#!/bin/sh

### a command line tool to access https://gist.github.com

## by Jakukyo Friel <weakish@gmail.com> and licensed under Apache v2.
## Depends:
# gist.rb
# curl
# git
# csearch
# jq
# xclip|xsel|pbpaste|cygutils-extra

## Ref:
# github API: https://develop.github.com/v3/
# gist API: https://developer.github.com/v3/gists/
# gist.rb: https://github.com/defunkt/gist
# gist clients: https://gist.github.com/370230
# csearch: https://code.google.com/p/codesearch/
# jq: http://stedolan.github.io/jq/


SEMVER='v2.1.1'

help() {
cat<<'END'
gister  -- shell script to access https://gist.github.com

gister [ACTION]
gister description file.txt [...]

Actions:
sync            sync all your gists
search regexp   code search (command line)
sync            sync with gist.github.com
migrate         migrate from <1.0.0
version         version
help            this help page

Usage:

`gister init` will associate your gists with your GitHub account and ask you where to store local copies of your gist.

Run `gister sync` to sync all your gists.

`gister description file.txt ...`  will create the gist with the provided description,
clone the gist repo, put the gistid to clipborad, and open the url in
your `x-www-browser`.
`gister` will pass all arguments to gist as `gist -c -o -d description ...`, so you can use other options that gist understands,
e.g. `gister descrption -P` will work.

END
}

main() {
gisthome=${GIST_HOME:=`git config --get gist.home`}
if test -f $HOME/.gist; then
  github_oauth_token=`cat $HOME/.gist`
else
  echo 'You need a github oauth2 token.'
fi

set -e

case $1 in
    fetchall)             fetchall;;
    help|-h|--help)       help;;
    init)                 init;;
    migrate)              migrate;;
    search)               code_search $2;;
    sync)                 sync;;
    version)              echo gister $SEMVER;;
    *)                    publish "$@";;
esac
}

fetchlist() {
    echo 'I can only fetch up to 10 million gists for you.'
    if test -f $gisthome/gists.list; then
      mv $gisthome/gists.list $gisthome/gists.list.backup
    fi
    curl -s -H "Authorization: token $github_oauth_token" 'https://api.github.com/gists?per_page=100' > $gisthome/gists.list
    for i in `seq 2 100000`; do
      if ! (curl -s -H "Authorization: token $github_oauth_token"  "https://api.github.com/gists?page=$i&per_page=100" | jq '.' | grep --silent '^\[]$'); then
        curl -s -H "Authorization: token $github_oauth_token"  "https://api.github.com/gists?page=$i&per_page=100" >> $gisthome/gists.list
      else
        break
      fi
    done
}


fetchall() {
  echo '`fetchall` is deprecated. Use `gister sync` instead.'
  sync
}


check_command() {
  to_check_command=$1
  command -v  $to_check_command >/dev/null 2>&1
}

get_paste() {
  # Linux, BSD, etc
  if check_command  xclip; then
    xclip -o
  elif check_command xsel; then
    xsel -o
  # Mac OS X
  elif check_command pbpaste; then
    pbpaste
  elif check_command getclip; then
    getclip
  else
    echo 'Error: No clipboard command found!'
  fi
}

update_csearch_index() {
  export CSEARCHINDEX=$gisthome/.csearchindex
  cindex
}

publish() {
    local gist_description gist_argv
    gist_description="$1"
    shift 1
    if [ $# -eq 0 ]; then
      help
    else
      gist_argv=$@
      # post gist and open it in browser
      gist -c -o -d "$gist_description" $gist_argv
      # record the id
      local gist_id=`get_paste | grep -o -E '/[0-9a-f]+$' | sed -e 's/\///'`
      # add a record
      cd $gisthome
      curl -s -H "Authorization: token $github_oauth_token" 'https://api.github.com/gists?per_page=1' >> gists.list
      # clone
      cd $gisthome/tree
      git clone git@gist.github.com:$gist_id.git --separate-git-dir $gisthome/repo/$gist_id
      # code search index
      update_csearch_index
    fi
}


code_search() {
  export CSEARCHINDEX=$gisthome/.csearchindex
  csearch -i -l -n $1
}

init() {
  # login
  if ! test -f $HOME/.gist; then
    echo 'We need your username and password to get an OAuth2 token (with the "gist" permission).'
    echo 'We will not store your password.'
    gist --login
    echo 'Your GitHub OAuth2 token is stored at ~/.gist'
  fi
  # store
  echo 'Where do you want to store local copies of your gists?'
  read -p 'Enter full path to the directroy: ' gist_store_directory
  git config --global gist.home $gist_store_directory
  mkdir -p $gist_store_directory/tree $gist_store_directory/repo
  echo "Your gists will be stored at $gist_store_directory"
  echo 'You can overwrite this using environment variable $GIST_HOME'
}

migrate() {
  # migrate to new storage
  cd $gisthome
  mkdir -p tree
  ls --file-type --hide gonzui.db --hide tree --hide repo | grep '/$' | xargs -I '{}' mv '{}' tree
  mkdir -p repo
  cd tree
  ls | xargs -I '{}' git init --separate-git-dir ../repo/'{}' '{}'

  # index via new engine 
  update_csearch_index
}


sync() {
  fetchlist
  cd $gisthome
  for gist_id in $(cat $gisthome/gists.list |
  grep -F '"git_pull_url":' |
  grep -oE 'gist\.github\.com/[0-9a-f]+\.git' |
  sed -r 's/gist\.github\.com\/([0-9a-f]+)\.git/\1/'); do
    sync_gist $gist_id
  done
  mark_deleted_gists
  update_csearch_index
}

sync_gist() {
  gist_id=$1
  echo "syncing $gist_id"
  if test -d $gisthome/tree/$gist_id; then
    cd $gisthome/tree/$gist_id
    git pull && git push
  else
    cd $gisthome/tree
    git clone --separate-git-dir $gisthome/repo/$gist_id git@gist.github.com:$gist_id.git
  fi
}

mark_deleted_gists() {
  cd $gisthome/tree
  for gist_id in [0-9a-f]*; do
    if !  grep -F -q '"git_pull_url": "https://gist.github.com/'$gist_id'.git"' $gisthome/gists.list; then
      mv $gist_id _$gist_id
    fi
  done
}


main "$@"
