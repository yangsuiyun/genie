#!/bin/bash
# Install workflow validation tools
set -euo pipefail

echo "🔧 Installing workflow validation tools..."

# Install yamllint for YAML validation
if ! command -v yamllint &> /dev/null; then
    echo "Installing yamllint..."
    if command -v pip3 &> /dev/null; then
        pip3 install --user yamllint
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y yamllint
    elif command -v brew &> /dev/null; then
        brew install yamllint
    else
        echo "⚠️  Please install yamllint manually"
    fi
else
    echo "✅ yamllint already installed"
fi

# Install actionlint for GitHub Actions validation
if ! command -v actionlint &> /dev/null; then
    echo "Installing actionlint..."
    if command -v go &> /dev/null; then
        go install github.com/rhymond/actionlint/cmd/actionlint@latest
    else
        # Download binary directly
        curl -sSL https://github.com/rhymond/actionlint/releases/latest/download/actionlint_1.6.26_linux_amd64.tar.gz | tar xz -C /tmp
        sudo mv /tmp/actionlint /usr/local/bin/
    fi
else
    echo "✅ actionlint already installed"
fi

# Install GitHub CLI if not present
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    if command -v apt-get &> /dev/null; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install gh
    elif command -v brew &> /dev/null; then
        brew install gh
    else
        echo "⚠️  Please install GitHub CLI manually"
    fi
else
    echo "✅ GitHub CLI already installed"
fi

echo "✅ Workflow validation tools setup complete"