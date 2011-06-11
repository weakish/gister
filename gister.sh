#!/bin/sh

### a command line tool to access https://gist.github.com

## by Jakukyo Friel <weakish@gmail.com> and licensed under GPL v2

## Ref:
# github API: https://develop.github.com/v3/
# gist API: https://developer.github.com/v3/gists/
# pygist: https://github.com/mattikus/pygist
# gist clients: https://gist.github.com/370230

## Versions

semver='0.2.0-devel' # released on
#   - change backend from gist.rb to pygsit
#   - remove clone_my_gists()
#   - fetch_list() fetches priveate gists too.
#   - fix a bug to actually support multiple files
#   - add support for gist description

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

Run `gister -l` and all the info will be saved in gists.list.  There are two
ways to set up the location of gists.list:  Using env var GIST_HOME or
set the gist.home option using git config.  Refer gist(ruby) manual on how
to set up GitHub user.


`gister description file.txt`  will create the gist with the provided description,
clone the gist repo, and open the url in your `x-www-browser`.


Depends:
- pygist: https://github.com/mattikus/pygist
- curl
- git

END
}

main() {
gisthome=${GIST_HOME:=`git config --get gist.home`}
gist_title=${GIST_TITLE:=`git config --get gist.title`}
github_user=${GITHUB_USER:=`git config --get github.user`}
github_token=${GITHUB_TOKEN:=`git config --get github.token`}

case $1 in
    -h)     help;;
    -l)     fetch_list;;
    -s)     code_search $2;;
    -v)     echo gister $semver;;
    # disable some pygist features
    -g)     echo 'invalid option `-g`'
    -p)     echo 'invalid option `-p`'
    -a)     echo 'invalid option `-a`'
     *)     publish "$@";;
esac
}


fetch_list() {
    curl -H "Authorization: token $github_token" https://api.github.com/users/$github_user/gists > $gisthome/gists.list
}
    

publish() {
    gist_description="$1"
    shift 1
    local gist_argv="$@"
    # post and get the id
    local gist_id=`pygist -d $gist_description $gist_argv | grep -o -E '[0-9]+'`
    # TODO add a record
    cd $gisthome
    # clone
    git clone git@gist.github.com:$gist_id.git
    # import into gonzui search
    gonzui-import --exclude='\.git' $gist_id 
    # open the gist in browser
    x-www-browser https://gist.github.com/$gist_id
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
