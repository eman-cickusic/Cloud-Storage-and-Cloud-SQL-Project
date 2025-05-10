#!/bin/bash
# Setup script for Cloud Storage and Cloud SQL Project

# Exit on error
set -e

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud is not installed. Please install the Google Cloud SDK."
    exit 1
fi

# Ask for project ID
read -p "Enter your Google Cloud Project ID: " PROJECT_ID

# Configure gcloud with project
gcloud config set project $PROJECT_ID

# Ask for preferred location
echo "Choose a location for your Cloud Storage bucket:"
echo "1. US"
echo "2. EU"
echo "3. ASIA"
read -p "Enter your choice (1-3): " LOCATION_CHOICE

case $LOCATION_CHOICE in
    1) LOCATION="US" ;;
    2) LOCATION="EU" ;;
    3) LOCATION="ASIA" ;;
    *) echo "Invalid choice. Defaulting to US."; LOCATION="US" ;;
esac

echo "Using location: $LOCATION"

# Create VM Instance
echo "Creating VM instance bloghost..."
gcloud compute instances create bloghost \
    --machine-type=e2-medium \
    --zone=$(gcloud config get-value compute/zone) \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --tags=http-server \
    --metadata=startup-script='apt-get update
apt-get install apache2 php php-mysql -y
service apache2 restart'

# Create firewall rule for HTTP
echo "Creating firewall rule for HTTP traffic..."
gcloud compute firewall-rules create allow-http \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server

# Create Cloud Storage bucket
echo "Creating Cloud Storage bucket..."
gcloud storage buckets create gs://$PROJECT_ID --location=$LOCATION

# Download and upload the blog image
echo "Downloading and uploading banner image..."
gcloud storage cp gs://cloud-training/gcpfci/my-excellent-blog.png my-excellent-blog.png
gcloud storage cp my-excellent-blog.png gs://$PROJECT_ID/my-excellent-blog.png
gsutil acl ch -u allUsers:R gs://$PROJECT_ID/my-excellent-blog.png

# Get the external IP of the VM
VM_IP=$(gcloud compute instances describe bloghost \
    --zone=$(gcloud config get-value compute/zone) \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "VM External IP: $VM_IP"

# Create Cloud SQL instance
echo "Creating Cloud SQL instance (this may take several minutes)..."
gcloud sql instances create blog-db \
    --database-version=MYSQL_8_0 \
    --tier=db-f1-micro \
    --region=$(gcloud config get-value compute/region)

# Create database user
echo "Creating database user..."
DB_PASSWORD=$(openssl rand -base64 12)
gcloud sql users create blogdbuser \
    --instance=blog-db \
    --password="$DB_PASSWORD"

# Get Cloud SQL IP
SQL_IP=$(gcloud sql instances describe blog-db --format='get(ipAddresses[0].ipAddress)')
echo "Cloud SQL IP: $SQL_IP"

# Add VM IP to authorized networks
echo "Authorizing VM to connect to Cloud SQL..."
gcloud sql instances patch blog-db \
    --authorized-networks="$VM_IP/32"

echo ""
echo "========================================================"
echo "Setup Complete! Please update your index.php file with:"
echo ""
echo "Cloud SQL IP: $SQL_IP"
echo "Database User: blogdbuser"
echo "Database Password: $DB_PASSWORD"
echo "Bucket Name: $PROJECT_ID"
echo ""
echo "To deploy index.php to your VM, run:"
echo "gcloud compute scp index.php bloghost:/var/www/html/ --zone=$(gcloud config get-value compute/zone)"
echo "========================================================"
