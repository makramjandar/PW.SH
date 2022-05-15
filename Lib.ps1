new-module -name PWSHLib -scriptblock {
  Function Get-AzureRepoContent {
    param( 
      [Parameter(Mandatory = $true)] [string] $GitFilePath,
      [Parameter(Mandatory = $true)] [string] $RepoName,
      [Parameter(Mandatory = $false)] [string] $OutFilePath,
      [Parameter(Mandatory = $false)] [string] $token,
      [Parameter(Mandatory = $false)] [string] $orgUrl,
      [Parameter(Mandatory = $false)] [string] $teamProject,
      [Parameter(Mandatory = $false)] [string] $apiVersion = '6.1-preview.1',
      [Parameter(Mandatory = $false)] [string] $User = ''
    )

    begin {
      if ([String]::IsNullOrEmpty($token)) {
        if ($(System.AccessToken) -eq $null) {
          Write-Error "you must either pass the -token parameter or use the BUILD_TOKEN environment variable"
          exit 1;
        }
        else {
          $token = $(System.AccessToken);
        }
      }
      if ([string]::IsNullOrEmpty($teamProject)) {
        if ($(System.TeamProject) -eq $null) {
          Write-Error "you must either pass the -teampProject parameter or use the SYSTEM_TEAMPROJECT environment variable"
          exit 1;
        }
        else {
          $teamProject = $(System.TeamProject)
        }
      }
      if ([string]::IsNullOrEmpty($orgUrl)) {
        if ($(System.CollectionUri) -eq $null) {
          Write-Error "you must either pass the -orgUrl parameter or use the SYSTEM_COLLECTIONURI environment variable"
          exit 1
        }
        else {
          $teamProject = $(System.CollectionUri)
        }
      }
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $User, $token)))
      $header = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    }

    process {
      try {
        
        $uriGetFile = "$orgUrl/$teamProject/_apis/git/repositories/$repoName/items?scopePath=$GitFilePath&download=true&api-version=$apiVersion"
        Write-Host "Url:" $uriGetFile
        $filecontent = Invoke-RestMethod -ContentType "application/json" -UseBasicParsing -Headers $header -Uri $uriGetFile
        

        if ([String]::IsNullOrEmpty($OutFilePath)) {
          Write-Output $filecontent
          exit 0 
        }
        Write-Host "Download file" $GitFilePath "to" $OutFilePath
        $filecontent | Out-File -Encoding utf8 $OutFilePath
      }
      catch {
        Write-Error "Unable to get Azure repo content: $_"
      }
    }
  }
  
  export-modulemember -function 'Get-AzureRepoContent'
}
