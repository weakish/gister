#!/usr/bin/env bats


# Dependencies

@test "curl installed" {
  command -v curl
}

@test "git installed" {
  command -v git
}

@test "gist.rb installed" {
  command -v gist
}

@test "csearch installed" {
  command -v csearch
}

@test "jq installed" {
  command -v jq
}

@test "clipboard command installed" {
  command -v xclip || command -v xsel || command -v pbcopy || command -v putclip
}

# prepare for enviroment

old_gisthome=`git config --get gist.home`
old_GIST_HOME=$GIST_HOME
GIST_HOME=''
git config --unset gist.home


# main

# FIXME we need a test account on GitHub to run tests.

# revert back
GIST_HOME=$old_GIST_HOME
git config --global old_gisthome
