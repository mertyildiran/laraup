<?php

$new_project_path = $argv[1];
$composer_json_file_path = $new_project_path.'/composer.json';
$composer_json_content = file_get_contents($composer_json_file_path);

$composer_array = json_decode($composer_json_content, true);
$composer_array['autoload']['files'] = ['app/helpers.php'];

file_put_contents($composer_json_file_path, json_encode($composer_array, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES));
?>
