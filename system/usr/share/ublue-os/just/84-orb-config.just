# Use Zsh as the shell for all recipes in this Justfile
set shell := ["zsh", "-eu", "-c"]

# Setup Neovim, dotfiles (tmux, ghostty, zshrc), starship config, and install Oh My Zsh for the current user
setup-dev-env:
    # Ensure $HOME exists (should be true for normal users, but safe for root in containers)
    mkdir -p "$HOME"

    # Install Oh My Zsh if not already present
    export ZSH="$HOME/.oh-my-zsh"
    if [ ! -d "$ZSH" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Clone Neovim config
    rm -rf /tmp/unemployee.nvim
    git clone --depth=1 https://github.com/Ariffansyah/unemployee.nvim.git /tmp/unemployee.nvim
    mkdir -p "$HOME/.config"
    rm -rf "$HOME/.config/nvim"
    mv /tmp/unemployee.nvim "$HOME/.config/nvim"

    # Clone dotfiles
    rm -rf /tmp/dotfiles
    git clone --depth=1 https://github.com/Ariffansyah/dotfiles.git /tmp/dotfiles

    # Move tmux config
    if [ -d /tmp/dotfiles/.config/tmux ]; then
        rm -rf "$HOME/.config/tmux"
        mv /tmp/dotfiles/.config/tmux "$HOME/.config/tmux"
    fi

    # Move ghostty config
    if [ -d /tmp/dotfiles/.config/ghostty ]; then
        rm -rf "$HOME/.config/ghostty"
        mv /tmp/dotfiles/.config/ghostty "$HOME/.config/ghostty"
    fi

    # Move starship config
    if [ -f /tmp/dotfiles/.config/starship.toml ]; then
        rm -f "$HOME/.config/starship.toml"
        mv /tmp/dotfiles/.config/starship.toml "$HOME/.config/starship.toml"
    fi

    # Move .zshrc
    if [ -f /tmp/dotfiles/.zshrc ]; then
        mv /tmp/dotfiles/.zshrc "$HOME/.zshrc"
    fi

    # Clean up
    rm -rf /tmp/unemployee.nvim /tmp/dotfiles

    # Change default shell to zsh for the current user (if not already)
    if [ -x "$(command -v zsh)" ]; then
        CURRENT_SHELL="$(getent passwd $USER | cut -d: -f7)"
        if [[ "$CURRENT_SHELL" != *zsh ]]; then
            chsh -s "$(command -v zsh)" || echo "Please run 'chsh -s $(command -v zsh)' manually if prompted."
        fi
    fi

    echo "Setup complete. Please log out and back in to use Zsh as your default shell."
