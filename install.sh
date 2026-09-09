#!/bin/bash


# GITHUB_ID=yourname   # uncomment and set this to skip auto-detection

install_flux(){
    curl -s https://fluxcd.io/install.sh | sudo bash
}

detect_github_id(){
    local id=""
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        id=$(gh api user --jq .login 2>/dev/null)
    fi
    if [ -z "$id" ] && command -v git >/dev/null 2>&1; then
        id=$(printf 'protocol=https\nhost=github.com\n' \
             | GIT_TERMINAL_PROMPT=0 timeout 5 git credential fill 2>/dev/null \
             | sed -n 's/^username=//p')
    fi
    if [ -z "$id" ] && command -v ssh >/dev/null 2>&1; then
        id=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 \
             | sed -n 's/^Hi \([^!]*\)!.*/\1/p')
    fi
    echo "$id"
}

detect_account_type(){
    local login="$1"
    local type=""
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        type=$(gh api "users/$login" --jq .type 2>/dev/null)
    fi
    if [ -z "$type" ] && command -v curl >/dev/null 2>&1; then
        type=$(curl -s "https://api.github.com/users/$login" \
               | sed -n 's/.*"type": *"\([A-Za-z]*\)".*/\1/p' | head -n1)
    fi
    echo "$type"
}

if [ -n "$GITHUB_ID" ]; then
    echo "Using configured GitHub ID: $GITHUB_ID"
else
    GITHUB_ID=$(detect_github_id)
    if [ -n "$GITHUB_ID" ]; then
        echo "Detected GitHub ID: $GITHUB_ID"
    else
        echo "Could not determine your GitHub ID." >&2
        echo "Set GITHUB_ID at the top of this script (or export it before running) and try again." >&2
        exit 1
    fi
fi

account_type=$(detect_account_type "$GITHUB_ID")
case "$account_type" in
    Organization)
        PERSONAL=""
        echo "'$GITHUB_ID' looks like a GitHub Organization account; omitting --personal"
        ;;
    User)
        PERSONAL="--personal"
        echo "'$GITHUB_ID' looks like a personal GitHub account; using --personal"
        ;;
    *)
        PERSONAL="--personal"
        echo "Could not determine whether '$GITHUB_ID' is a personal or org account;" >&2
        echo "defaulting to --personal. Edit PERSONAL in this script if that's wrong." >&2
        ;;
esac


which kubectl || (
	echo You need to install kubectl and probably a cluster. You could try
	echo ' curl -sfL https://get.k3s.io | sh - '
)


which flux || install_flux

flux bootstrap github  --owner=$GITHUB_ID --repository=fluxcd-starterkit \
      --token-auth $PERSONAL \
      --path prod \
      --components-extra=image-reflector-controller,image-automation-controller

