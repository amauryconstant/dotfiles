# Project Brief: Chezmoi Dotfiles Management System

## Overview

This project is a sophisticated dotfiles management system built using [chezmoi](https://www.chezmoi.io/), designed to maintain consistent configurations across multiple machines and Linux distributions. It uses templates, encryption, and cross-platform scripts to create a portable, secure, and adaptable environment.

## Core Requirements

1. **Cross-Distribution Compatibility**: Support multiple Linux distributions beyond Arch Linux, including Debian/Ubuntu and Fedora.
2. **Secure Configuration Management**: Use age encryption for sensitive data like API keys and SSH credentials.
3. **Templated Configuration**: Leverage Go templates to customize configurations based on machine type, OS, and user preferences.
4. **Package Management**: Implement sophisticated package installation strategies across different distribution package managers.
5. **Development Environment**: Configure consistent development tools, including VSCode, AI tools, and shell environments.
6. **Quality Assurance**: Maintain high standards for script quality, error handling, and documentation.

## Goals

1. **Portability**: Ensure configurations work seamlessly across different machines and Linux distributions.
2. **Maintainability**: Create well-documented, modular scripts that are easy to understand and modify.
3. **Security**: Protect sensitive information through proper encryption and access controls.
4. **Efficiency**: Optimize package installation and update processes for speed and reliability.
5. **Adaptability**: Design the system to easily accommodate new distributions and changing requirements.

## Current Focus

The current focus is on adapting the existing Arch-specific scripts to work on other Linux distributions, particularly Debian/Ubuntu and Fedora. This involves:

1. Restructuring package management to support different package managers (apt, dnf, etc.)
2. Creating distribution-specific installation strategies
3. Implementing proper distribution detection and conditional logic
4. Testing cross-distribution compatibility

## Key Components

1. **Chezmoi Configuration**: Core settings and templates in `.chezmoi.yaml.tmpl`
2. **Data Files**: Configuration data in `.chezmoidata/` directory
3. **Scripts**: Lifecycle scripts in `.chezmoiscripts/` directory
4. **Templates**: Configuration templates with `.tmpl` extension
5. **Encrypted Files**: Sensitive data with `.age` extension
6. **Modify Scripts**: Special handlers for mixed state/settings files

## Success Criteria

1. All scripts work correctly on Arch, Debian/Ubuntu, and Fedora distributions
2. Package installation strategies are properly adapted for each distribution
3. Configuration files are correctly generated across all supported platforms
4. Security protocols are maintained across all distributions
5. Documentation clearly explains cross-distribution support and limitations
