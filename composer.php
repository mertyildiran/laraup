<?php

$publishings = [
  'cartalyst/sentry'                => "php artisan vendor:publish --provider=\"Cartalyst\Sentry\SentryServiceProvider\"",
  'barryvdh/laravel-ide-helper'     => "php artisan vendor:publish --provider=\"Barryvdh\LaravelIdeHelper\IdeHelperServiceProvider\" --tag=config",
  'maatwebsite/excel'               => "php artisan vendor:publish --provider=\"Maatwebsite\Excel\ExcelServiceProvider\""
];

$package_replacements = [
  'cartalyst/sentry'                => 'mertyildiran/sentry:dev-master',
  '*/l4shell'                       => 'mertyildiran/l5shell:dev-master',
  '*/kmd-logviewer|*/logviewer'     => 'rap2hpoutre/laravel-log-viewer'
];

$old_project_path = $argv[1];
$new_project_path = $argv[2];

$old_composer_json_file_path = $old_project_path.'/composer.json';
$old_composer_json_content = file_get_contents($old_composer_json_file_path);

$new_composer_json_file_path = $new_project_path.'/composer.json';
$new_composer_json_content = file_get_contents($new_composer_json_file_path);

$old_composer_array = json_decode($old_composer_json_content, true);
$new_composer_array = json_decode($new_composer_json_content, true);

$key = 'repositories';
if (array_key_exists($key, $old_composer_array)) {
  $new_composer_array[$key] = $old_composer_array[$key];
}
file_put_contents($new_composer_json_file_path, json_encode($new_composer_array, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES));

$require = $old_composer_array['require'];
$require_dev = $old_composer_array['require-dev'];

$commands_to_execute = [
  "cd ".$new_project_path." && composer require",
  "cd ".$new_project_path." && composer require --dev"
];

foreach ($require as $package => $version) {
  evaluatePackage($package, 0);
}

foreach ($require_dev as $package => $version) {
  evaluatePackage($package, 1);
}

function evaluatePackage($package, $dev)
{
  global $package_replacements;
  global $commands_to_execute;

  if (in_array($package, ['php', 'laravel/framework'])) {
    return;
  }

  $match = getFirstWildcardMatch($package, $package_replacements);
  if (! is_null($match)) {
    executeInstall($package, $commands_to_execute[$dev]." ".$match);
  } else {
    executeInstall($package, $commands_to_execute[$dev]." ".$package);
  }
}

function executeInstall($package, $command)
{
  global $publishings;

  shell_exec($command);
  $match = getFirstWildcardMatch($package, $publishings);
  if (! is_null($match)) {
    shell_exec($match);
  }
}

function getFirstWildcardMatch($package, $array)
{
  foreach (array_keys($array) as $pattern) {
    foreach (explode('|', $pattern) as $wildcard) {
      if (fnmatch($wildcard, $package)) {
        return $array[$pattern];
      }
    }
  }
  return NULL;
}

?>
