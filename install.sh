#!/bin/bash
set -e

# risk-claude installer for Linux/macOS
# Usage: bash install.sh [--install-dir ~/.claude] [--force]

REPO="qingchengliu/risk-claude"
INSTALL_DIR="${HOME}/.claude"
FORCE=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Expand ~ in INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"

echo "Installing risk-claude workflow to ${INSTALL_DIR}..."

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create install directory
mkdir -p "${INSTALL_DIR}"

# Function to copy directory
copy_dir() {
    local src="$1"
    local dst="$2"

    if [[ -d "${SCRIPT_DIR}/${src}" ]]; then
        if [[ -d "${dst}" ]] && [[ $FORCE -eq 0 ]]; then
            echo "Merging ${src}..."
            cp -rn "${SCRIPT_DIR}/${src}/"* "${dst}/" 2>/dev/null || true
        else
            echo "Copying ${src}..."
            mkdir -p "${dst}"
            cp -r "${SCRIPT_DIR}/${src}/"* "${dst}/"
        fi
    fi
}

# Install components
copy_dir "commands" "${INSTALL_DIR}/commands"
copy_dir "agents" "${INSTALL_DIR}/agents"
copy_dir "skills" "${INSTALL_DIR}/skills"

# Download codeagent-wrapper from GitHub releases
echo ""
echo "Downloading codeagent-wrapper..."

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Normalize architecture names
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Build download URL
VERSION="latest"
BINARY_NAME="codeagent-wrapper-${OS}-${ARCH}"
URL="https://github.com/${REPO}/releases/${VERSION}/download/${BINARY_NAME}"

echo "Downloading from ${URL}..."
if ! curl -fsSL "$URL" -o /tmp/codeagent-wrapper; then
    echo "WARNING: Failed to download codeagent-wrapper, skipping..."
else
    mkdir -p "$HOME/bin"
    mv /tmp/codeagent-wrapper "$HOME/bin/codeagent-wrapper"
    chmod +x "$HOME/bin/codeagent-wrapper"

    if "$HOME/bin/codeagent-wrapper" --version >/dev/null 2>&1; then
        echo "codeagent-wrapper installed successfully to ~/bin/codeagent-wrapper"
    else
        echo "WARNING: codeagent-wrapper installation verification failed"
    fi

    # Check if ~/bin is in PATH and add if not
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo ""
        echo "Adding ~/bin to PATH..."

        # Detect shell and config file
        SHELL_NAME=$(basename "$SHELL")
        case "$SHELL_NAME" in
            zsh)
                RC_FILE="$HOME/.zshrc"
                ;;
            bash)
                if [[ -f "$HOME/.bash_profile" ]]; then
                    RC_FILE="$HOME/.bash_profile"
                else
                    RC_FILE="$HOME/.bashrc"
                fi
                ;;
            *)
                RC_FILE="$HOME/.profile"
                ;;
        esac

        # Add to shell config if not already present
        if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$RC_FILE" 2>/dev/null; then
            echo '' >> "$RC_FILE"
            echo '# Added by risk-claude installer' >> "$RC_FILE"
            echo 'export PATH="$HOME/bin:$PATH"' >> "$RC_FILE"
            echo "Added PATH to $RC_FILE"
            echo "Please run: source $RC_FILE"
        else
            echo "PATH entry already exists in $RC_FILE"
        fi
    fi
fi

echo ""
echo "Installation completed successfully!"
echo "Installed to: ${INSTALL_DIR}"
echo ""
echo "Components installed:"
[[ -d "${INSTALL_DIR}/commands" ]] && echo "  - commands/"
[[ -d "${INSTALL_DIR}/agents" ]] && echo "  - agents/"
[[ -d "${INSTALL_DIR}/skills" ]] && echo "  - skills/"
[[ -f "$HOME/bin/codeagent-wrapper" ]] && echo "  - ~/bin/codeagent-wrapper"

# Install global npm packages
echo ""
echo "Installing global npm packages..."
npm install -g @openai/codex || echo "WARNING: Failed to install @openai/codex"
npm install -g @anthropic-ai/claude-code || echo "WARNING: Failed to install @anthropic-ai/claude-code"
echo "Global npm packages installation completed."
