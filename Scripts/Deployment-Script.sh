############################################################
# @author Elias De Hondt, Kobe Wijnants, Quinten Willekens #
# @see https://eliasdh.com                                 #
# @since 18/09/2024                                        #
############################################################
# This script will create a kubernetes cluster and deploy a:
# Application: Jellyfin
# Database: MySQL
# Storage: Persistent Volume Claims

# Functie: Validate the external resources.
function validate_external_resources() { # Step 0
  if [ ! -f ./app-deployment.yaml ]; then error_exit "The app-deployment.yaml file is missing."; fi
  if [ ! -f ./dash-deployment.yaml ]; then error_exit "The dash-deployment.yaml file is missing."; fi
  if [ ! -f ./ddns.sh ]; then error_exit "The ddns.sh file is missing."; fi
  if [ ! -f ./handy.sh ]; then error_exit "The handy.sh file is missing."; fi
  if [ ! -f ./config.sh ]; then error_exit "The config.sh file is missing."; fi
  if [ -z "$(ls -A "../Media/")" ]; then error_exit "The Media directory is empty."; fi
}

source ./config.sh
source ./handy.sh

function check_gcloud_installation() { # Step 1
  # Check for gcloud installation
  if ! command -v gcloud &>/dev/null; then
    error_exit "ERROR: gcloud is not installed. Please install it from https://cloud.google.com/sdk/docs/install"
  fi

  # Check for active gcloud login
  gcloud config get-value account &>/dev/null
  if [[ $? -ne 0 ]]; then
    error_exit "ERROR: You are not logged in to gcloud. Please run 'gcloud auth login' to authenticate."
  fi
}

# Functie: Enable the required APIs.
function enable_apis() { # Step 2
  gcloud services enable container.googleapis.com gkehub.googleapis.com containeranalysis.googleapis.com >./deployment-script.log 2>&1 &

  # ANIMATION
  local GCLOUD_PID=$!
  loading_icon "Enabling APIs..." $GCLOUD_PID
  wait $GCLOUD_PID
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then success "APIs enabled successfully."; else error_exit "Failed to enable the APIs."; fi
}

# Functie: Create the kubernetes cluster.
function create_cluster() {
  # Check if the cluster already exists
  if gcloud container clusters describe "$cluster_name" --region="$zone" >/dev/null 2>&1; then
    printf "\nCluster '$cluster_name' already exists, skipping creation.\n"
    return 0
  fi

  # Start cluster creation in the background
  gcloud container clusters create "$cluster_name" \
    --region="$zone" \
    --min-nodes="$min_nodes" \
    --max-nodes="$max_nodes" \
    --enable-ip-alias \
    --machine-type=n1-standard-4 \
    --disk-size=20GB \
    --enable-autoscaling >./deployment-script.log 2>&1 &

  # ANIMATION
  local GCLOUD_PID=$!
  loading_icon "Creating cluster..." $GCLOUD_PID
  wait $GCLOUD_PID
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    success "Cluster created successfully."
  else
    error_exit "Failed to create the cluster."
  fi
}

# Functie: Get authentication credentials for the cluster.
function get_credentials() { # Step 4
  gcloud container clusters get-credentials $cluster_name --region=$zone >./deployment-script.log 2>&1 &

  # ANIMATION
  local GCLOUD_PID=$!
  loading_icon "Capturing kubernetes credentials..." $GCLOUD_PID
  wait $GCLOUD_PID
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then success "Credentials retrieved successfully."; else error_exit "Failed to retrieve the credentials."; fi
}

# Function: Deploy the application.
function deploy_application() {
  # Step 1: Create namespaces if they don't exist.
  kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
  kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

  # Step 2: Deploy cert-manager.
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
  if [ $? -eq 0 ]; then
    success "cert-manager.yaml deployed successfully."
  else
    error_exit "Failed to deploy cert-manager.yaml"
  fi

  # Wait for cert-manager to be ready.
  kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/instance=cert-manager --timeout=120s

  # Step 3: Deploy NGINX Ingress Controller.
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
  if [ $? -eq 0 ]; then
    success "ingress-nginx deployed successfully."
  else
    error_exit "Failed to deploy ingress-nginx"
  fi

  # Wait for NGINX Ingress Controller to be ready.
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

  # Step 4: Deploy the app.
  kubectl apply -f ./app-deployment.yaml
  if [ $? -eq 0 ]; then
    success "app-deployment.yaml deployed successfully."
  else
    error_exit "Failed to deploy app-deployment.yaml"
  fi

  # Step 5: Deploy the Kubernetes Dashboard.
  kubectl apply -f ./dash-deployment.yaml
  if [ $? -eq 0 ]; then
    success "dash-deployment.yaml deployed successfully."
  else
    error_exit "Failed to deploy dash-deployment.yaml"
  fi
}

# Functie: Copy test data to volume.
function copy_test_data() { # Step 7
  # Wait until the Jellyfin pod is running
  echo "Waiting for Jellyfin pod to be ready..."

  # Wait for the Jellyfin deployment to be available
  if ! kubectl wait --for=condition=available --timeout=60s deployment/jellyfin -n jellyfin; then
    error_exit "Jellyfin deployment did not become available in time."
  fi

  # Retrieve the pod name
  POD_NAME=$(kubectl get pods -l app=jellyfin -o jsonpath="{.items[0].metadata.name}" --field-selector=status.phase=Running -n jellyfin)

  # Check if the POD_NAME is empty
  if [ -n "$POD_NAME" ]; then
    echo "Jellyfin pod is running: $POD_NAME"

    # Copy the media files to the Jellyfin pod
    kubectl cp ../Media/ jellyfin/$POD_NAME:/media/ &

    # ANIMATION
    local GCLOUD_PID=$!
    loading_icon "Copying media to the media volume..." $GCLOUD_PID
    wait $GCLOUD_PID
    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
      success "Test data copied successfully."
    else
      error_exit "Failed to copy the test data."
    fi
  else
    error_exit "No running Jellyfin pod found."
  fi
}

# Functie: Set up SSL certificates for domain (For the load balancer external IP).
# Get the IP address of the load balancer
function setup_ssl_dns_certificates() { # Step 8
  # app.nepfliks.kobelabs.online
  LOAD_BALANCER_IP=$(
    kubectl get service jellyfin -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | awk '{print $1}'
  )
  success "Load balancer IP: $LOAD_BALANCER_IP"
  ./ddns.sh "$LOAD_BALANCER_IP" "app.nepfliks.kobelabs.online"

  # dashboard.nepfliks.kobelabs.online
  LOAD_BALANCER_IP=$(
    kubectl get service kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | awk '{print $1}'
  )
  success "Load balancer IP: $LOAD_BALANCER_IP"
  ./ddns.sh "$LOAD_BALANCER_IP" "dashboard.nepfliks.kobelabs.online"
}

# Start of the script.
function main() {
  validate_external_resources # Step 0
  check_gcloud_installation   # Step 1
  enable_apis                 # Step 2
  create_cluster              # Step 3
  get_credentials             # Step 4
  deploy_application          # Step 5
  copy_test_data              # Step 7
  setup_ssl_dns_certificates  # Step 8
}

main # Start the script.
