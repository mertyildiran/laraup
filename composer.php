<?php

$publishings = [
  'cartalyst/sentry'                => "php artisan vendor:publish --provider=\"Cartalyst\Sentry\SentryServiceProvider\"",
  'barryvdh/laravel-ide-helper'     => "php artisan vendor:publish --provider=\"Barryvdh\LaravelIdeHelper\IdeHelperServiceProvider\" --tag=config",
  'maatwebsite/excel'               => "php artisan vendor:publish --provider=\"Maatwebsite\Excel\ExcelServiceProvider\""
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
  if (in_array($package, ['php', 'laravel/framework'])) {
    continue;
  } else if ($package === 'cartalyst/sentry') {
    executeInstall($package, $commands_to_execute[0]." cartalyst/sentry:dev-feature/laravel-5");
  } else {
    executeInstall($package, $commands_to_execute[0]." ".$package);
  }
}

foreach ($require_dev as $package => $version) {
  if (in_array($package, ['php', 'laravel/framework'])) {
    continue;
  } else {
    executeInstall($package, $commands_to_execute[1]." ".$package);
  }
}

function executeInstall($package, $command)
{
  global $publishings;

  shell_exec($command);
  if (array_key_exists($package, $publishings)) {
    shell_exec($publishings[$package]);
  }
}

?>
