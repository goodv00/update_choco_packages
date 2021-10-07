#Invoke-WebRequest -Uri "https://biodiversityinformatics.amnh.org/open_source/dotdotgoose/index.html" -OutFile "DDG.html"
#Invoke-WebRequest -Uri "https://biodiversityinformatics.amnh.org/open_source/dotdotgoose/index.html" -OutFile "release.html"
#$Source = Get-Content -path DDG.html
#$text = Get-Content -path release.html
#$Source -match '<ul class="local-list"> <li>[0-9]{4}-[0-9]{2}-[0-9]{2} - version ([0-9]+(\.[0-9]+)+) '
#$tag = $matches[1]

$tag = "1.5.2"

#$pattern = '<ul class="local-list"> <li>(.*?)</li> </ul> </li>'
#$result = [regex]::match($text, $pattern).Groups[1].Value

#$release = $result -replace ' <ul class="local-list"> <li>', "`n* "
#$release = $release -replace '</li> <li>', "`n* "
#$release = $release -replace '(Enhancement)', '**Enhancement**'
#$release = $release -replace '(Bug Fix)', '**Bug Fix**'
#$release = $release -replace '(Bug Fixed)', '**Bug Fixed**'
#$release = -join($release, "`n`n**Full changelog:** [https://biodiversityinformatics.amnh.org/open_source/dotdotgoose/](https://biodiversityinformatics.amnh.org/open_source/dotdotgoose/) ");


$file = "./dotdotgoose/dotdotgoose.nuspec"
$xml = New-Object XML
$xml.Load($file)
$xml.package.metadata.version = $tag
$xml.package.metadata.releaseNotes = " https://biodiversityinformatics.amnh.org/open_source/dotdotgoose/ " # $release
$xml.Save($file)

Invoke-WebRequest -Uri "https://adri-server.ddns.net/CDN/A-D-R-I/dotdotgoose-win.zip" -OutFile "dotdotgoose.zip"

Expand-Archive dotdotgoose.zip -DestinationPath .\dotdotgoose\tools\ -Force

Remove-Item dotdotgoose.zip

choco pack ./dotdotgoose/dotdotgoose.nuspec --outputdirectory .\dotdotgoose

If ($LastExitCode -eq 0) {
	choco push ./dotdotgoose/dotdotgoose.$tag.nupkg --source https://push.chocolatey.org/
} else {
 'Error - Exit code: $LastExitCode'
}

#git and create tag
git config --local user.email "a-d-r-i@outlook.fr"
git config --local user.name "A-d-r-i"
git add .
git commit -m "[Bot] Update files - dotdotgoose" --allow-empty
git tag -a dotdotgoose-v$tag -m "DotDotGoose - version $tag"
git push -f && git push --tags

#create release
Install-Module -Name New-GitHubRelease -Force
Import-Module -Name New-GitHubRelease
$newGitHubReleaseParameters = @{
GitHubUsername = "A-d-r-i"
GitHubRepositoryName = "update_choco_package"
GitHubAccessToken = "$env:ACTIONS_TOKEN"
ReleaseName = "DotDotGoose v$tag"
TagName = "dotdotgoose-v$tag"
ReleaseNotes = "$release"
AssetFilePaths = ".\dotdotgoose\dotdotgoose.$tag.nupkg"
IsPreRelease = $false
IsDraft = $false
}
$resultrelease = New-GitHubRelease @newGitHubReleaseParameters

#post tweet
$twitter = (Select-String -Path config.txt -Pattern "twitter=(.*)").Matches.Groups[1].Value
if ( $twitter -eq "y" )
{
Install-Module PSTwitterAPI -Force
Import-Module PSTwitterAPI
$OAuthSettings = @{
ApiKey = "$env:PST_KEY"
ApiSecret = "$env:PST_SECRET"
AccessToken = "$env:PST_TOKEN"
AccessTokenSecret = "$env:PST_TOKEN_SECRET"
}
Set-TwitterOAuthSettings @OAuthSettings
Send-TwitterStatuses_Update -status "DotDotGoose v$tag push now on @chocolateynuget! 
Link: https://community.chocolatey.org/packages/dotdotgoose/$tag
#dotdotgoose #release #opensource
"
}