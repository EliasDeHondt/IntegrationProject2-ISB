############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 18/09/2024        #
############################
# This script will create a kubernetes cluster and deploy a:
# Application: Jellyfin
# Database: MySQL
# Storage: Persistent Volume Claims

# UI variables
reset="\e[0m"    # Reset
red="\e[0;31m"   # Red
green="\e[0;32m" # Green

source ./config.sh

# Functie: Error afhandeling.
function error_exit() {
  echo -e "\n*\n* ${red}$1${reset}\n*\n* Exiting script.\n"
  exit 1
}

# Functie: Succes afhandeling.
function success() {
  echo -e "\n*\n* ${green}$1${reset}\n*"
}

# Spinner function
function spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Functie: Validate the external resources.
function validate_external_resources() { # Step 0
  if [ ! -f ./application.yaml ]; then error_exit "The application.yaml file is missing."; fi
  if [ -z "$(ls -A "../Media/")" ]; then error_exit "The Media directory is empty."; fi
}

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
  gcloud services enable container.googleapis.com >./deployment-script.log 2>&1
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then success "APIs enabled successfully."; else error_exit "Failed to enable the APIs."; fi
}

# Functie: Create the kubernetes cluster.
function create_cluster() {
  # Check if the cluster already exists
  if gcloud container clusters describe "$cluster_name" --region="$zone" >/dev/null 2>&1; then
    echo "Cluster '$cluster_name' already exists, skipping creation."
    return 0
  fi

  # Start cluster creation in the background
  echo "Creating the cluster..."
  gcloud container clusters create "$cluster_name" \
    --region="$zone" \
    --min-nodes="$min_nodes" \
    --max-nodes="$max_nodes" \
    --enable-ip-alias \
    --machine-type=n1-standard-4 \
    --disk-size=20GB \
    --enable-autoscaling >./deployment-script.log 2>&1 &

  # Get the process ID of the cluster creation
  local CLUSTER_CREATION_PID=$!

  # Run the spinner while the cluster is being created
  spinner $CLUSTER_CREATION_PID

  # Wait for the process to complete
  wait $CLUSTER_CREATION_PID
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    success "Cluster created successfully."
  else
    error_exit "Failed to create the cluster."
  fi
}

# Functie: Get authentication credentials for the cluster.
function get_credentials() { # Step 4
  gcloud container clusters get-credentials $cluster_name --region=$zone >./deployment-script.log 2>&1
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then success "Credentials retrieved successfully."; else error_exit "Failed to retrieve the credentials."; fi
}

# Functie: Deploy the application.
function deploy_application() { # Step 5
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.9.1/cert-manager.yaml >./deployment-script.log 2>&1
  kubectl apply -f ./application.yaml >./deployment-script.log 2>&1
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then success "Application deployed successfully."; else error_exit "Failed to deploy the application."; fi
}

# Functie: Copy test data to volume.
function copy_test_data() { # Step 6
  # Wait until the pod is running
  echo "Waiting for Jellyfin pod to be ready..."

  while true; do
    POD_NAME=$(kubectl get pods -l app=jellyfin -o jsonpath="{.items[0].metadata.name}" --field-selector=status.phase=Running 2>/dev/null)

    if [ -n "$POD_NAME" ]; then
      echo "Jellyfin pod is running: $POD_NAME"
      break
    else
      echo "Pod not ready, retrying in 5 seconds..."
      sleep 5
    fi
  done

  # Copy the media files to the Jellyfin pod
  kubectl cp ../Media/ default/$POD_NAME:/media/
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    success "Test data copied successfully."
  else
    error_exit "Failed to copy the test data."
  fi
}

# Functie: Set up SSL certificates for domain (For the load balancer external IP).
function setup_ssl_certificates() { # Step 7
  # Get the IP address of the load balancer
  LOAD_BALANCER_IP=$(gcloud compute forwarding-rules list --format="value(IPAddress)" --limit=1)
  success "Load balancer IP: $LOAD_BALANCER_IP"
  ./ddns.sh "$LOAD_BALANCER_IP"
}

# Start of the script.
function main() {
  validate_external_resources # Step 0
  check_gcloud_installation   # Step 1
  enable_apis                 # Step 2
  create_cluster              # Step 3
  get_credentials             # Step 4
  deploy_application          # Step 5
  copy_test_data              # Step 6
  setup_ssl_certificates      # Step 7
}

main # Start the script.
