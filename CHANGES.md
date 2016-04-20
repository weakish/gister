gister changes
==============

v2.1.2 (2016-04-20)
----------------

- sync: Compare update time to skip already up to date repos.
- Use `gsed` and `gdate` on Mac OS X. Fix #14.

v2.1.1 (2013-11-09)
------------------

- mark deleted gists
- add rakefile
- fix a typo in manual


v2.1.0 (2013-11-04)
------------------

- seperate `fetchlist()` from `fetchall()`
- seperate `update_csearch_index()` from `publish()` and `migrate()`
- also support `-h` and `--help`
- replace `fetchall()` with `sync()`
- move changelog to a seperate file
- add manual
- add tests

v2.0.3-alpha (2013-11-03)
------------------------

Fix a bug that causes `gister` to fail if `gist.home` unset. Thanks to wenLiangcan.

v2.0.2 (2013-11-01)
------------------

Yet another hotfix version.

- remove confusing error message
- `init()` does not get oauth2 token if already exist.
- `init()`: `gist.home` should be global. Thanks wenLiangcan.
- `fetchall()`: fix a bug that causes git clone to fail.

v2.0.1 (2013-10-31)
-------------------

- add support for Mac OS X and Cygwin
- add support for xclip

v2.0.0 (2013-10-30)
-------------------

- redesign UI
- add init function
- replace `fetch_list()` with `fetchall()`, which fetches all your gists.
- improve documentation

v1.0.0 (2013-09-16)
-------------------

- Use new storage hierarchy (seperate work tree and repo)
- Support github OAuth.
- Fetch all gists of the user (including private ones).
- Switch to csearch as code search backend.
- Change license to Apache v2 License.


v0.3.0 (2012-05-04)
-------------------

- Change backend back to gist.rb, since pygist stops to work due to api change.

- `fetch_list()` fetches public gists only.
    (I myself only creates public gists. So I'm too lazy to deal with
    new oauth api. Patches are welcomed.)

v0.2.0 (2012-04-17)
-------------------

- change backend from gist.rb to pygsit
- remove `clone_my_gists()`
- `fetch_list()` fetches priveate gists too.
- fix a bug to actually support multiple files
- add support for gist description
- add gistid to pasteboard

v0.1.0 (2011-06-11)
-------------------

- bugfix: implement clone properly (yaml -> json)
- simplify `publish()`

v0.0.0 (2011-04-04)
-------------------

- first version
