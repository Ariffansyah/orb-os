setup-dev-env:
    # Ensure $HOME exists (should be true for normal users, but safe for root in containers)
    mkdir -p "$HOME"

    # Install Oh My Zsh if not already present
    export ZSH="$HOME/.oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install Antigen for Zsh
    curl -sSL https://raw.githubusercontent.com/BillyAddlers/rezsh/refs/heads/master/check_antigen.sh | bash

    rm -rf /tmp/unemployee.nvim
    git clone --depth=1 https://github.com/Ariffansyah/unemployee.nvim.git /tmp/unemployee.nvim
    mkdir -p "$HOME/.config"
    rm -rf "$HOME/.config/nvim"
    mv /tmp/unemployee.nvim "$HOME/.config/nvim"

    # Clone dotfiles
    rm -rf /tmp/dotfiles
    git clone --depth=1 https://github.com/Ariffansyah/dotfiles.git /tmp/dotfiles

    rm -rf "$HOME/.config/tmux"
    mv /tmp/dotfiles/.config/tmux "$HOME/.config/tmux"

    rm -rf "$HOME/.config/ghostty"
    mv /tmp/dotfiles/.config/ghostty "$HOME/.config/ghostty"

    rm -f "$HOME/.config/starship.toml"
    mv /tmp/dotfiles/.config/starship.toml "$HOME/.config/starship.toml"

    # Move .zshrc
    mv /tmp/dotfiles/.zshrc "$HOME/.zshrc"

    # Clean up
    rm -rf /tmp/unemployee.nvim /tmp/dotfiles

    sudo usermod --shell /usr/bin/zsh ${USER}
    echo "Setup complete. Please log out and back in to use Zsh as your default shell."
