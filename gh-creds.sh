usage() {
    cat <<USAGE
usage: gh-creds pull <github-user> [--user U] [--host H]
       gh-creds new  <github-user> [--user U] [--host H] [--save-bw] [--local]

The Bitwarden item is "github key U@H" (default: \$USER and \$(hostname)).

pull  on the target device: install that item's key as
      ~/.ssh/keys/gh-<github-user> with a "Host gh-<github-user>" entry
new   on a machine with a browser: generate a key for U@H and upload it
      with gh. --save-bw stores it in Bitwarden (then pull on the target),
      --local also installs it here like pull. Needs at least one of them.

Clone with: git clone git@gh-<github-user>:<owner>/<repo>.git
USAGE
}

die() { printf 'gh-creds: %s\n' "$*" >&2; exit 1; }

mode=${1:-}; gh_user=${2:-}
[[ $mode == pull || $mode == new ]] && [[ -n $gh_user && $gh_user != -* ]] || { usage >&2; exit 2; }
shift 2

bw_user=$USER
bw_host=$(hostname)
save_bw=0
local_install=0
while (( $# )); do
    case $1 in
        --user)    bw_user=${2:?--user needs a value}; shift 2 ;;
        --host)    bw_host=${2:?--host needs a value}; shift 2 ;;
        --save-bw) [[ $mode == new ]] || die "--save-bw is for new"; save_bw=1; shift ;;
        --local)   [[ $mode == new ]] || die "--local is for new"; local_install=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *)         usage >&2; exit 2 ;;
    esac
done

alias=gh-$gh_user
item="github key $bw_user@$bw_host"
key=$HOME/.ssh/keys/$alias

bw_unlock() {
    case $(bw status | jq -r .status) in
        unauthenticated) BW_SESSION=$(bw login --raw) ;;
        locked)          BW_SESSION=$(bw unlock --raw) ;;
    esac
    export BW_SESSION
    bw sync >/dev/null
}

[[ $mode == new ]] && (( ! save_bw && ! local_install )) && die "new needs --save-bw and/or --local"
[[ $mode == pull ]] && local_install=1

if (( local_install )); then
    install -d -m 700 ~/.ssh ~/.ssh/keys
    [[ $mode == new && -e $key ]] && die "$key exists; move it away first"
fi

if [[ $mode == pull ]]; then
    bw_unlock
    priv=$(bw list items --search "$item" | jq -r --arg n "$item" '[.[] | select(.name == $n)] | if length == 1 then .[0].sshKey.privateKey // empty else empty end')
    [[ -n $priv ]] || die "need exactly one Bitwarden SSH key item named \"$item\""
    printf '%s\n' "$priv" | install -m 600 /dev/stdin "$key"
    ssh-keygen -y -f "$key" > "$key.pub"
    echo "wrote $key"
else
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    gen=$tmp/key
    ssh-keygen -q -t ed25519 -N '' -C "$bw_user@$bw_host" -f "$gen"
    echo "generated key for $bw_user@$bw_host: $(ssh-keygen -lf "$gen.pub" | cut -d' ' -f2)"

    gh auth status >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --web
    gh auth refresh --hostname github.com --scopes admin:public_key
    gh ssh-key add "$gen.pub" --title "$bw_user@$bw_host"

    if (( save_bw )); then
        bw_unlock
        bw get template item | jq \
            --arg name "$item" --rawfile priv "$gen" --rawfile pub "$gen.pub" \
            --arg fp "$(ssh-keygen -lf "$gen.pub" | cut -d' ' -f2)" \
            '.type = 5 | .name = $name | .notes = null | .login = null
             | .sshKey = { privateKey: $priv, publicKey: ($pub | rtrimstr("\n")), keyFingerprint: $fp }' \
            | bw encode | bw create item >/dev/null
        echo "saved to Bitwarden as \"$item\""
    fi

    if (( local_install )); then
        install -m 600 "$gen" "$key"
        install -m 644 "$gen.pub" "$key.pub"
        echo "wrote $key"
    fi
fi

(( local_install )) || exit 0

if ! grep -qsx "Host $alias" ~/.ssh/config; then
    cat >> ~/.ssh/config <<CONF
Host $alias
    HostName github.com
    User git
    IdentityFile ~/.ssh/keys/$alias
    IdentitiesOnly yes
CONF
    chmod 600 ~/.ssh/config
fi

if ! ssh-keygen -F github.com >/dev/null 2>&1; then
    ssh-keyscan -t ed25519 github.com 2>/dev/null >> ~/.ssh/known_hosts
    echo "github.com host key: $(ssh-keygen -lf <(ssh-keyscan -t ed25519 github.com 2>/dev/null) | cut -d' ' -f2)"
    echo "GitHub publishes:    SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"
fi

ssh -T -o BatchMode=yes "git@$alias" 2>&1 | head -1 || true
