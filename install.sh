#!/bin/bash

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup"

echo "Starting dotfiles installation..."

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Symlink dotfiles
FILES=(
  ".zshrc"
  ".oh-my-zsh"
  ".gitconfig"
  ".bashrc"
  ".ssh/config"
)

for file in "${FILES[@]}"; do
  TARGET="$HOME/$file"

  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    echo "Backing up $TARGET to $BACKUP_DIR"
    mv "$TARGET" "$BACKUP_DIR/"
  fi

  DOTFILE_SOURCE="$DOTFILES_DIR/$file"
  if [ -e "$DOTFILE_SOURCE" ]; then
    ln -s "$DOTFILE_SOURCE" "$TARGET"
    echo "Symlinked $DOTFILE_SOURCE → $TARGET"
  else
    echo "Skipping $file (not found in dotfiles repo)"
  fi
done

# Homebrew installation and update
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Updating Homebrew and upgrading installed packages..."
brew update && brew upgrade

# Install Homebrew packages
if [ -f "$DOTFILES_DIR/brew-packages.txt" ]; then
  echo "Installing Homebrew packages..."
  xargs brew install < "$DOTFILES_DIR/brew-packages.txt"
fi

# Install Cask apps
if [ -f "$DOTFILES_DIR/cask-apps.txt" ]; then
  echo "Installing Cask applications..."
  xargs brew install --cask < "$DOTFILES_DIR/cask-apps.txt"
fi

# Clean up outdated versions and cache
echo "Cleaning up old Homebrew versions..."
brew cleanup -s
rm -rf "$(brew --cache)"

# Install VS Code extensions
if [ -f "$DOTFILES_DIR/vscode-extensions.txt" ]; then
  echo "Installing VS Code extensions..."
  while read -r extension; do
    code --install-extension "$extension"
  done < "$DOTFILES_DIR/vscode-extensions.txt"
fi

# Authenticate GitHub CLI
echo "Authenticating GitHub CLI..."
gh auth login --web

# SSH Key Setup
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo "Generating SSH key..."
  ssh-keygen -t ed25519 -C "kristian.hellang@procore.com" -f "$SSH_KEY" -N ""
  eval "$(ssh-agent -s)"
  ssh-add "$SSH_KEY"

  echo "Adding SSH key to GitHub via GitHub CLI..."
  gh ssh-key add "$SSH_KEY.pub" --title "MacBook Setup $(date +'%Y-%m-%d')"

  echo "SSH key added to GitHub successfully!"
else
  echo "SSH key already exists."
fi

# Set Zsh as the default shell if installed
if command -v zsh &> /dev/null; then
  echo "Setting Zsh as the default shell..."
  chsh -s "$(which zsh)"
  # Install Oh My Zsh for better Zsh experience (optional)
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  echo "Default shell changed to Zsh. Restart your terminal or log out and log in for changes to take effect."
else
  echo "Zsh was not found. It may not have installed correctly."
fi

echo "MacBook setup complete!"
