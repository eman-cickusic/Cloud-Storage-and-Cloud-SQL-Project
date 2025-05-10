#!/bin/bash
# Deploy script for the web application

# Exit on error
set -e

# Check for required parameters
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <YOUR_CLOUD_SQL_IP> <YOUR_DB_PASSWORD> <YOUR_BUCKET_NAME>"
    exit 1
fi

# Get parameters
CLOUD_SQL_IP=$1
DB_PASSWORD=$2
BUCKET_NAME=$3

# Create temporary index.php with correct values
cat > index.php.tmp << EOL
<html>
<head><title>Welcome to my excellent blog</title></head>
<body>
<img src='https://storage.googleapis.com/${BUCKET_NAME}/my-excellent-blog.png'>
<h1>Welcome to my excellent blog</h1>
<?php
 \$dbserver = "${CLOUD_SQL_IP}";
 \$dbuser = "blogdbuser";
 \$dbpassword = "${DB_PASSWORD}";
 // In a production blog, we would not store the MySQL
 // password in the document root. Instead, we would store
 // it in a Secret Manger. For more information see 
 // https://cloud.google.com/sql/docs/postgres/use-secret-manager

 try {
  \$conn = new PDO("mysql:host=\$dbserver;dbname=mysql", \$dbuser, \$dbpassword);
  // set the PDO error mode to exception
  \$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
  echo "Connected successfully";
 } catch(PDOException \$e) {
  echo "Database connection failed:: " . \$e->getMessage();
 }
?>
</body></html>
EOL

# Get the VM instance's external IP
VM_IP=$(gcloud compute instances describe bloghost \
    --zone=$(gcloud config get-value compute/zone) \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Copy the file to the VM
echo "Copying configured index.php to VM..."
gcloud compute scp index.php.tmp bloghost:/tmp/index.php --zone=$(gcloud config get-value compute/zone)

# Move the file to the correct location with proper permissions on the VM
echo "Installing index.php on VM..."
gcloud compute ssh bloghost --zone=$(gcloud config get-value compute/zone) \
    --command="sudo mv /tmp/index.php /var/www/html/index.php && sudo chmod 644 /var/www/html/index.php && sudo service apache2 restart"

# Clean up
rm index.php.tmp

echo ""
echo "========================================================"
echo "Deployment Complete!"
echo ""
echo "You can access your blog at: http://${VM_IP}/"
echo "========================================================"
