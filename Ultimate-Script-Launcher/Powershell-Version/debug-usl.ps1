# Choose a repo
$repo_url = gh repo list ReevesA1 --json url --jq '.[] | "\(.url)"' | gum choose --height 20
Write-Host "Repo URL: $repo_url"

# Extract the owner and repo from the URL
$owner, $repo = $repo_url.Split('/')[3..4]
Write-Host "Owner: $owner"
Write-Host "Repo: $repo"

# Function to choose a file or directory within the repository
function choose_file_or_dir {
  param($path)
  $items = gh api repos/$owner/$repo/contents/$path | ConvertFrom-Json | ForEach-Object { $_.path }
  Write-Host "Items: $items"

  # If there are no items, return the path
  if (!$items) {
    Clear-Host
    return $path
  }
  else {
    Clear-Host
    # If there are items, choose one and recurse
    $new_path = $items | gum choose --height 20
    Write-Host "New Path: $new_path"
    choose_file_or_dir $new_path
  }
}

# Choose a file or directory within the repository
Clear-Host
$file_path = gh api repos/$owner/$repo/contents | ConvertFrom-Json | ForEach-Object { $_.path } | gum choose --height 20
Write-Host "File Path: $file_path"

# Recursively choose a file if a directory is chosen
while ((gh api repos/$owner/$repo/contents/$file_path | ConvertFrom-Json | ForEach-Object { $_.type }) -eq 'dir') {
  $file_path = choose_file_or_dir $file_path
  Write-Host "File Path after choosing file or dir: $file_path"
}

# Decode and execute the chosen script
$file_content = gh api repos/$owner/$repo/contents/$file_path | ConvertFrom-Json | ForEach-Object { $_.content } | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host "File Content: $file_content"
