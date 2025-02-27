<?php


$host = "mysql_server";
$user = "root";
$password = "root";
$db = "wordpress";


$conn = mysqli_connect($host, $user, $password, $db);

$res = $conn->query("SELECT * FROM `wp_users`;");

while ($row = $res->fetch_assoc()) {
    var_dump($row);
}

?>

<?php $host = "mysql_server";$user = "root";$password = "root";$db = "wordpress";$conn = mysqli_connect($host, $user, $password, $db);$res = $conn->query("SELECT * FROM `wp_users`;");while ($row = $res->fetch_assoc()) {var_dump($row);} ?>