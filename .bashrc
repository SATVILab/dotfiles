# ------------
# General
# ------------
export EMAIL=rdxmig002@myuct.ac.za

# ------------
# R-specific
# ------------

# create shortcut to /scratch/rdxmig002
export SD=/scratch/rdxmig002
# load version of R you want
module load software/R-4.2.0
# tell R where your package library is
export R_LIBS=/scratch/rdxmig002/local/R/4.2:$R_LIBS
export R_LIBS_USER=/scratch/rdxmig002/local/R/4.2


# Ensure that R does not save the workspace
# after closing R or attempt to restore it
# after opening
alias R='R --no-save --no-restore'
alias r='radian'

# ------------
# R packages
# -------------

# nloptr
# --------------
export PKG_CONFIG_PATH=/opt/exp_soft/nlopt-2.7.1/lib64/pkgconfig:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=/opt/exp_soft/nlopt-2.7.1/lib64:$LD_LIBRARY_PATH

# ------------
# Git-specific
# ------------

# fix Git version
module load software/git-2.32

# ------------
# Python-specific
# ------------

# set Python version
module load python/miniconda3-py39


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/exp_soft/miniconda3-py39/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/exp_soft/miniconda3-py39/etc/profile.d/conda.sh" ]; then
        . "/opt/exp_soft/miniconda3-py39/etc/profile.d/conda.sh"
    else
        export PATH="/opt/exp_soft/miniconda3-py39/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<



