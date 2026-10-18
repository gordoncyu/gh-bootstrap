# gh-bootstrap

Get GitHub SSH credentials onto a fresh machine. Needs only Nix.

```sh
# key already in Bitwarden (SSH key item "github key <user>@<host>")
nix --extra-experimental-features 'nix-command flakes' run github:gordoncyu/gh-bootstrap -- pull <github-user> --user gordo --host adequate-ssh-head

# new key: generate, log in with gh, upload it; --save-bw also stores it in Bitwarden
nix --extra-experimental-features 'nix-command flakes' run github:gordoncyu/gh-bootstrap -- new <github-user> --user gordo --host adequate-ssh-head --save-bw
```

`--user`/`--host` pick the Bitwarden item and default to `$USER` and `$(hostname)`.

The key goes to `~/.ssh/keys/gh-<github-user>` with a `Host gh-<github-user>`
entry in `~/.ssh/config`, so clone with `git clone git@gh-<github-user>:owner/repo.git`.
