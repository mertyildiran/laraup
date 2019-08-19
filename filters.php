<?php

$new_project_path = $argv[2];
$route_service_provider_path = $new_project_path.'/app/Providers/RouteServiceProvider.php';
$filters_php_path = $argv[1];
$filters_php = file_get_contents($filters_php_path);
$filters_php = preg_replace('/^.+\n/', '', $filters_php);
eval($filters_php);


function applyTheFixes($line)
{
  $line = str_replace('App::bind', '$this->app->bind', $line);
  $line = str_replace('$request->', 'request()->', $line);
  return $line;
}

function getLineWithString($fileName, $str) {
    $lines = file($fileName);
    foreach ($lines as $lineNumber => $line) {
        if (strpos($line, $str) !== false) {
            return $lineNumber;
        }
    }
    return -1;
}

function handleAppFilter(Closure $closure, $is_before)
{
  global $route_service_provider_path;
  global $filters_php_path;

  $sign = -1;
  if ($is_before) {
    $sign = 1;
  }
  
  $reflFunc = new ReflectionFunction($closure);
  $filename = $reflFunc->getFileName(); 
  $startline = $reflFunc->getStartLine() + 1; 
  $endline = $reflFunc->getEndLine() - 1;

  $parent_boot_line_number = getLineWithString($route_service_provider_path, 'parent::boot();');

  $route_service_provider = file($route_service_provider_path);
  $lines = file($filters_php_path);
  for ($i = $startline; $i <= $endline; $i++) {
    $lines[$i] = applyTheFixes($lines[$i]);
    array_splice($route_service_provider, $parent_boot_line_number - $sign, 0, "\t".$lines[$i]);
    $parent_boot_line_number += $sign;
  }
  file_put_contents($route_service_provider_path, implode($route_service_provider));
}

class App
{
  public static function before(Closure $closure)
  {
    handleAppFilter($closure, true);
  }

  public static function after(Closure $closure)
  {
    handleAppFilter($closure, false);
  }

  public static function environment()
  {
    return false;
  }
}

class Route
{
  public static function filter($name, Closure $closure)
  {
    global $new_project_path;
    global $filters_php_path;

    $middleware_return_line_number = 18;

    $reflFunc = new ReflectionFunction($closure);
    $filename = $reflFunc->getFileName(); 
    $startline = $reflFunc->getStartLine() + 1; 
    $endline = $reflFunc->getEndLine() - 1;

    shell_exec("cd ".$new_project_path." && php artisan make:middleware ".ucfirst($name));
    $middleware_path = $new_project_path.'/app/Http/Middleware/'.ucfirst($name).'.php';

    $middleware = file($middleware_path);
    $lines = file($filters_php_path);
    for ($i = $startline; $i <= $endline; $i++) {
      array_splice($middleware, $middleware_return_line_number - 1, 0, "\t".$lines[$i]);
      $middleware_return_line_number++;
    }
    file_put_contents($middleware_path, implode($middleware));
  }
}

class View
{
  public static function composer($pattern, Closure $closure)
  {
    return false;
  }

  public static function share($key, $value)
  {
    return false;
  }
}

?>
