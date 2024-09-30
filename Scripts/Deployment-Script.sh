#!/bin/bash
############################################################
# @author Elias De Hondt, Kobe Wijnants, Quinten Willekens #
# @since 18/09/2024                                        #
############################################################
# This script will create a kubernetes cluster and deploy a:
# Application: Jellyfin
# Database: MySQL
# Storage: Persistent Volume Claims

# Get all the variables from the config file.
source ./variables.conf

# Functie: Error afhandeling.
function error_exit() {
    echo -e "\n*\n* ${red}$1${reset}\n*\n* Exiting script.\n${line}"
    exit 1
}

# Functie: Succes afhandeling.
function success() {
    echo -e "\n*\n* ${green}$1${reset}\n*"
}

# Functie: Validate the environment.
function validate_environment() { # Step 0
    if [ ! -f ./variables.conf ]; then error_exit "The variables.conf file is missing."; fi
    if [ ! -f ./app-deployment.yaml ]; then error_exit "The app-deployment.yaml file is missing."; fi
    if [ ! -f ./dash-deployment.yml ]; then error_exit "The dash-deployment.yml file is missing."; fi
    if [ ! -f ./dash-service-account-admin.yml ]; then error_exit "The dash-service-account-admin.yml file is missing."; fi
    if [ ! -f ./dash-clusterRoleBinding-admin.yml ]; then error_exit "The dash-clusterRoleBinding-admin.yml file is missing."; fi
    if [ -z "$(ls -A "../Media/")" ]; then error_exit "The Media directory is empty."; fi

    # Check if the script is run using Bash.
    if [ -z "$BASH_VERSION" ]; then error_exit "This script must be run using Bash."; fi

    # Check if the script is not run as root.
    if [ "$EUID" -eq 0 ]; then error_exit "This script must not be run as root."; fi

    # Check if the Google Cloud CLI is installed.
    if ! command -v gcloud &> /dev/null; then error_exit "Google Cloud CLI is not installed. Please install it before running this script."; fi
}


# Functie: Enable the required APIs.
function enable_apis() { # Step 1
    gcloud services enable compute.googleapis.com > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    gcloud services enable container.googleapis.com > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))

    if [ $EXIT_CODE -eq 0 ]; then success "APIs enabled successfully."; else error_exit "Failed to enable the APIs."; fi
}

# Functie: Create the kubernetes cluster.
function create_cluster() { # Step 2
    # Check if the cluster already exists

    # Start cluster creation in the background
    gcloud container clusters create "$cluster_name" \
        --region="$zone" \
        --min-nodes="$min_nodes" \
        --max-nodes="$max_nodes" \
        --enable-ip-alias \
    --machine-type="$machine_type" \
        --disk-size="$disk_size" \
        --enable-autoscaling >./deployment-script.log 2>&1 &

    if [ $EXIT_CODE -eq 0 ]; then success "Cluster created successfully."
    else error_exit "Failed to create the cluster."; fi
}

# Functie: Get authentication credentials for the cluster.
function get_credentials() { # Step 3
    gcloud container clusters get-credentials $cluster_name --region=$zone >./deployment-script.log 2>&1 &

    if [ $EXIT_CODE -eq 0 ]; then success "Credentials retrieved successfully."; else error_exit "Failed to retrieve the credentials."; fi
}

# Functie: Deploy the application (Jellyfin).
function deploy_jellyfin() { # Step 4
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
    local EXIT_CODE=$?
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
    EXIT_CODE=$((EXIT_CODE + $?))
    kubectl apply -f ./app-deployment.yaml
    EXIT_CODE=$((EXIT_CODE + $?))

    if [ $EXIT_CODE -eq 0 ]; then success "Application (Jellyfin) deployed successfully."; else error_exit "Failed to deploy the application (Jellyfin)."; fi
}

# Functie: Deploy the application (Dashboard).
function deploy_dashboard() { # Step 5
    kubectl apply -f ./dash-deployment.yml
    local EXIT_CODE=$?
    kubectl apply -f ./dash-service-account-admin.yml
    EXIT_CODE=$((EXIT_CODE + $?))
    kubectl apply -f ./dash-clusterRoleBinding-admin.yml
    EXIT_CODE=$((EXIT_CODE + $?))

    if [ $EXIT_CODE -eq 0 ]; then success "Application (Dashboard) deployed successfully."; else error_exit "Failed to deploy the application (Dashboard)."; fi
}

# Start of the script.
function main() {
    validate_environment                # Step 0
    enable_apis                         # Step 1
    create_cluster                      # Step 2
    get_credentials                     # Step 3
    deploy_jellyfin                     # Step 4
    deploy_dashboard                    # Step 5
}

main # Start the script.