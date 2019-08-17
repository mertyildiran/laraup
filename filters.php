<?php

$route_service_provider_path = $argv[2].'/app/Providers/RouteServiceProvider.php';
$filters_php_path = $argv[1];
$filters_php = file_get_contents($argv[1]);
$filters_php = preg_replace('/^.+\n/', '', $filters_php);
eval($filters_php);


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
    $lines[$i] = str_replace('App::bind', '$this->app->bind', "\t".$lines[$i]);
    echo $parent_boot_line_number;
    array_splice($route_service_provider, $parent_boot_line_number - $sign, 0, $lines[$i]);
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
}

?>
