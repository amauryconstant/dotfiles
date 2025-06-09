# Product Context: Chezmoi Dotfiles Management System

## Why This Project Exists

This dotfiles management system exists to solve the common problem of maintaining consistent development environments across multiple machines and operating systems. It addresses several key challenges:

1. **Configuration Drift**: Without a systematic approach, configurations across different machines tend to drift apart over time, leading to inconsistent behavior and "works on my machine" problems.

2. **Distribution Lock-in**: Many dotfiles solutions are tied to specific Linux distributions, making it difficult to switch between distributions or maintain a mixed environment.

3. **Security Concerns**: Dotfiles often contain sensitive information like API keys and credentials, which need to be securely managed when stored in version control.

4. **Complex Dependencies**: Modern development environments have complex dependencies and configurations that need to be consistently installed and maintained.

5. **Customization Needs**: Different machines may require slight variations in configuration based on their role (e.g., work vs. personal, desktop vs. laptop).

## Problems It Solves

### 1. Cross-Distribution Configuration Management

The system provides a unified approach to configuration management that works across multiple Linux distributions. This allows users to:
- Switch between distributions without losing their preferred environment
- Maintain a consistent experience across different machines
- Leverage distribution-specific features when available

### 2. Secure Credential Management

Using age encryption, the system securely manages sensitive information:
- SSH keys and configurations
- API tokens and credentials
- Personal configuration data
- Private server information

### 3. Sophisticated Package Management

The system implements a multi-strategy approach to package management:
- Prioritizes official repositories for stability
- Falls back to alternative sources when needed
- Handles distribution-specific package naming and availability
- Optimizes installation methods based on package type

### 4. Development Environment Consistency

Ensures consistent development tools and configurations:
- VSCode extensions and settings
- Shell configurations and utilities
- Programming languages and frameworks
- AI tools and models

### 5. Templated Configurations

Uses Go templates to customize configurations based on:
- Machine type (desktop vs. laptop)
- Operating system and distribution
- User preferences and identities
- Available hardware (e.g., NVIDIA GPUs)

## How It Should Work

### User Experience Goals

1. **Seamless Adoption**: A new machine should be fully configured with a single command
2. **Transparent Operation**: Users should understand what changes are being made
3. **Graceful Degradation**: When features aren't available on a platform, provide alternatives
4. **Safe Updates**: Configuration updates should be previewed before application
5. **Easy Customization**: Simple mechanisms to override defaults for specific machines

### Core Workflows

#### Initial Setup

1. Clone the repository
2. Run `chezmoi init`
3. Answer a few questions about the machine
4. Run `chezmoi apply`
5. System automatically configures itself based on the detected distribution

#### Updates and Maintenance

1. Run `chezmoi update` to pull latest changes
2. System automatically detects what needs updating
3. Preview changes with `chezmoi diff`
4. Apply updates with `chezmoi apply`
5. Handle any merge conflicts if local changes exist

#### Adding New Configurations

1. Make changes locally to configuration files
2. Add to chezmoi with `chezmoi add`
3. For sensitive data, use `chezmoi add --encrypt`
4. Commit and push changes
5. Other machines receive updates on next `chezmoi update`

### Integration Points

1. **Package Managers**: Integrates with pacman, apt, dnf, and others
2. **Shell Environment**: Configures zsh, bash, and related tools
3. **Development Tools**: Sets up VSCode, git, and language-specific tools
4. **AI Tools**: Configures Ollama and related AI development tools
5. **System Services**: Manages systemd services and other system components

## Key Differentiators

What makes this dotfiles management system unique:

1. **Cross-Distribution Focus**: Unlike many dotfiles solutions that target a single distribution, this system is designed from the ground up for cross-distribution compatibility.

2. **Sophisticated Package Strategies**: The multi-strategy approach to package management is more robust than simple package lists.

3. **Security-First Design**: Encryption is integrated at the core, not as an afterthought.

4. **Template-Driven**: Extensive use of templates allows for highly customized configurations while maintaining a single source of truth.

5. **Quality Standards**: Rigorous quality standards ensure scripts are reliable, well-documented, and maintainable.
