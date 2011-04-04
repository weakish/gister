#!/bin/sh

### a command line tool to access http://gist.github.com

## by Jakukyo Friel <weakish@gmail.com> and licensed under GPL v2

## Ref:
# github API: http://develop.github.com/p/general.html
# gist API: http://develop.github.com/p/gist.html
# gist.rb: http://github.com/defunkt/gist
# gist clients: http://gist.github.com/370230

## Versions

semver='0.0.1 devel' # released on
  # - record descriptions
  # - bugfix: implement clone properly (yaml -> json)

# semver=0.0.0 # released on 2011-04-04

help() {
cat<<'END'
gister  -- shell script to access http://gist.github.com

gister [OPTION] file.txt [morefile]

Options:
-a          clone all your public gists
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

`gister -a` require the gists.list file.  gists will be cloned in the same
directory as gists.list's.

`gister file.txt`  will create the gist, record its metainfo in gists.list,
clone the gist repo, and open the url in your `x-www-browser`.

Since we just pass arguments to gist.rb, it's possible to use
`gister -t ext file`, or `echo 'hello' | gister`.    

Depends:
- gist (ruby http://github.com/defunkt/gist)
- curl
- git
END
}

main() {
gisthome=${GIST_HOME:=`git config --get gist.home`}

case $1 in
    -a)     clone_my_gists;;
    -h)     help;;
    -l)     fetch_list;;
    -s)     code_search $2;;
    -v)     echo gister $semver;;
     *)     publish $*;;
esac
}


fetch_list() {
    curl http://gist.github.com/api/v1/json/gists/${GITHUB_USER:=`git config --get github.user`} > $gisthome/gists.list
}
    
clone_my_gists() {
# public gists only due to API limit
    cd $gisthome
    grep -oE '"repo":"[0-9]+"' gists.list |
    grep -oE '[0-9]+' |
    sed -r -e 's/^/git@gist\.github\.com:/' |
    sed -r -e 's/$/\.git/' |
    xargs -0 git clone # require -0 since newlines
}

publish() {
    local gist_argv=$*
    # post and get the id
    local gist_id=`gist $gist_argv | grep -o -E '[0-9]+'`
    # add a record
    cd $gisthome
    # we add the previous gist, and leave current gist to next
    # time.
    # Thus we can have description recorded.
    curl http://gist.github.com/api/v1/json/`cat tip` >> $gisthome/gists.list
    echo $gist_id > tip
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
