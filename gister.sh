#!/bin/sh

### a command line tool to access https://gist.github.com

## by Jakukyo Friel <weakish@gmail.com> and licensed under Apache v2.
## Depends:
# gist.rb
# curl
# git
# csearch
# jq

## Ref:
# github API: https://develop.github.com/v3/
# gist API: https://developer.github.com/v3/gists/
# gist.rb: https://github.com/defunkt/gist
# gist clients: https://gist.github.com/370230
# csearch: https://code.google.com/p/codesearch/
# jq: http://stedolan.github.io/jq/

## Versions

semver='1.0.0' # released on 2013-09-16
#   - Use new storage hierarchy (seperate work tree and repo)
#   - Support github OAuth.
#   - Fetch all gists of the user (including private ones).
#   - Switch to csearch as code search backend.
#   - Change license to Apache v2 License.


# semver='0.3.0' # released on 2012-05-04
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
gister description file.txt [...]

Options:
-l          get info of all your gists
-m          migrate from <1.0.0
-s regexp   code search (command line)
-v          version
-h          this help page

Usage:

Run `gister -l` and a list of your gists will be saved in gists.list.  There are two
ways to set up the location of gists.list:  Using env var GIST_HOME or
set the gist.home option using git config.  Refer gist(ruby) manual on how
to set up GitHub user.

`gister description file.txt ...`  will create the gist with the provided description,
clone the gist repo, put the gistid to clipborad, and open the url in
your `x-www-browser`.
`gister` will pass all arguments to gist as `gist -c -o -d description ...`, so you use other options that gist understands,
e.g. `gister descrption -P` will work.

END
}

main() {
gisthome=${GIST_HOME:=`git config --get gist.home`}
gist_title=${GIST_TITLE:=`git config --get gist.title`}
github_user=${GITHUB_USER:=`git config --get github.user`}
github_oauth_token=`cat $HOME/.gist`

case $1 in
    -h)     help;;
    -l)     fetch_list;;
    -m)     migrate;;
    -s)     code_search $2;;
    -v)     echo gister $semver;;
     *)     publish "$@";;
esac
}


fetch_list() {
    echo 'I can only fetch up to 10 million gists for you.'
    mv $gisthome/gists.list $gisthome/gists.list.backup
    curl -s -H "Authorization: token $github_oauth_token" 'https://api.github.com/gists?per_page=100' > $gisthome/gists.list
    for i in `seq 2 100000`; do
      if ! (curl -s -H "Authorization: token $github_oauth_token"  "https://api.github.com/gists?page=$i&per_page=100" | jq '.' | grep --silent '^\[]$'); then
        curl -s -H "Authorization: token $github_oauth_token"  "https://api.github.com/gists?page=$i&per_page=100" >> $gisthome/gists.list
      else
        break
      fi
    done
}
    

publish() {
    local gist_description gist_argv
    gist_description="$1"
    shift 1
    gist_argv=$@
    # post gist and open it in browser
    gist -c -o -d "$gist_description" $gist_argv
    # record the id
    local gist_id=`xsel -o | grep -o -E '/[0-9a-f]+$' | sed -e 's/\///'`
    # add a record
    cd $gisthome
    curl -s -H "Authorization: token $github_oauth_token" 'https://api.github.com/gists?per_page=1' >> gists.list
    # clone
    cd $gisthome/tree
    git clone git@gist.github.com:$gist_id.git --separate-git-dir ../repo/$gist_id
    # code search index
    export CSEARCHINDEX=$gisthome/.csearchindex
    cindex
}


code_search() {
  export CSEARCHINDEX=$gisthome/.csearchindex
  csearch -i -l -n $1
}


migrate() {
  # migrate to new storage
  cd $gisthome
  mkdir tree
  ls --file-type --hide gonzui.db --hide tree | grep '/$' | xargs -I '{}' mv '{}' tree
  mkdir repo
  cd tree
  ls | xargs -I '{}' git init --separate-git-dir ../repo/'{}' '{}'

  # index via new engine 
  cd $gisthome
  export CSEARCHINDEX=$gisthome/.csearchindex
  cindex $gisthome/tree 
}

main "$@"
