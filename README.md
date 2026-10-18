# gh-bootstrap

Get GitHub SSH credentials onto a fresh machine. Needs only Nix.

```sh
git clone https://github.com/gordoncyu/gh-bootstrap && cd gh-bootstrap

# key already in Bitwarden (SSH key item "github key <user>@<host>")
./gh-creds pull <github-user> --user gordo --host adequate-ssh-head

# new key: generate, log in with gh, upload it; --save-bw also stores it in Bitwarden
./gh-creds new <github-user> --user gordo --host adequate-ssh-head --save-bw
```

Without cloning: `curl -fsSL https://raw.githubusercontent.com/gordoncyu/gh-bootstrap/main/gh-creds | bash -s -- pull <github-user> ...`

`--user`/`--host` pick the Bitwarden item and default to `$USER` and `$(hostname)`.

The key goes to `~/.ssh/keys/gh-<github-user>` with a `Host gh-<github-user>`
entry in `~/.ssh/config`, so clone with `git clone git@gh-<github-user>:owner/repo.git`.
