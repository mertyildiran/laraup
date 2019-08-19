<?php

$line_number_end_of_file = 231;
$line_number_end_of_aliases = 229;
$line_number_end_of_providers = 178;

$old_project_path = $argv[1];
$new_project_path = $argv[2];

$old_app_php_path = $old_project_path.'/app/config/app.php';
$new_app_php_path = $new_project_path.'/config/app.php';

$old_app_php = file_get_contents($old_app_php_path);
$old_app_php = preg_replace('/^.+\n/', '', $old_app_php);

function app() {}
include $old_project_path.'/vendor/laravel/framework/src/Illuminate/Support/helpers.php';
include $old_project_path.'/bootstrap/helpers.php';
include $old_project_path.'/app/helpers.php';
$config = eval($old_app_php);

$standard_keys = [
  'name',
  'debug',
  'url',
  'timezone',
  'locale',
  'fallback_locale',
  'key',
  'cipher',
  'providers',
  'manifest',
  'aliases'
];

$lines = file($new_app_php_path);

foreach ($config as $key => $value) {
  if (! in_array($key, $standard_keys)) {
    $write = "\t'".$key."' => ".var_export($value, true).",\n"; 
    array_splice($lines, $line_number_end_of_file - 1, 0, $write);
    $line_number_end_of_file++;
  }
}

foreach ($config['aliases'] as $key => $value) {
  if (substr($value, 0, strlen('Illuminate')) !== 'Illuminate') {
    array_splice($lines, $line_number_end_of_aliases - 1, 0, "\t\t'".$key."' => ".$value."::class,\n");
    $line_number_end_of_aliases++;
  }
}

// for "laravelcollective/html" package
array_splice($lines, $line_number_end_of_aliases - 1, 0, "\n\t\t'Form' => Collective\\Html\\FormFacade::class,\n");
$line_number_end_of_aliases++;
array_splice($lines, $line_number_end_of_aliases - 1, 0, "\t\t'Html' => Collective\\Html\\HtmlFacade::class,\n");
$line_number_end_of_aliases++;



foreach ($config['providers'] as $value) {
  if (substr($value, 0, strlen('Illuminate')) !== 'Illuminate') {
    array_splice($lines, $line_number_end_of_providers - 1, 0, "\t\t".$value."::class,\n");
    $line_number_end_of_providers++;
  }
}


file_put_contents($new_app_php_path, implode($lines));

?>
