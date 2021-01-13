param ([Parameter(Mandatory = $True)]$version, [Parameter(Mandatory = $False)]$branchName)

git checkout master

Write-Host "Loading Helper Functions" -ForegroundColor Cyan;
$currentLocation = (Get-Item -Path ".\" -Verbose).FullName
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition;
$includePath = Join-Path $scriptPath -ChildPath "SharedConfigFunctions.ps1";
. "$includePath";

$VersionsXml = [Xml](Get-Content $(Join-Path $scriptPath -ChildPath "Versions.xml") -ErrorVariable err)
Write-Host "Getting versions" -ForegroundColor Cyan;
$EVOVersion = GetVersionFromXML $VersionsXml "Nightly" "Evolutions";

# ----AutoIncrement----
# if($version -eq $null) {
	# $splitVers = GetVersionFromParam $EVOVersion
	# SetVersionFromParams $VersionsXml "Nightly" "Evolutions" $splitVers.Major ([int]$splitVers.Minor+1) $splitVers.BuildNumber $splitVers.Revision;
	# $VersionsXml.Save($(Join-Path $scriptPath -ChildPath "Versions.xml"));
	# $EVOVersion = GetVersionFromXML $VersionsXml "Nightly" "Evolutions";
	# git commit -a -m "Update Version.xml"
	# git tag $EVOVersion -a -m "Tag for version $EVOVersion"
	# git push --porcelain
	# git push --tags --porcelain
	# git checkout -b "releases/$($splitVers.Major).$([int]$splitVers.Minor+1)"
	# git push origin "releases/$($splitVers.Major).$([int]$splitVers.Minor+1)"
# }
# else
# {
	$splitVers = GetVersionFromParam $version
	SetVersionFromParams $VersionsXml "Nightly" "Evolutions" $splitVers.Major $splitVers.Minor $splitVers.BuildNumber $splitVers.Revision;
	$VersionsXml.Save($(Join-Path $scriptPath -ChildPath "Versions.xml"));
	
	# ----Change Tag FROM-----
	# $TagFrom = GetTagFrom $VersionsXml "Nightly" "Evolutions";
	# $TagFrom
	# SetTagFrom $VersionsXml "Nightly" "Evolutions" "2.1.4"
	# $VersionsXml.Save($(Join-Path $scriptPath -ChildPath "Versions.xml"));
	# $TagFrom = GetTagFrom $VersionsXml "Nightly" "Evolutions";
	# $TagFrom
	
	# ----Change Tag TO-----
	# $TagTo = GetTagTo $VersionsXml "Nightly" "Evolutions";
	# $TagTo
	# SetTagTo $VersionsXml "Nightly" "Evolutions" "SMTH"
	# $VersionsXml.Save($(Join-Path $scriptPath -ChildPath "Versions.xml"));
	# $TagTo = GetTagTo $VersionsXml "Nightly" "Evolutions";
	# $TagTo
	
	# $EVOVersion = GetVersionFromXML $VersionsXml "Nightly" "Evolutions";
	git commit -a -m "Update Version.xml"
	git tag $EVOVersion -a -m "Tag for version $EVOVersion"
	git push --porcelain
	git push --tags --porcelain
	
	if($branchName -eq $null) 
	{
		git checkout -b "releases/$($splitVers.Major).$($splitVers.Minor)"
		git push origin "releases/$($splitVers.Major).$($splitVers.Minor)"
	}
	else
	{
		git checkout -b "releases/$branchName"
		git push origin "releases/$branchName"
	}
# }

