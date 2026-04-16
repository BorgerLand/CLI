#!/usr/bin/env bash
set -e

if ! command -v git &>/dev/null; then
	echo "ERROR: You need to install git in order to cook borger."
	exit 1
fi

install_dir=$HOME/.borger

if ! command -v rustup &>/dev/null; then
	read -rp "Rustup is not installed. Would you like to install it? (y/n) " response </dev/tty
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
		export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"
	else
		exit 1
	fi
fi

if ! command -v bun &>/dev/null; then
	read -rp "Bun is not installed. Would you like to install it? (y/n) " response </dev/tty
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		curl -fsSL https://bun.sh/install | bash
	else
		exit 1
	fi
fi

#wasm-pack has some unreleased features regarding custom profiles
#https://github.com/drager/wasm-pack/pull/1489
cargo install --git https://github.com/Argeo-Robotics/wasm-pack.git --rev 956f6e4 --locked
cargo install cargo-watch --locked --version 8.5.3

mkdir -p $install_dir
curl -fsSLo $install_dir/borger https://raw.githubusercontent.com/BorgerLand/CLI/refs/heads/main/borger
chmod +x $install_dir/borger

if command -v borger >/dev/null; then
	echo
	echo "Command \`borger\` armed and ready."
	exit 0
fi

tildify() {
    if [[ $1 = $HOME/* ]]; then
        local replacement=\~/

        echo "${1/$HOME\//$replacement}"
    else
        echo "$1"
    fi
}

install_env=BORGER_INSTALL
tilde_dir=$(tildify "$install_dir")
quoted_install_dir=\"${install_dir//\"/\\\"}\"

if [[ $quoted_install_dir = \"$HOME/* ]]; then
	quoted_install_dir=${quoted_install_dir/$HOME\//\$HOME/}
fi

echo

case $(basename "$SHELL") in
fish)
	commands=(
		"set --export $install_env $quoted_install_dir"
		"set --export PATH $install_env \$PATH"
	)

	fish_config=$HOME/.config/fish/config.fish
	tilde_fish_config=$(tildify "$fish_config")

	if [[ -w $fish_config ]]; then
		{
			echo -e '\n# borger'

			for command in "${commands[@]}"; do
				echo "$command"
			done
		} >>"$fish_config"

		echo "Added \"$tilde_dir\" to \$PATH in \"$tilde_fish_config\""
	else
		echo "Manually add the directory to $tilde_fish_config (or similar):"

		for command in "${commands[@]}"; do
			echo "  $command"
		done
	fi
	;;
zsh)
	commands=(
		"export $install_env=$quoted_install_dir"
		"export PATH=\"\$$install_env:\$PATH\""
	)

	zsh_config=$HOME/.zshrc
	tilde_zsh_config=$(tildify "$zsh_config")

	if [[ -w $zsh_config ]]; then
		{
			echo -e '\n# borger'

			for command in "${commands[@]}"; do
				echo "$command"
			done
		} >>"$zsh_config"

		echo "Added \"$tilde_dir\" to \$PATH in \"$tilde_zsh_config\""
	else
		echo "Manually add the directory to $tilde_zsh_config (or similar):"

		for command in "${commands[@]}"; do
			echo "  $command"
		done
	fi
	;;
bash)
	commands=(
		"export $install_env=$quoted_install_dir"
		"export PATH=\"\$$install_env:\$PATH\""
	)

	bash_configs=(
		"$HOME/.bash_profile"
		"$HOME/.bashrc"
	)

	if [[ ${XDG_CONFIG_HOME:-} ]]; then
		bash_configs+=(
			"$XDG_CONFIG_HOME/.bash_profile"
			"$XDG_CONFIG_HOME/.bashrc"
			"$XDG_CONFIG_HOME/bash_profile"
			"$XDG_CONFIG_HOME/bashrc"
		)
	fi

	set_manually=true
	for bash_config in "${bash_configs[@]}"; do
		tilde_bash_config=$(tildify "$bash_config")

		if [[ -w $bash_config ]]; then
			{
				echo -e '\n# borger'

				for command in "${commands[@]}"; do
					echo "$command"
				done
			} >>"$bash_config"

			echo "Added \"$tilde_dir\" to \$PATH in \"$tilde_bash_config\""

			set_manually=false
			break
		fi
	done

	if [[ $set_manually = true ]]; then
		echo "Manually add the directory to $tilde_bash_config (or similar):"

		for command in "${commands[@]}"; do
			echo "  $command"
		done
	fi
	;;
*)
	echo 'Manually add the directory to ~/.bashrc (or similar):'
	echo "  export $install_env=$quoted_install_dir"
	echo "  export PATH=\"\$$install_env:\$PATH\""
	;;
esac

echo
echo "Please restart your terminal/shell to use the \`borger\` command."
