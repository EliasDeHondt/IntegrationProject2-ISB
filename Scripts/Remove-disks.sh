#!/bin/bash
############################################################
# @author Elias De Hondt, Kobe Wijnants, Quinten Willekens #
# @since 18/09/2024                                        #
############################################################

# Set your Google Cloud project ID
PROJECT_ID="integrationproject2-elias"

# Set the zone you are using (modify as needed)
ZONE="us-central1-c" # Adjust this to your desired zone

# List all persistent disks in the project
DISKS=$(gcloud compute disks list --project "$PROJECT_ID" --format="value(name)")

# Check if there are any disks to delete
if [ -z "$DISKS" ]; then
  echo "No persistent disks found in project $PROJECT_ID."
  exit 0
fi

# Confirm deletion
echo "The following disks will be deleted:"
echo "$DISKS"
read -p "Are you sure you want to delete all these disks? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Deletion canceled."
  exit 1
fi

# Delete each disk
for DISK in $DISKS; do
  echo "Deleting disk: $DISK..."
  gcloud compute disks delete "$DISK" --zone "$ZONE" --quiet --project "$PROJECT_ID"
done

echo "All disks have been deleted."
