<?php

class Route
{
  public static $api_lines = [];
  public static $api_starts_at = null;

  public static function get($args) {
    $args = func_get_args();
    $trace = debug_backtrace();
    $controller = '';
    if (is_array($args[1])) {
      $controller = $args[1]['uses'];
    } else {
      $controller = $args[1];
    }

    if (substr($controller, 0, 4) === "Api\\") {
      Route::check_api($trace, true);
    } else {
      Route::check_api($trace, false);
    }
  }

  public static function controller($args) {
    $args = func_get_args();
    $trace = debug_backtrace();
    $controller = $args[1];
    //var_dump($controller);
    if (substr($controller, 0, 4) === "Api\\") {
      Route::check_api($trace, true);
    } else {
      Route::check_api($trace, false);
    }

  }
  
  public static function group($args) {
    $trace = debug_backtrace();

    if (is_array($args)) {
      if (array_key_exists('prefix', $args) && $args['prefix'] === 'api') {
        Route::check_api($trace, true);
      } else {
        Route::check_api($trace, false);
      }
    }
  }

  public static function __callStatic($name, $args) {
    $trace = debug_backtrace();
    Route::check_api($trace, false);
  }

  private static function check_api($trace, $api) {
    if (is_null(self::$api_starts_at) && $api) {
      //var_dump($trace);
      self::$api_starts_at = $trace[0]['line'];
    } else if (!is_null(self::$api_starts_at) && !$api) {
      self::$api_lines = array_merge(self::$api_lines, range(self::$api_starts_at, $trace[0]['line']-2));
      self::$api_starts_at = null;
    }
  }

}

$old_routes_php = file_get_contents($argv[1]);
$new_routes_directory = $argv[2];

$old_routes_php = preg_replace('/^.+\n/', '', $old_routes_php);

eval($old_routes_php);

//var_dump(Route::$api_lines);

$lines = explode("\n", $old_routes_php);

$new_routes_directory_api = $new_routes_directory.'/api.php';
$routes_api_php = fopen($new_routes_directory_api, 'a') or die('Cannot open file:  '.$new_routes_directory_api);
$new_routes_directory_web = $new_routes_directory.'/web.php';
$routes_web_php = fopen($new_routes_directory_web, 'a') or die('Cannot open file:  '.$new_routes_directory_web);

$i = 1;
foreach($lines as $line) {
  if (in_array($i, Route::$api_lines)) {
    fwrite($routes_api_php, "\t".$line."\n");
  } else {
    fwrite($routes_web_php, $line."\n");
  }
  $i++;
}

fclose($routes_api_php);
fclose($routes_web_php);
?>

