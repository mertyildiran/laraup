<?php

$old_project_path = $argv[1];
$desired_laravel_version = $argv[2];
$composer_json_file_path = $old_project_path.'/composer.json';
$composer_json_content = file_get_contents($composer_json_file_path);

$composer_array = json_decode($composer_json_content, true);
$laravel_framework = $composer_array['require']['laravel/framework'];
$laravel_version = preg_replace("/[^1-9\.]/", "", $laravel_framework);

if (substr($laravel_version, 0, strlen($desired_laravel_version)) === $desired_laravel_version) {
  exit(0);
} else {
  exit(1);
}

?>
