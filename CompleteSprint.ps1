<#
.Synopsis
   Perform a release of Evolutions
.DESCRIPTION
   This will tag the repository and update the versions.xml
#>
Param
(	
    # New Version
    [Parameter(Mandatory = $True)]
    [String]
    $NewVersion,
    
    # Commit to Git
    [Parameter(Mandatory = $False)]
    [String]
    $CommitToGit = $False,

    # Branch to Commit to Git
    [Parameter(Mandatory = $False)]
    [String]
    $Branch = "master"
)

$Error.Clear();
	
# First ensure the branch is on the specified branch.
& "C:\Program Files\Git\bin\git" checkout $Branch
& "C:\Program Files\Git\bin\git" pull
	
# Helper functions.
Write-Host "Loading Helper Functions" -ForegroundColor Cyan;
$currentLocation = (Get-Item -Path ".\" -Verbose).FullName
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition;
$includePath = Join-Path $scriptPath -ChildPath "SharedConfigFunctions.ps1";
. "$includePath";
    
# Open the versions file to pull the version through.
$VersionsXml = [Xml](Get-Content $(Join-Path $scriptPath -ChildPath "Versions.xml") -ErrorVariable err);
    
# Get existing version.
Write-Host "Getting versions" -ForegroundColor Cyan;
$EVOVersion = GetVersionFromXML $VersionsXml "Nightly" "Evolutions";

# Update new version.
$splitVers = GetVersionFromParam $NewVersion;
SetVersionFromParams $VersionsXml "Nightly" "Evolutions" $splitVers.Major $splitVers.Minor $splitVers.BuildNumber $splitVers.Revision;
SetTagFrom $VersionsXml "Nightly" "Evolutions" $EVOVersion;

# Finally Save the XML for the new versions.
$VersionsXml.Save($(Join-Path $scriptPath -ChildPath "Versions.xml"));
    
# Commit to Git if we need to.
if ($CommitToGit -eq $True) {
    Write-Host "Committing Versions.xml to Git" -ForegroundColor Cyan;
    & "C:\Program Files\Git\bin\git" commit -a -m "Update Version.xml for Complete Sprint."
    & "C:\Program Files\Git\bin\git" tag $EVOVersion -a -m "Tag for version $EVOVersion"
    & "C:\Program Files\Git\bin\git" push --porcelain
    & "C:\Program Files\Git\bin\git" push --tags --porcelain
}
	
# Update the maintenance and Utilities folder to the new version
[string]$fileContent = Get-Content "$currentLocation\DataSQL\99_Maintenance\M001_Clear StructureLog_Table.sql" -Encoding UTF8 -Raw;
$fileContent = $fileContent -replace "\(# -.*- #\)", "(# - $NewVersion - #)";
$fileContent.TrimEnd() | Out-File -Force -FilePath "$currentLocation\DataSQL\99_Maintenance\M001_Clear StructureLog_Table.sql" -Encoding UTF8;

# Commit to Git if we need to.
if ($CommitToGit -eq $True) {
    Write-Host "Committing maintenance script to Git" -ForegroundColor Cyan;
    & "C:\Program Files\Git\bin\git" commit -a -m "Update 99_Maintenance script(s) for Release."
    & "C:\Program Files\Git\bin\git" push --porcelain
}

Write-Host "Finished Consolidating files" -ForegroundColor Green;
