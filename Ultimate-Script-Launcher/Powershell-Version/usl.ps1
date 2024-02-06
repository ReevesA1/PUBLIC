# Choose a repository
$repo_url = gh repo list ReevesA1 --json url --jq '.[] | "\(.url)"' | gum choose --height 20

# Extract the owner and repo from the URL
$owner, $repo = $repo_url.Split('/')[3..4]

function Explore_Repo {
  param($path)

  # URL encode the path
  $encodedPath = [System.Web.HttpUtility]::UrlEncode($path)

  # Fetch the contents of the path
  $contents = gh api repos/$owner/$repo/contents/$encodedPath | ConvertFrom-Json

  # If the path is a directory, let the user select a file or subdirectory
  if (($contents | Measure-Object).Count -gt 1 -or $contents.type -eq "dir") {
    $selectedPath = $contents | ForEach-Object { $_.path } | gum choose --height 20

    # Recursively explore the selected path
    Explore_Repo -path $selectedPath
  }
  elseif ($path -like "*.ps1") {
    # If it's a PowerShell script, download and execute it
    $base64Content = gh api repos/$owner/$repo/contents/$encodedPath --jq '.content'
    $decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64Content))
    Invoke-Expression -Command $decodedContent
  }
  else {
    Write-Output "The selected path is not a directory or a PowerShell script."
  }
}

# Start exploring from the root of the repository
Explore_Repo -path ""
