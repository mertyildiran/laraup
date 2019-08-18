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

foreach ($require as $package => $version) {
  if (in_array($package, ['php', 'laravel/framework'])) {
    continue;
  } else if ($package === 'cartalyst/sentry') {
    shell_exec("cd ".$new_project_path." && composer require cartalyst/sentry:dev-feature/laravel-5 && php artisan vendor:publish --provider=\"Cartalyst\Sentry\SentryServiceProvider\"");
  } else {
    shell_exec("cd ".$new_project_path." && composer require ".$package);
  }
}

foreach ($require_dev as $package => $version) {
  if (in_array($package, ['php', 'laravel/framework'])) {
    continue;
  } else {
    shell_exec("cd ".$new_project_path." && composer require --dev ".$package);
  }
}


?>
