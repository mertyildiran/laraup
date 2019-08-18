<?php

$old_project_path = $argv[1];
$new_project_path = $argv[2];

$old_composer_json_file_path = $old_project_path.'/composer.json';
$old_composer_json_content = file_get_contents($old_composer_json_file_path);

$new_composer_json_file_path = $new_project_path.'/composer.json';
$new_composer_json_content = file_get_contents($new_composer_json_file_path);

$old_composer_array = json_decode($old_composer_json_content, true);
$new_composer_array = json_decode($new_composer_json_content, true);

$new_composer_array['repositories'] = $old_composer_array['repositories'];
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
    $commands_to_execute[0] = $commands_to_execute[0]." cartalyst/sentry:dev-feature/laravel-5";
    array_push($commands_to_execute, "php artisan vendor:publish --provider=\"Cartalyst\Sentry\SentryServiceProvider\"");
  } else {
    $commands_to_execute[0] = $commands_to_execute[0]." ".$package;
  }
}

foreach ($require_dev as $package => $version) {
  if (in_array($package, ['php', 'laravel/framework'])) {
    continue;
  } else {
    $commands_to_execute[1] = $commands_to_execute[1]." ".$package;
  }
}

foreach ($commands_to_execute as $command) {
  shell_exec($command);
}

?>
