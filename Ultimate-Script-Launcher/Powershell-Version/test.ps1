function Explore-Repo {
  param($path)

  # URL encode the path
  $encodedPath = [System.Web.HttpUtility]::UrlEncode($path)

  # Fetch the contents of the path
  $contents = gh api repos/ReevesA1/RocketOS/contents/$encodedPath | ConvertFrom-Json

  # If the path is a directory, let the user select a file or subdirectory
  if (($contents | Measure-Object).Count -gt 1 -or $contents.type -eq "dir") {
      $selectedPath = $contents | ForEach-Object { $_.path } | gum choose --height 20

      # Recursively explore the selected path
      Explore-Repo -path $selectedPath
  } elseif ($path -like "*.ps1") {
      # If it's a PowerShell script, download and execute it
      $base64Content = gh api repos/ReevesA1/RocketOS/contents/$encodedPath --jq '.content'
      $decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64Content))
      Invoke-Expression -Command $decodedContent
  } else {
      Write-Output "The selected path is not a directory or a PowerShell script."
  }
}

# Start exploring from the root of the repository
Explore-Repo -path ""
