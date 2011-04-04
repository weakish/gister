#!/usr/bin/env python3.1

# Author: Jakukyo Friel <weakish@gmail.com>
# License: GPL v2

'''make a navigation page for gists

Usage: gistnavi 'your title' yourusername > output.html

Note: all repos must have descriptions.

TODO:
- nice css layout
- tag filter using javascript
'''

import json
from string import Template

with open('gists.list') as gist_list_file:
  gist_list = gist_list_file.read()

gists = {
  gist['repo']:gist['description']
  for gist in tuple(json.loads(gist_list).values())[0]}

def gen_list_item(repo, description):
  return Template(
    '<li><a href="https://gist.github.com/$repo">$description<a></li>'
    ).substitute(repo=repo, description=description)

navi_list = ''.join(
  [gen_list_item(*(gist)) for gist in gists.items()])

def gen_page(title, navi_list, username):
  return Template('''
<html>
<head>
<title>$title</title>
</head>
<body>
<h1>$title</h1>
<p>
<a href="https://gist.github.com/$username.atom">subscribe</a>
<a href="https://gist.github.com/$username">with previews</a>
<p>
<ul>
$navi_list
<ul>
<p>
<form action="https://gist.github.com/gists/search" method="get">
<input name="q" value="" results="5" class="search" placeholder="Search Gists…" type="search"> <input value="Search" class="button" type="submit">
<input name="page" value="1" type="hidden">
</form>
</p>
</body>
</html>
''').substitute(title=title, navi_list=navi_list, username=username)

def main():
  import sys
  print(gen_page(sys.argv[1], navi_list, sys.argv[2]))

if __name__ == '__main__':
  main()
