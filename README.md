# Dotfiles Repository for HPC and GitHub Codespaces

This repository provides a comprehensive setup for configuring development environments both on High-Performance Computing (HPC) clusters and GitHub Codespaces. It includes essential scripts and configurations that streamline your workflow, from setting up your environment to updating your dotfiles.

## TL;DR

- **HPC Users**: Clone the repo and run `install-hpc.sh` to set up your environment.
- **Codespaces Users**: Use this repository as your dotfiles repository in your Codespaces settings.
- **Update Dotfiles**: Use `hpc-dotfiles-update` on HPC to keep your setup current.
- **Explore Commands**: Use the `-h` option with most scripts to see detailed help.

## Table of Contents

1. [Summary](#summary)
2. [Setup on HPC](#setup-on-hpc)
3. [Update Dotfiles on HPC](#update-dotfiles-on-hpc)
4. [Usage on GitHub Codespaces](#usage-on-github-codespaces)
5. [Detailed Script Overview](#detailed-script-overview)
    - [Apptainer Scripts](#apptainer-scripts)
    - [Slurm Scripts](#slurm-scripts)
    - [Utility Scripts](#utility-scripts)
6. [Dotfiles Overview](#dotfiles-overview)
7. [Additional Resources](#additional-resources)

---

## Summary

This repository contains scripts and configurations to enhance your development environment on both HPC clusters and GitHub Codespaces. The scripts automate common tasks such as container management with Apptainer, job submission with Slurm, and environment setup.

## Setup on HPC

To set up your environment on an HPC cluster:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/YourUsername/dotfiles.git ~/dotfiles
   ```
2. **Run the Installation Script**:
   ```bash
   bash ~/dotfiles/install-hpc.sh
   ```
   This script will:
   - Copy all necessary scripts to your `~/.local/bin` directory.
   - Configure your environment by sourcing scripts in `.bashrc.d`.
   - Optionally copy hidden configuration files if the `-c` flag is set.

3. **Copy Hidden Files** (optional):
   To copy hidden configuration files, re-run the installation script with the `-c` flag:
   ```bash
   bash ~/dotfiles/install-hpc.sh -c
   ```

## Update Dotfiles on HPC

To update your dotfiles on the HPC, run:

```bash
hpc-dotfiles-update
```

This will pull the latest changes from the repository and re-run the setup script.

## Usage on GitHub Codespaces

To use this dotfiles repository in GitHub Codespaces:

1. **Set the Repository as Your Dotfiles Repo**:
   - Go to your GitHub account settings.
   - Under "Codespaces", set this repository as your dotfiles repository.

2. **Customize Your Environment**:
   The `install.sh` script will automatically run in your Codespaces environment, setting up your development environment.

## Detailed Script Overview

### Apptainer Scripts

- **`apptainer-exists`**: Checks if a specified Apptainer Image File (SIF) exists.
- **`apptainer-pull`**: Pulls an Apptainer image from the GitHub Container Registry and saves it locally.
- **`apptainer-run`**: Runs a command inside an Apptainer container.
- **`apptainer-run-rscript`**: Runs an R script inside an Apptainer container.

### Slurm Scripts

- **`slurm-sintx`**: Submits a job to Slurm with a specified number of tasks (default is 2).
- **`slurm-squeue`**: Displays the Slurm queue for the current user.

### Utility Scripts

- **`hpc-dotfiles-update`**: Updates the dotfiles repository on the HPC and re-runs the setup.
- **`install-jetbrains-font`**: Installs the JetBrains Mono font and configures it for use in VS Code.

## Dotfiles Overview

### `.Renviron`

- Contains environment variables for R projects.

### `.gitconfig`

- Configures Git to handle line endings with `autocrlf=input`.

### `.radian_profile`

- Configures the Radian REPL, disabling auto-matching of parentheses.

### `.lintr`

- Configures `lintr` to disable specific linters for R code.

## Additional Resources

- [Dotfiles Guide](https://dotfiles.github.io/)
- [Apptainer Documentation](https://apptainer.org/docs/)
- [Slurm User Guide](https://slurm.schedmd.com/documentation.html)

