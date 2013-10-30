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

# semver='2.0.0' # released on 2013-10-30
#   - redesign UI
#   - add init function
#   - improve documentation

# semver='1.0.0' # released on 2013-09-16
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

gister [ACTION]
gister description file.txt [...]

Actions:
list            get info of all your gists
migrate         migrate from <1.0.0
search regexp   code search (command line)
version         version
help            this help page

Usage:

`gister init` will associate your gists with your GitHub account and ask you where to store local copies of your gist.

Run `gister list` and a list of your gists will be saved in gists.list.

`gister description file.txt ...`  will create the gist with the provided description,
clone the gist repo, put the gistid to clipborad, and open the url in
your `x-www-browser`.
`gister` will pass all arguments to gist as `gist -c -o -d description ...`, so you use other options that gist understands,
e.g. `gister descrption -P` will work.

END
}

main() {
gisthome=${GIST_HOME:=`git config --get gist.home`}
github_oauth_token=`cat $HOME/.gist`

case $1 in
    help)       help;;
    list)       fetch_list;;
    search)     code_search $2;;
    init)       init;;
    migrate)    migrate;;
    version)    echo gister $semver;;
    *)          publish "$@";;
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
    if [ $# -eq 0 ]; then
      help
    else
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
    fi
}


code_search() {
  export CSEARCHINDEX=$gisthome/.csearchindex
  csearch -i -l -n $1
}

init() {
  echo 'Where do you want to store local copies of your gists?'
  read -p 'Enter full path to the directroy: ' gist_store_directory
  git config gist.home $gist_store_directory
  echo "Your gists will be stored at $gist_store_directory"
  echo 'You can overwrite this using environment variable $GIST_HOME'
  echo 'We need your username and password to get an OAuth2 token (with the "gist" permission).'
  echo 'We will not store your password.'
  gist --login
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
