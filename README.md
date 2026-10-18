# gh-bootstrap

Get GitHub SSH credentials onto a fresh machine. Needs only Nix.

```sh
git clone https://github.com/gordoncyu/gh-bootstrap && cd gh-bootstrap

# key already in Bitwarden (SSH key item "github key <user>@<host>")
./gh-creds pull <github-user> --user gordo --host adequate-ssh-head

# no key yet: on a machine with a browser, make one for the target and store it
./gh-creds new <github-user> --user gordo --host adequate-ssh-head --save-bw
# then on the target, pull as above (new --local installs it on this machine instead/too)
```

Without cloning: `curl -fsSL https://raw.githubusercontent.com/gordoncyu/gh-bootstrap/main/gh-creds | bash -s -- pull <github-user> ...`

`--user`/`--host` pick the Bitwarden item and default to `$USER` and `$(hostname)`.

The key goes to `~/.ssh/keys/gh-<github-user>` with a `Host gh-<github-user>`
entry in `~/.ssh/config`, so clone with `git clone git@gh-<github-user>:owner/repo.git`.
