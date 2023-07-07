# github token
export GITHUB_PAT=${GITHUB_PAT:-$GH_TOKEN}
export GITHUB_TOKEN=${GITHUB_PAT:-$GH_TOKEN}

# set R_LIBS
export R_LIBS="/home/$USER/.local/lib/R"
mkdir -p $R_LIBS

