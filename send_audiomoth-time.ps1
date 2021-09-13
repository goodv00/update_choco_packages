$tag = (Invoke-WebRequest "https://api.github.com/repos/OpenAcousticDevices/AudioMoth-Time-App/releases/latest" | ConvertFrom-Json)[0].name

$file = "./audiomoth-time/audiomoth-time.nuspec"
$xml = New-Object XML
$xml.Load($file)
$xml.package.metadata.version = $tag
$xml.Save($file)

$Version = ([xml](Get-Content ./audiomoth-time/audiomoth-time.nuspec)).package.metadata.version

Invoke-WebRequest -Uri "https://github.com/OpenAcousticDevices/AudioMoth-Time-App/releases/download/$tag/AudioMothTimeAppSetup$tag.exe" -OutFile "./audiomoth-time/tools/AudioMothTimeAppSetup.exe"

choco pack ./audiomoth-time/audiomoth-time.nuspec --outputdirectory .\audiomoth-time

If ($LastExitCode -eq 0) {
	choco push ./audiomoth-time/audiomoth-time.$tag.nupkg --source https://push.chocolatey.org/
} else {
 'Error'
}

Start-Sleep -Seconds 10