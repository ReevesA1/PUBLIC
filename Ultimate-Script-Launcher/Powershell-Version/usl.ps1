#!Debug
#Set-PSDebug -Trace 1


# Choose a repo
$repo_url = gh repo list ReevesA1 --json url --jq '.[] | "\(.url)"' | gum choose --height 20

# Extract the owner and repo from the URL
$owner, $repo = $repo_url.Split('/')[3..4]

# Function to choose a file or directory within the repository
function choose_file_or_dir {
  param($path)
  $items = gh api repos/$owner/$repo/contents/$path | ConvertFrom-Json | ForEach-Object { $_.path }

  # If there are no items, return the path
  if (!$items) {
    Clear-Host
    return $path
  }
  else {
    Clear-Host
    # If there are items, choose one and recurse
    $new_path = $items | gum choose --height 20
    choose_file_or_dir $new_path
  }
}

# Choose a file or directory within the repository
Clear-Host
$file_path = gh api repos/$owner/$repo/contents | ConvertFrom-Json | ForEach-Object { $_.path } | gum choose --height 20

# Recursively choose a file if a directory is chosen
while ((gh api repos/$owner/$repo/contents/$file_path | ConvertFrom-Json | ForEach-Object { $_.type }) -eq 'dir') {
  $file_path = choose_file_or_dir $file_path
}

# Decode and execute the chosen script
$file_content = gh api repos/$owner/$repo/contents/$file_path | ConvertFrom-Json | ForEach-Object { $_.content } | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Check if the file is a .md file
if ($file_path -like "*.md") {
  write-output $file_content | glow
}
elseif ($file_path -like "*.ps1") {
  try {
    Invoke-Expression -Command $file_content
  }
  catch {
    Write-Host "An error occurred while executing the PowerShell script: $_" -ForegroundColor Red
  }
}
elseif ($file_path -like "*.sh") {
  Clear-Host
  Write-Host "Bash scripts do not work on Windows" -ForegroundColor Red
}
else {
  try {
    Invoke-Expression -Command $file_content
  }
  catch {
    Write-Host "An error occurred while executing the script: $_" -ForegroundColor Red
  }
}
