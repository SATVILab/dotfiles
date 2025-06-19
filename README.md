# Dotfiles: Unified Shell Environment for HPC, Linux, WSL, Codespaces, & Mac

This repo provides an installable, cross-platform dotfiles environment supporting:

* **HPC clusters** (Bash)
* **Linux** (Bash)
* **WSL** (Bash)
* **Devcontainers & GitHub Codespaces** (auto-installs)
* **macOS** (Zsh/Bash; support untested)

Its primary purpose is to configure Git and/or HuggingFace authentication and configure R within VS Code. 

---

## Quick Start

### GitHub Codespaces

Set this repository as your dotfiles in the Codespaces settings. It will automatically install when you create a new codespace.

### Local Installation

Clone and install for your environment:

```bash
git clone https://github.com/YourUsername/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install-env.sh <env>
```

Where `<env>` is one of:

* `hpc` (for clusters)
* `linux` (for normal Linux)
* `wsl` (for Windows Subsystem for Linux)
* `dev` (for generic devcontainer)
* `codespace` (for GitHub Codespaces; installs automatically if set as dotfiles repo)
* `mac` (for Mac; untested)

---

## What Does This Setup Provide?

* **Utility script installation:**
  All repo scripts go to `~/.local/bin`, including:
  * **Apptainer and Slurm tools** for HPC/cluster users
  * **dotfiles-update** helper for keeping your setup current
* **R config:**
  Copies sensible `.Renviron`, `.lintr`, and `.radian_profile` defaults if using R/VS Code—also strips out HPC-specific R settings if not on cluster.
* **Authentication environment:**
  Prompts (when in interactive mode) to set up initial GitHub and HuggingFace authentication for use in scripts/RStudio/VS Code.
* **Git configuration:**
  Ensures email/username are set and normalises line endings for cross-platform safety.

---

## Updating Your Dotfiles

To update your setup after pulling changes:

```bash
cd ~/dotfiles
git pull
bash install-env.sh <env>
```

If in a GitHub codespace, you should rebuild the codespace (full rebuild not needed).

---

## Limitations

* Native Windows is not supported—use WSL.
* macOS support is present but untested.

---

## Questions or issues?

Feel free to open an issue on the GitHub repository or contact me directly (Miguel Rodo at miguel.rodo@uct.ac.za).

## Resources

* [Dotfiles Guide](https://dotfiles.github.io/)
* [Apptainer Docs](https://apptainer.org/docs/)
* [Slurm Docs](https://slurm.schedmd.com/documentation.html)
