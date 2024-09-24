# UI variables
reset="\e[0m"    # Reset
red="\e[0;31m"   # Red
green="\e[0;32m" # Green

source ./config.sh

# Functie: Error afhandeling.
function error_exit() {
  echo -e "\n*\n* ${red}$1${reset}\n*\n"
}

# Functie: Succes afhandeling.
function success() {
  echo -e "\n*\n* ${green}$1${reset}\n*"
}

# Functie: Validate the external resources.
function validate_external_resources() { # Step 0
  if [ ! -f ./application.yaml ]; then error_exit "The application.yaml file is missing."; fi
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

# Functie: Get authentication credentials for the cluster.
function get_credentials() { # Step 4
  gcloud container clusters get-credentials $cluster_name --region=$zone >./deployment-script.log 2>&1
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then success "Credentials retrieved successfully."; else error_exit "Failed to retrieve the credentials."; fi
}

function delete_deployment() {
  kubectl delete -f ./application.yaml
  kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.9.1/cert-manager.yaml

  if [ $? -eq 0 ]; then success "Deployment deleted successfully."; else error_exit "Failed to delete the deployment."; fi
}

function delete_cluster() {
  gcloud container clusters delete $cluster_name --region=$zone --quiet >./deployment-script.log 2>&1
  if [ $? -eq 0 ]; then success "Cluster deleted successfully."; else error_exit "Failed to delete the cluster."; fi
}

# Start of the script.
function main() {
  validate_external_resources # Step 0
  check_gcloud_installation   # Step 1
  get_credentials             # Step 2
  delete_deployment
  delete_cluster
}

main # Start the script.
