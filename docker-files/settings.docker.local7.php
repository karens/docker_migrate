<?php

$databases['default']['default'] = array(
  'driver' => 'mysql',
  'database' => 'drupal',
  'username' => 'drupal',
  'password' => 'drupal',
  'host' => 'mariadb7',
  'prefix' => '',
);

$drupal_hash_salt = hash('sha256', serialize($databases)); //'ca596d170c1a9d4d73719dedf9b13ada09588cdbf07d3c70a430fde141968824';

$conf['file_directory_path'] = 'sites/default/files';
$conf['file_public_path'] = "sites/default/files";
$conf['file_private_path'] = '/var/www/html/files/private';
$conf['file_temporary_path'] = '/tmp';
$conf['preprocess_css'] = 0;
$conf['preprocess_js'] = 0;
$conf['drupal_http_request_fails'] = FALSE;

