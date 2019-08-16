<?php

function fixContentTags($value, $regex)
{
  $contentTags = array('{{', '}}');

  $pattern = sprintf($regex, $contentTags[0], $contentTags[1]);

  $callback = function($matches)
  {
    $whitespace = empty($matches[3]) ? '' : $matches[3].$matches[3];

    return $matches[1] ? substr($matches[0], 1) : '{!! '.$matches[2].' !!}'.$whitespace;
  };

  return preg_replace_callback($pattern, $callback, $value);
}

function fixEscapedTags($value, $regex)
{
  $escapedTags = array('{{{', '}}}');

  $pattern = sprintf($regex, $escapedTags[0], $escapedTags[1]);

  $callback = function($matches)
  {
    $whitespace = empty($matches[2]) ? '' : $matches[2].$matches[2];

    return '{{ '.$matches[1].' }}'.$whitespace;
  };

  return preg_replace_callback($pattern, $callback, $value);
}

$blade_content = file_get_contents($argv[1]);

// Fixes the facades like HTML, From, Lang, Input, Config, URL, Request, etc. which are all capitalized
$blade_content = fixContentTags($blade_content, '/(@)?%s\s*([A-Z].+?)\s*%s(\r?\n)?/s');

// Fixes the helper named link_to_route()
$blade_content = fixContentTags($blade_content, '/(@)?%s\s*(link_to_route.+?)\s*%s(\r?\n)?/s');
// Fixes the helper named action_links()
$blade_content = fixContentTags($blade_content, '/(@)?%s\s*(action_links.+?)\s*%s(\r?\n)?/s');
// Fixes the helper named json_encode()
$blade_content = fixContentTags($blade_content, '/(@)?%s\s*(json_encode.+?)\s*%s(\r?\n)?/s');

// Replaces all {{{ }}} with {{ }}
$blade_content = fixEscapedTags($blade_content, '/%s\s*(.+?)\s*%s(\r?\n)?/s');

file_put_contents($argv[1], $blade_content);

?>
