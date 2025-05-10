#!/bin/bash
# Cleanup script for Cloud Storage and Cloud SQL Project

# Exit on error
set -e

# Confirm before proceeding
echo "WARNING: This script will delete all resources created for this project."
echo "This includes the VM instance, Cloud SQL instance, and Cloud Storage bucket."
read -p "Are you sure you want to continue? (y/n): " CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Cleanup aborted."
    exit 0
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)

# Delete VM instance
echo "Deleting VM instance bloghost..."
gcloud compute instances delete bloghost \
    --zone=$(gcloud config get-value compute/zone) \
    --quiet || echo "VM instance not found or already deleted."

# Delete firewall rule
echo "Deleting firewall rule..."
gcloud compute firewall-rules delete allow-http --quiet || echo "Firewall rule not found or already deleted."

# Delete Cloud SQL instance
echo "Deleting Cloud SQL instance blog-db..."
gcloud sql instances delete blog-db --quiet || echo "Cloud SQL instance not found or already deleted."

# Delete Cloud Storage bucket contents
echo "Deleting contents of Cloud Storage bucket..."
gsutil -m rm -r gs://$PROJECT_ID/* || echo "Bucket empty or not found."

# Delete Cloud Storage bucket
echo "Deleting Cloud Storage bucket..."
gcloud storage buckets delete gs://$PROJECT_ID --quiet || echo "Bucket not found or already deleted."

echo ""
echo "========================================================"
echo "Cleanup Complete! All resources have been deleted."
echo "========================================================"
