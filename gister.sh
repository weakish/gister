#!/bin/sh

### a command line tool to access https://gist.github.com

## by Jakukyo Friel <weakish@gmail.com> and licensed under Apache v2.
## Depends:
# gist.rb
# curl
# git
# csearch (optional)
# jq
# xclip|xsel|pbpaste|cygutils-extra
# gsed/gdate on Mac OS X

## Ref:
# github API: https://develop.github.com/v3/
# gist API: https://developer.github.com/v3/gists/
# gist.rb: https://github.com/defunkt/gist
# gist clients: https://gist.github.com/370230
# csearch: https://github.com/google/codesearch
# jq: http://stedolan.github.io/jq/


SEMVER='v2.1.2'

# Mac OS X compatibility
if [ "$(uname)" = "Darwin" ]; then
  SED=gsed
  DATE=gdate
else
  SED=sed
  DATE=date
fi

help() {
cat<<'END'
gister  -- shell script to access https://gist.github.com

gister [ACTION]
gister description file.txt [...]

Actions:
sync            sync all your gists
search regexp   code search (command line)
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
gisthome=${GIST_HOME:=$(git config --global --path --get gist.home)}
if test -f $HOME/.gist; then
  github_oauth_token=$(cat $HOME/.gist)
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
    curl -s -H "Authorization: token $github_oauth_token" 'https://api.github.com/gists?per_page=100' > $gisthome/gists.list.dirty
    for i in $(seq 2 100000); do
      if ! (curl -s -H "Authorization: token $github_oauth_token"  "https://api.github.com/gists?page=$i&per_page=100" | jq '.' | grep --silent '^\[]$'); then
        curl -s -H "Authorization: token $github_oauth_token"  "https://api.github.com/gists?page=$i&per_page=100" >> $gisthome/gists.list.dirty
      else
        break
      fi
    done

    # If you have more than 100 gists, gists.list will contain more than one array.
    # Thus we need to combine them into one.
    cat $gisthome/gists.list.dirty |
    # delete all `[`s
    $SED -r '/^\[$/d' |
    # recover the first `[`
    $SED -r '1 i [' |
    # replace all `]`s to `,`
    $SED -r 's/^]$/,/g' |
    # delete `,` on the last line (JSON does not permit this!)
    $SED -r '$d' |
    # recover the last `]`
    $SED -r '$ a ]' > $gisthome/gists.list
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
  # Windows (Cygwin)
  elif check_command getclip; then
    getclip
  else
    echo 'Error: No clipboard command found!'
  fi
}

update_csearch_index() {
  if (which cindex > /dev/null); then
    export CSEARCHINDEX=$gisthome/.csearchindex
    cindex $gisthome/tree
  else  # do nothing
    echo 'codesearch is not installed. Skip building index.'
  fi
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
      local gist_id=$(get_paste | grep -o -E '/[0-9a-f]+$' | $SED -e 's/\///')
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
  if (which csearch > /dev/null); then
    export CSEARCHINDEX=$gisthome/.csearchindex
    csearch -i -l -n "$1"
  else
    grep -r -E "$1" $gisthome/tree
  fi
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
  read -p 'Enter full path to the directory: ' gist_store_directory
  git config --global gist.home $gist_store_directory
  gist_store_directory=$(git config --global --path --get gist.home)
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
  local gists_list_length=$(cat $gisthome/gists.list | jq '. | length')
  for i in $(seq 0 $(($gists_list_length - 1))); do
    local gist_id=$(cat $gisthome/gists.list | jq --raw-output ".[$i].id")
    local gist_updated_at=$(cat $gisthome/gists.list | jq --raw-output ".[$i].updated_at")
    sync_gist $gist_id $gist_updated_at
  done
  mark_deleted_gists
  update_csearch_index
}

sync_gist() {
  local gist_id=$1
  local gist_updated_at=$2
  echo "syncing $gist_id"
  if test -d $gisthome/tree/$gist_id; then
    cd $gisthome/tree/$gist_id
    # Compare update time to skip already up to date repos.
    # This will speed sync on slow network connection.
    local last_commit_unixtime=$(git log -1 --pretty=format:%ct)
    local last_updated_unixtime=$($DATE --date="$gist_updated_at" +"%s")
    local time_difference=$(($last_commit_unixtime - $last_updated_unixtime))
    local time_difference_abs=$(echo $time_difference | tr -d -)
    # Allow 6 seconds difference since local machine's and GitHub's time may differ slightly.
    if test $time_difference_abs -le 6; then
      echo "[x] $gist_id"
    else
      if [ $(git status --porcelain | wc -l) -eq 0 ]; then # clean
        git pull && git push
      else # dirty
        echo "DIRTY $gist_id"
      fi
    fi
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
      sed -i -r "s#tree/$argv[1]#tree/_$gist_id#" $gisthome/repo/$gist_id/config
    fi
  done
}


main "$@"
