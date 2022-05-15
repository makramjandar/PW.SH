New-Module -name PwshLib -scriptblock {
  Function Get-AzureRepoContent {
    param( 
      [Parameter(Mandatory = $true)] [string] $GitFilePath,
      [Parameter(Mandatory = $true)] [string] $RepoName,
      [Parameter(Mandatory = $false)] [string] $OutFilePath,
      [Parameter(Mandatory = $false)] [string] $Token = $(System.AccessToken),
      [Parameter(Mandatory = $false)] [string] $OrgUrl = $(System.CollectionUri),
      [Parameter(Mandatory = $false)] [string] $TeamProject = $(System.TeamProject),
      [Parameter(Mandatory = $false)] [string] $Identifier = 'main',
      [Parameter(Mandatory = $false)] [string] $ApiVersion = '6.1-preview.1',
      [Parameter(Mandatory = $false)] [string] $User = ''
    )

    begin {
      Write-Output $(System.AccessToken)
      Write-Output "---------------------------------------------------"
      if ([String]::IsNullOrEmpty($Token)) {
        Write-Error "you must either pass the -token parameter"
        Write-Error "or use the BUILD_TOKEN environment variable"
        exit 1
      }

      if ([string]::IsNullOrEmpty($TeamProject)) {
        Write-Error "you must either pass the -teampProject parameter"
        Write-Error "or use the SYSTEM_TeamProject environment variable"
        exit 1
      }

      if ([string]::IsNullOrEmpty($OrgUrl)) {
        Write-Error "you must either pass the -OrgUrl parameter"
        Write-Error "or use the SYSTEM_COLLECTIONURI environment variable"
        exit 1
      }
      
      $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $User, $Token)))
      $header = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    }
    
     process {
      try {
        $items = "$OrgUrl/$TeamProject/_apis/git/repositories/$repoName/items"
        $path = "scopePath=$GitFilePath"
        $dwl = "download=true"
        $identifier = "versionDescriptor.version=$Identifier"
        $api = "api-version=$ApiVersion"
        $uriGetFile = $items + "?" + $path + "&" + $dwl + "&" + $identifier + "&" + $api
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
