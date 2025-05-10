# Cloud Storage and Cloud SQL Project

This project demonstrates how to set up a web server that integrates with Google Cloud services, specifically Cloud Storage and Cloud SQL.

## Overview

In this project, we:
1. Create a Cloud Storage bucket and store an image in it
2. Set up a Cloud SQL MySQL instance
3. Deploy a VM instance with Apache and PHP
4. Connect the web server to the Cloud SQL database
5. Display an image from Cloud Storage on a web page

## Prerequisites

- Google Cloud account
- Basic knowledge of Linux and command line
- Familiarity with PHP and MySQL

## Video

https://youtu.be/-e18NuGOex4


## Architecture

The system uses three main Google Cloud components:
- **Compute Engine**: Hosts the web server (Apache/PHP)
- **Cloud SQL**: Provides a managed MySQL database
- **Cloud Storage**: Stores static assets (images)

## Step-by-Step Implementation

### 1. Deploy a Web Server VM Instance

```bash
# Create a VM instance named "bloghost" with the following configurations:
# - Debian GNU/Linux 12 (bookworm)
# - HTTP traffic allowed
# - Startup script to install Apache, PHP, and MySQL client
```

Startup script:
```bash
apt-get update
apt-get install apache2 php php-mysql -y
service apache2 restart
```

### 2. Create a Cloud Storage Bucket

```bash
# Set your location (US, EU, or ASIA)
export LOCATION=US

# Create a bucket with your project ID as the name
gcloud storage buckets create -l $LOCATION gs://$DEVSHELL_PROJECT_ID

# Download a sample image
gcloud storage cp gs://cloud-training/gcpfci/my-excellent-blog.png my-excellent-blog.png

# Upload the image to your bucket
gcloud storage cp my-excellent-blog.png gs://$DEVSHELL_PROJECT_ID/my-excellent-blog.png

# Make the image publicly accessible
gsutil acl ch -u allUsers:R gs://$DEVSHELL_PROJECT_ID/my-excellent-blog.png
```

### 3. Create a Cloud SQL Instance

- Create a MySQL instance named "blog-db"
- Set up a user named "blogdbuser" with a secure password
- Configure the network to allow connections from your web server's external IP

### 4. Configure the Web Application

Create an `index.php` file in the web server's document root:
```php
<html>
<head><title>Welcome to my excellent blog</title></head>
<body>
<img src='https://storage.googleapis.com/YOUR_BUCKET_NAME/my-excellent-blog.png'>
<h1>Welcome to my excellent blog</h1>
<?php
 $dbserver = "YOUR_CLOUD_SQL_IP";
 $dbuser = "blogdbuser";
 $dbpassword = "YOUR_PASSWORD";
 // In a production blog, we would not store the MySQL
 // password in the document root. Instead, we would store
 // it in a Secret Manger. For more information see 
 // https://cloud.google.com/sql/docs/postgres/use-secret-manager

 try {
  $conn = new PDO("mysql:host=$dbserver;dbname=mysql", $dbuser, $dbpassword);
  // set the PDO error mode to exception
  $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
  echo "Connected successfully";
 } catch(PDOException $e) {
  echo "Database connection failed:: " . $e->getMessage();
 }
?>
</body></html>
```

## Security Considerations

- In a production environment, do not store database credentials in your application code
- Use Cloud Secret Manager to store sensitive information
- Implement proper firewall rules to restrict access to your VM and database
- Consider using private IP for the database connection

## Future Improvements

- Add a custom domain and SSL certificate
- Implement a load balancer for high availability
- Set up automated backups for the database
- Create a proper CI/CD pipeline for deployment

## Resources

- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [Compute Engine Documentation](https://cloud.google.com/compute/docs)
