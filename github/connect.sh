if gh auth status >/dev/null 2&>1; then # already set up
	echo "✓ Already authenticated with GitHub"
	return
fi

SSH_CONFIG=~/.ssh/config
SSH_KEY_PRIV=~/.ssh/github.com/id_ed25519
SSH_KEY_PUB=${SSH_KEY_PRIV}.pub

update_ssh_config() {
	if ! grep '^Host github.com' $SSH_CONFIG >/dev/null 2&>1; then
	# if ! grep '^Host github.com' $SSH_CONFIG 2 >/dev/null &>1; then
		cat <<-eof >>$SSH_CONFIG
			Host github.com
				UseKeychain yes
				IdentitiesOnly yes
				IdentityFile $SSH_KEY_PRIV
		eof
	else
		echo "✓ SSH key for GitHub already set up"
	fi
}

gen_key() {
	if [[ ! -f $SSH_KEY_PRIV ]]; then
		ssh-keygen -t ed25519 -C "GitHub CLI ($(whoami)@$(hostname))" -f $SSH_KEY_PRIV -N ""
	else
		echo "✓ Already existing SSH key for GitHub"
	fi
}

set_permissions() {
	chmod 600 $SSH_KEY_PRIV && chmod 644 $SSH_KEY_PUB
}

mkdir -p $(dirname $SSH_KEY_PRIV) &&
	gen_key &&
	set_permissions &&
	update_ssh_config

gh auth login --web --git-protocol ssh --skip-ssh-key --scopes admin:public_key || return 1
gh ssh-key add $SSH_KEY_PUB && gh auth status
