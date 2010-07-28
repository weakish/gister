#!/bin/sh

### a command line tool to access http://gist.github.com

## by weakish <weakish@gmail.com> and licensed under GPL v2

## Ref:
# github API: http://develop.github.com/p/general.html
# gist API: http://develop.github.com/p/gist.html
# gist.rb: http://github.com/defunkt/gist
# gist clients: http://gist.github.com/370230



help() {
cat<<'END'
gister  -- shell script to access http://gist.github.com

gister [OPTION] file.txt

Options:
-a    clone all your public gists
-l    get info of all your public gists
-h    this help page

Usage:

Run `gister -l` and all the info will be saved in gists.list.  There are two
ways to set up the location of gists.list:  Using env var GIST_HOME or
set the gist.home option using git-config.  Refer gist(ruby) manual on how
to set up GitHub user.

`gister -a` require the gists.list file.  gists will be cloned in the same
directory as gists.list's.

`gister file.txt`  will create the gist, record its metainfo in gists.list
and clone the gist repo.

Since we just pass arguments to gist.rb, it's possible to use
`gister -t ext file`, or `echo 'hello' | gister`.    

Depends:
- gist (ruby http://github.com/defunkt/gist)
- curl
- git
END
}

main() {
gisthome=${GIST_HOME:=`git-config --get gist.home`}

case $1 in
    -l)     fetch_list;;
    -a)     clone_my_gists;;
    -h)     help;;
     *)     publish $*;;
esac
}


fetch_list() {
    curl http://gist.github.com/api/v1/yaml/gists/${GITHUB_USER:=`git-config --get github.user`} >> $gisthome/gists.list
}
    
clone_my_gists() {
# public gists only due to API limit
    cd $gisthome
    grep -E ':repo: "[0-9]+"' gists.list |
    grep -o -E '[0-9]+' |
    sed -r -e 's/^/git@gist\.github\.com:/' |
    sed -r -e 's/$/\.git/' |
    xargs -0 echo #git clone # require -0 since newlines
}

publish() {
    local gist_argv=$*
    # post and get the id
    local gist_id=`gist $gist_argv | grep -o -E '[0-9]+'`
    # add a record
    curl http://gist.github.com/api/v1/yaml/$gist_id >> $gisthome/gists.list
    # clone
    cd $gisthome
    git clone git@gist.github.com:$gist_id.git
}

main $*
