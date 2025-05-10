<html>
<head><title>Welcome to my excellent blog</title></head>
<body>
<img src='https://storage.googleapis.com/YOUR_BUCKET_NAME/my-excellent-blog.png'>
<h1>Welcome to my excellent blog</h1>
<?php
 $dbserver = "CLOUDSQLIP";
 $dbuser = "blogdbuser";
 $dbpassword = "DBPASSWORD";
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
