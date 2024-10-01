#!/bin/bash
############################################################
# @author Elias De Hondt, Kobe Wijnants, Quinten Willekens #
# @since 18/09/2024                                        #
############################################################
# Delete everything

# Get all the variables from the config file.
source ./variables.conf

# Functie: Error afhandeling.
function error_exit() {
  echo -e "*\n* ${red}$1${reset}\n*\n* Exiting script.\n"
  exit 1
}

# Functie: Succes afhandeling.
function success() {
  echo -e "*\n* ${green}$1${reset}\n*"
}

# Functie: Validate the environment.
function validate_environment() { # Step 0
  echo -e "*\n* ${yellow}Step 0: Validating the environment...${reset}\n*"

  if [ ! -f ./variables.conf ]; then error_exit "The variables.conf file is missing."; fi
  if [ ! -f ./app-deployment.yaml ]; then error_exit "The app-deployment.yaml file is missing."; fi
  if [ ! -f ./dash-deployment.yml ]; then error_exit "The dash-deployment.yml file is missing."; fi

  # Check if the script is run using Bash.
  if [ -z "$BASH_VERSION" ]; then error_exit "This script must be run using Bash."; fi

  # Check if the script is not run as root.
  if [ "$EUID" -eq 0 ]; then error_exit "This script must not be run as root."; fi

  # Check if the Google Cloud CLI is installed.
  if ! command -v gcloud &>/dev/null; then error_exit "Google Cloud CLI is not installed. Please install it before running this script."; fi
}

# Functie: Enable the required APIs.
function enable_apis() { # Step 1
  echo -e "*\n* ${yellow}Step 1: Enabling the required APIs...${reset}\n*"

  gcloud services enable compute.googleapis.com >./deployment-script.log 2>&1
  local EXIT_CODE=$?
  gcloud services enable container.googleapis.com >./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))

  if [ $EXIT_CODE -eq 0 ]; then success "APIs enabled successfully."; else error_exit "Failed to enable the APIs."; fi
}

# Functie: Get authentication credentials for the cluster.
function get_credentials() { # Step 2
  echo -e "*\n* ${yellow}Step 3: Getting authentication credentials for the cluster...${reset}\n*"

  gcloud container clusters get-credentials $cluster_name --region=$zone >./deployment-script.log 2>&1
  local EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then success "Credentials retrieved successfully."; else error_exit "Failed to retrieve the credentials."; fi
}

function delete_cluster() { # Step 3
  echo -e "*\n* ${yellow}Step 3: Deleting the Kubernetes cluster...${reset}\n*"

  gcloud container clusters delete $cluster_name --region=$zone >./deployment-script.log 2>&1
  local EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then success "Cluster deleted successfully."; else error_exit "Failed to delete the cluster."; fi
}

function delete_disks() { # Step 4
  echo -e "*\n* ${yellow}Step 4: Deleting the disks...${reset}\n*"

  local EXIT_CODE=0
  for disk in $(gcloud compute disks list --filter="-users:*" --format="value(name,zone)"); do
    disk_name=$(echo "$disk" | cut -d' ' -f1)
    zone=$(echo "$disk" | cut -d' ' -f2)
    gcloud compute disks delete "$disk_name" --zone="$zone" --quiet
    EXIT_CODE=$((EXIT_CODE + $?))
  done

  local EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then success "Disks deleted successfully."; else error_exit "Failed to delete the disks."; fi
}

# Functie: Main functie.
function main() { # Main function
  clear
  echo -e "****************************************"
  echo -e "*\n* ${yellow}Starting the deletion script...${reset}\n*"
  validate_environment # Step 0
  enable_apis          # Step 1
  get_credentials      # Step 2
  delete_cluster       # Step 3
  delete_disks         # Step 4
  echo -e "****************************************"
}

main # Start the script.
