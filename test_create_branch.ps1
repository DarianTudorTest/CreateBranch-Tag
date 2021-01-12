$version = 2.5
Write-Host "Loading Helper Functions" -ForegroundColor Cyan;
$currentLocation = (Get-Item -Path ".\" -Verbose).FullName
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition;
$includePath = Join-Path $scriptPath -ChildPath "SharedConfigFunctions.ps1";
. "$includePath";
$splitVers = GetVersionFromParam $version

git checkout -b ([int]$splitVers.Minor+1)