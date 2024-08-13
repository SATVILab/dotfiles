# Dotfiles Repository for HPC and GitHub Codespaces

This repository provides a comprehensive setup for configuring development environments both on High-Performance Computing (HPC) clusters and GitHub Codespaces. It includes essential scripts and configurations that streamline your workflow, from setting up your environment to updating your dotfiles.

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

For a quick start:
- **HPC Users**: Clone the repo and run `dotfiles/install-hpc.sh`.
- **Codespaces Users**: Set this repository as your dotfiles repository in your Codespaces settings.

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
   - Run the main `install.sh` script to configure your environment.
   - Optionally copy hidden configuration files (such as `.Renviron`, `.lintr`, and `.radian_profile`) if the `-c` flag is set.

3. **Copy Hidden Files** (optional):
   To copy hidden configuration files, re-run the installation script with the `-c` flag:
   ```bash
   bash ~/dotfiles/install-hpc.sh -c
   ```

## Update Dotfiles on HPC

To update your dotfiles on the HPC, simply run the `dotfiles-update` script:

```bash
dotfiles-update
```

This script will:
- Pull the latest changes from the dotfiles repository.
- Run the `install-hpc.sh` script to apply updates.

## Usage on GitHub Codespaces

To use this dotfiles repository in GitHub Codespaces:

1. **Set the Repository as Your Dotfiles Repo**:
   - Go to your GitHub account settings.
   - Under "Codespaces", set this repository as your dotfiles repository.

2. **Customize Your Environment**:
   The `install.sh` script will automatically run in your Codespaces environment, setting up your development environment based on the configurations and scripts in this repository.

## Detailed Script Overview

### Apptainer Scripts

**`apptainer-exists`**

- **Description**: Checks if a specified Apptainer Image File (SIF) exists in the specified or default directories.
- **Usage**:
  ```bash
  apptainer-exists -s mycontainer.sif
  ```
  If no SIF file is specified, it defaults to the current directory name.

**`apptainer-pull`**

- **Description**: Pulls an Apptainer image from the GitHub Container Registry and saves it locally.
- **Usage**:
  ```bash
  apptainer-pull -u YourGitHubUser -r YourRepo -i image_name
  ```
  This script supports several optional flags for customization, such as `-f` for force, `-t` for tag, and `-b` for base directory.

**`apptainer-run`**

- **Description**: Runs a command inside an Apptainer container.
- **Usage**:
  ```bash
  apptainer-run -s mycontainer.sif echo "Hello, World!"
  ```
  If no command is specified, it opens a shell inside the container.

**`apptainer-run-rscript`**

- **Description**: Runs an R script inside an Apptainer container.
- **Usage**:
  ```bash
  apptainer-run-rscript -s mycontainer.sif "print('Hello, World!')"
  ```
  The command passed as an argument will be executed as an R script.

### Slurm Scripts

**`slurm-sintx`**

- **Description**: Submits a job to the Slurm workload manager with a default of 2 tasks.
- **Usage**:
  ```bash
  slurm-sintx 4
  ```
  This command submits a job with 4 tasks. If no number is specified, it defaults to 2 tasks.

**`slurm-squeue`**

- **Description**: Displays the Slurm queue for the current user.
- **Usage**:
  ```bash
  slurm-squeue
  ```
  This command runs `squeue -u $USER` to show your queued jobs.

### Utility Scripts

**`dotfiles-update`**

- **Description**: Updates the dotfiles repository on the HPC and re-runs the setup.
- **Usage**:
  ```bash
  dotfiles-update
  ```
  This will pull the latest changes from the dotfiles repository and re-run the `install-hpc.sh` script.

**`install-jetbrains-font`**

- **Description**: Installs the JetBrains Mono font on your system, and configures it for use in VS Code.
- **Usage**:
  ```bash
  install-jetbrains-font
  ```
  This script downloads, installs, and configures the JetBrains Mono font.

## Dotfiles Overview

### `.Renviron`

- **Purpose**: Contains environment variables for R projects, including GitHub username and project-specific variables.

### `.gitconfig`

- **Purpose**: Configures Git to handle line endings correctly with `autocrlf=input`.

### `.radian_profile`

- **Purpose**: Configures the Radian REPL, specifically to disable auto-matching of parentheses.

### `.lintr`

- **Purpose**: Configures `lintr` to disable specific linters for R code, such as object name and length checks.

## Additional Resources

For more information on using dotfiles, Apptainer, or Slurm, you can check out these resources:

- [Dotfiles Guide](https://dotfiles.github.io/)
- [Apptainer Documentation](https://apptainer.org/docs/)
- [Slurm User Guide](https://slurm.schedmd.com/documentation.html)