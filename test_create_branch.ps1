param ($version)
git checkout master
Write-Host "Loading Helper Functions" -ForegroundColor Cyan;
$currentLocation = (Get-Item -Path ".\" -Verbose).FullName
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition;
$includePath = Join-Path $scriptPath -ChildPath "SharedConfigFunctions.ps1";
. "$includePath";

$VersionsXml = [Xml](Get-Content $(Join-Path $scriptPath -ChildPath "Versions.xml") -ErrorVariable err)
Write-Host "Getting versions" -ForegroundColor Cyan;
$EVOVersion = GetVersionFromXML $VersionsXml "Nightly" "Evolutions";
if($version -eq $null) {
	$splitVers = GetVersionFromParam $EVOVersion
	SetVersionFromParams $VersionsXml "Nightly" "Evolutions" $splitVers.Major ([int]$splitVers.Minor+1) $splitVers.BuildNumber $splitVers.Revision;
	$VersionsXml.Save($(Join-Path $scriptPath -ChildPath "Versions.xml"));
	$EVOVersion = GetVersionFromXML $VersionsXml "Nightly" "Evolutions";
	git commit -a -m "Update Version.xml"
	git tag $EVOVersion -a -m "Tag for version $EVOVersion"
	git push --porcelain
	git push --tags --porcelain
	git checkout -b "release/$($splitVers.Major).$([int]$splitVers.Minor+1)"
	git push origin "release/$($splitVers.Major).$([int]$splitVers.Minor+1)"
}
else
{
	$splitVers = GetVersionFromParam $version
	SetVersionFromParams $VersionsXml "Nightly" "Evolutions" $splitVers.Major ([int]$splitVers.Minor+1) $splitVers.BuildNumber $splitVers.Revision;
	$VersionsXml.Save($(Join-Path $scriptPath -ChildPath "Versions.xml"));
	$EVOVersion = GetVersionFromXML $VersionsXml "Nightly" "Evolutions";
	$splitVers.Minor
	git commit -a -m "Update Version.xml"
	git tag $EVOVersion -a -m "Tag for version $EVOVersion"
	git push --porcelain
	git push --tags --porcelain
	git checkout -b "release/$($splitVers.Major).$([int]$splitVers.Minor+1)"
	git push origin "release/$($splitVers.Major).$([int]$splitVers.Minor+1)"
}

