############################################################
# @author Elias De Hondt, Kobe Wijnants, Quinten Willekens #
# @since 18/09/2024                                        #
############################################################
# Remove everything

# Functie: Validate the external resources.
function validate_external_resources() { # Step 0
  if [ ! -f ./handy.sh ]; then error_exit "The handy.sh file is missing."; fi
  if [ ! -f ./config.sh ]; then error_exit "The config.sh file is missing."; fi
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

# Functie: Get authentication credentials for the cluster.
function get_credentials() { # Step 4
  gcloud container clusters get-credentials $cluster_name --region=$zone >./deployment-script.log 2>&1
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then success "Credentials retrieved successfully."; else error_exit "Failed to retrieve the credentials."; fi
}

function delete_deployment() {
  kubectl delete namespaces --all --all-namespaces=true
  kubectl delete all -all

  kubectl delete clusterroles --all
  kubectl delete clusterrolebindings --all
  kubectl delete customresourcedefinitions --all

  kubectl delete pvc --all
  kubectl delete pv --all

  kubectl delete configmaps --all
  kubectl delete secrets --all
}

function delete_cluster() {
  # Start gcloud delete command in the background and get its PID
  gcloud container clusters delete "$cluster_name" --region="$zone" --quiet >./deployment-script.log 2>&1 &

  # ANIMATION
  local GCLOUD_PID=$!
  loading_icon "Deleting cluster..." $GCLOUD_PID
  wait $GCLOUD_PID
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    success "Cluster deleted successfully."
  else
    error_exit "Failed to delete the cluster."
  fi
}

function remove_disks() {
  ./Remove-disks.sh

  if [ $EXIT_CODE -eq 0 ]; then
    success "Cluster deleted successfully."
  else
    error_exit "Failed to delete the cluster."
  fi
}

# Start of the script.
function main() {
  validate_external_resources
  check_gcloud_installation
  get_credentials
  echo "What would you like to delete? (cluster/deployment)"
  read -r delete
  if [ "$delete" == "cluster" ]; then
    delete_cluster
  elif [ "$delete" == "deployment" ]; then
    delete_deployment
  else
    error_exit "Invalid input."
  fi
  remove_disks
}

main "$@" # Start the script.
