#!/usr/bin/env bash

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
echo -e "\033[32mPlease enter your Github Username:\033[0m"
read GIT_USERNAME
repo_url=$(gh repo list $GIT_USERNAME --json url --jq '.[] | "\(.url)"' | gum choose --height 20)

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
gh api repos/$owner/$repo/contents/$file_path | jq -r '.content' | base64 --decode | bash
