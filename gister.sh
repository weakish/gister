#!/bin/sh

### a command line tool to access https://gist.github.com

## by Jakukyo Friel <weakish@gmail.com> and licensed under GPL v2

## Depends:
# gist.rb
# curl
# git
# gonzui

## Ref:
# github API: https://develop.github.com/v3/
# gist API: https://developer.github.com/v3/gists/
# gist.rb: https://github.com/defunkt/gist
# gist clients: https://gist.github.com/370230

## Versions
semver='0.3.0' # released on 2012-05-04
#   - Change backend back to gist.rb, since pygist stops to work due to api change.
#   - fetch_list() fetches public gists only. 
#     (I myself only creates public gists. So I'm too lazy to deal with
#     new oauth api. Patches are welcomed.)

# semver='0.2.0' # released on 2012-04-17
#   - change backend from gist.rb to pygsit
#   - remove clone_my_gists()
#   - fetch_list() fetches priveate gists too.
#   - fix a bug to actually support multiple files
#   - add support for gist description
#   - add gistid to pasteboard

# semver='0.1.0' # released on 2011-06-11
#   - bugfix: implement clone properly (yaml -> json)
#   - simplify publish()

# semver=0.0.0 # released on 2011-04-04

help() {
cat<<'END'
gister  -- shell script to access https://gist.github.com

gister [OPTION]
gister description file.txt [file ...]

Options:
-l          get info of all your public gists
-s pattern  code search (command line)
-s          code search (open a web browser)
-v          version
-h          this help page

Usage:

Run `gister -l` and a list of your public gists will be saved in gists.list.  There are two
ways to set up the location of gists.list:  Using env var GIST_HOME or
set the gist.home option using git config.  Refer gist(ruby) manual on how
to set up GitHub user.

`gister description file.txt`  will create the gist with the provided description,
clone the gist repo, put the gistid to clipborad, and open the url in
your `x-www-browser`.

END
}

main() {
gisthome=${GIST_HOME:=`git config --get gist.home`}
gist_title=${GIST_TITLE:=`git config --get gist.title`}
github_user=${GITHUB_USER:=`git config --get github.user`}

case $1 in
    -h)     help;;
    -l)     fetch_list;;
    -s)     code_search $2;;
    -v)     echo gister $semver;;
     *)     publish "$@";;
esac
}


fetch_list() {
    curl https://api.github.com/users/$github_user/gists > $gisthome/gists.list
}
    

publish() {
    local gist_description="$1"
    shift 1
    local gist_argv="$@"
    # post and get the id
    local gist_id=`gist -d "$gist_description" $gist_argv | grep -o -E '[0-9]+'`
    # TODO add a record
    cd $gisthome
    # clone
    git clone git@gist.github.com:$gist_id.git
    # import into gonzui search
    gonzui-import --exclude='\.git' $gist_id 
    # open the gist in browser
    x-www-browser https://gist.github.com/$gist_id
    # add gistid to pasteboard
    echo $gist_id | xsel
}


code_search() {
  cd $gisthome
  if [ -z $1 ]; then
    # If gonzui-server finds out that address is already binded when
    # starting up, it will stop automatically.
    # So no need to detect if gonzui-server is already running in
    # our script.
    gonzui-server &
    # wait for gonzui-server to start up
    sleep 2
    x-www-browser http://localhost:46984
  else
    gonzui-search -e $1
  fi  
}

main "$@"
