$version = 2.5
Write-Host "Loading Helper Functions" -ForegroundColor Cyan;
$currentLocation = (Get-Item -Path ".\" -Verbose).FullName
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition;
$includePath = Join-Path $scriptPath -ChildPath "SharedConfigFunctions.ps1";
. "$includePath";

$VersionsXml = [Xml](Get-Content $(Join-Path $scriptPath -ChildPath "Versions.xml") -ErrorVariable err)
$splitVers = GetVersionFromParam $version
SetVersionFromParams $VersionsXml "Nightly" "Evolutions" $splitVers.Major $splitVers.Minor $splitVers.BuildNumber $splitVers.Revision;
$splitVers
([int]$splitVers.Minor+1)
#git checkout -b ([int]$splitVers.Minor+1)