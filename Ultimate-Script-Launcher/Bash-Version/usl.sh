#!/usr/bin/env bash

#!#####################
#!       Gum Style   ##
#!#####################

gum style \
  --foreground 212 --border-foreground 255 --border double \
  --align center --width 50 --margin "1 2" --padding "2 4" \
  'ULTIMATE SCRIPT LAUNCHER'

#!################################
#!     Install Dependencies     ##
#!################################

check_and_install() {
  local package=$1
  if ! command -v $package &>/dev/null; then
    echo -e "\033[0;32mInstalling $package...\033[0m"
    sudo apt install $package
  else
    echo -e "\033[0;32m$package is installed\033[0m"
  fi
}

# Check if Github aka gh, git, and jq are installed
check_and_install "gh"
check_and_install "git"
check_and_install "jq"

#!#############################
#!       Install Gum         ##
#!#############################
#* Check if gum is installed
if ! command -v gum &>/dev/null; then
  echo -e "\033[0;32mInstalling git...\033[0m"
  sudo mkdir -p /etc/apt/keyrings
  sudo curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  sudo echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
  sudo apt update && sudo apt install gum
else
  echo -e "\033[0;32mgum is installed\033[0m"
fi

#!##################################
#!       Login to GH              ##
#!##################################

#variable
auth_status=$(gh auth status 2>&1)

if echo "$auth_status" | grep -q "Logged in to"; then
  echo -e "\033[0;32mYou are already logged in to GitHub.\033[0m"
else
  echo -e "\033[1;33mYou are not logged in to GitHub. Let's log you in.\033[0m"
  gh auth login
fi

#* Set Git credential timeout to 24 hours (Not sure if I even need this at all?)
#  git config --global credential.helper 'cache --timeout=86400'
echo -e "\033[0;32mGit credential timeout is now set to 24 hours.\033[0m"

#*Dependenci and Distro checks above
#*########################################################################################################################
#*########################################################################################################################
#*########################################################################################################################
#*                                            TESTING CUT OFF                                                           ##
#*########################################################################################################################
#*########################################################################################################################
#*########################################################################################################################
#* Meat and potatoes below

#!#############################
#!       Choose a repo       ##
#!#############################
#* abstract Username method
#echo -e "\033[32mPlease enter your Github Username:\033[0m"
#read GIT_USERNAME
#repo_url=$(gh repo list $GIT_USERNAME --json url --jq '.[] | "\(.url)"' | gum choose --height 20)
#*Plain Text Usernam Method
repo_url=$(gh repo list ReevesA1 --json url --jq '.[] | "\(.url)"' | gum choose --height 20)

#* I do not have to abstact username here since I will call the script with the abstraction in the Notion Public Homepage with this next line
#todo - this is the one liner
#echo -e "\033[32mPlease enter your Github Username:\033[0m"; read GIT_USERNAME; gh api repos/$GIT_USERNAME/PUBLIC/contents/Ultimate-Script-Launcher/Bash-Version/usl.sh | jq -r '.content' | base64 --decode | bash


# Extract the owner and repo from the URL
owner=$(echo $repo_url | cut -d'/' -f4)
repo=$(echo $repo_url | cut -d'/' -f5)

# Function to choose a file or directory within the repository
choose_file_or_dir() {
  local path=$1
  local items=$(gh api repos/$owner/$repo/contents/$path | jq -r '.[] | "\(.path)"' 2>/dev/null)

  # If there are no items, return the path
  if [ -z "$items" ]; then
    echo $path
  else
    # If there are items, choose one and recurse
    local new_path=$(echo "$items" | gum choose --height 20)
    choose_file_or_dir $new_path
  fi
}

#!###########################################################
#!       Choose a file or directory within the repository  ##
#!###########################################################
file_path=$(gh api repos/$owner/$repo/contents | jq -r '.[] | "\(.path)"' | gum choose --height 20)

# Recursively choose a file if a directory is chosen
file_path=$(choose_file_or_dir $file_path)

#!#####################################################
#!       Decode and execute the chosen script        ##
#!#####################################################
file_content=$(gh api repos/$owner/$repo/contents/$file_path | jq -r '.content' | base64 --decode)

# Check if the file is a .md file
if [[ $file_path == *.md ]]; then
  echo "$file_content" | glow
else
  echo "$file_content" | bash
fi
