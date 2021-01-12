<#
.Synopsis
   Shared functions used when configuring sites.
#>

## Helper functions
function Update_Value([string] $itemKey, $itemValue) {
    Write-Debug "Updated Value [$itemKey)] with [$itemValue]"
}

function Update_Address([string] $itemKey, $itemValue) {
    Write-Debug "Updated Endpoint Address [$itemKey)] with [$itemValue]"
}

function Update_EmailSettings([Xml] $XmlToUpdate, $EmailSettings) {
    # Email settings
    $XmlToUpdate.configuration.'system.net'.mailSettings.smtp.network.host = $EmailSettings.Host
    $XmlToUpdate.configuration.'system.net'.mailSettings.smtp.network.port = $EmailSettings.PortNumber
    $XmlToUpdate.configuration.'system.net'.mailSettings.smtp.network.userName = $EmailSettings.UserName
    $XmlToUpdate.configuration.'system.net'.mailSettings.smtp.network.password = $EmailSettings.Password
}
    
function Update_NewRelic([Xml] $XmlToUpdate, $NewRelicSettings, $installType) {
    # App Settings
    foreach($item in $XmlToUpdate.configuration.appSettings.add)
    {
        Switch ($item.key) {
            "NewRelic.AgentEnabled" { $item.value = $NewRelicSettings.AgentEnabled }
            "NewRelic.AppName" { 
                if ($NewRelicSettings.AppName) {
                    $item.value = $NewRelicSettings.AppName.Replace("{versionNumber}", $VersionNumber).Replace("{installType}", $installType); Update_Value $item.key $item.value
                }
                else {
                    $item.value = $item.value.Replace("{versionNumber}", $VersionNumber).Replace("{installType}", $installType); Update_Value $item.key $item.value
                }
            }
        }
    }
}
    
function Update_ServiceBehavior([Xml] $XmlToUpdate, [String] $UseHttps) {
    # Work out if we are using Https or not
    $HttpEnabled = "true"
    $HttpsEnabled = "false"
    if ($UseHttps.ToLower().Equals("true")) {
        $HttpEnabled = "false"
        $HttpsEnabled = "true"
    }

    # Service Model Behaviours
    foreach($item in $XmlToUpdate.configuration.'system.serviceModel'.behaviors.serviceBehaviors.behavior)
    {
        if ($item.serviceMetaData)
        {
            if ($item.serviceMetaData.httpsGetEnabled) {
                $item.serviceMetaData.httpsGetEnabled = $HttpsEnabled
            }
                
            if ($item.serviceMetaData.httpGetEnabled) {
                $item.serviceMetaData.httpGetEnabled = $HttpEnabled
            }
        }
    }
}

function Update_ServiceBindings([Xml] $XmlToUpdate, [String] $serviceMode, [String] $clientCredentialsType) {
    # Service Model Bindings
    if ($XmlToUpdate.configuration.'system.serviceModel'.bindings.basicHttpBinding) {
        foreach($item in $XmlToUpdate.configuration.'system.serviceModel'.bindings.basicHttpBinding.binding)
        {
            if ($item.security) {
                $item.security.mode=$serviceMode
                foreach($subItem in $item.security)
                {
                    if ($subItem.transport)
                    {
                        if ($subItem.transport.clientCredentialType) {
                            $subItem.transport.clientCredentialType = $clientCredentialsType
                        }
                    }
                }
            }
        }
    }
}
    
function Update_ServiceEndpoint([Xml] $XmlToUpdate, [String] $EndpointName, [String] $EndpointAddress) {
    # Service Model Bindings
    if ($XmlToUpdate.configuration.'system.serviceModel'.bindings.basicHttpBinding) {
        foreach($item in $XmlToUpdate.configuration.'system.serviceModel'.client.endpoint)
        {
            if ($item.name.ToLower().Equals($EndpointName.ToLower())) {
                $item.address = $EndpointAddress
            }
        }
    }
}

function Update_SetIdentity([Xml] $XmlToUpdate, [String] $IdentityServiceAddress, [String] $IdentityEvolutionsBaseAddress, [String] $IdentitySignedOutRedirect, [String] $IdentityWebServiceAddress) {
	# Enable Identity and set URLS
	if ($XmlToUpdate.configuration.'system.web'.authentication) {
		$XmlToUpdate.configuration.'system.web'.authentication.mode = "None"
		Update_Value "Authentication.Mode" "None"
	}
	foreach($item in $WebConfigXml.configuration.appSettings.add)
	{
		Switch ($item.key) {
			"UseAccessIdentitySSO" { $item.value = "Yes"; Update_Value $item.key $item.value }
			"AccessIdentityBaseAddress" { $item.value = $IdentityServiceAddress; Update_Value $item.key $item.value }
			"AccessIdentityRedirectBaseAddress" { $item.value = $IdentityEvolutionsBaseAddress; Update_Value $item.key $item.value }
			"AccessIdentitySignOutRedirect" { $item.value = "$IdentityEvolutionsBaseAddress/identity/signout"; Update_Value $item.key $item.value }
			"AccessIdentitySignedOutRedirect" { $item.value = "$IdentityEvolutionsBaseAddress/identity/signedout"; Update_Value $item.key $item.value }
			"SignOutRedirect" { $item.value = $IdentitySignedOutRedirect; Update_Value $item.key $item.value }
			"owin:AutomaticAppStartup" { $item.value = "true"; Update_Value $item.key $item.value }
			"AccessIdentityOidcUrl" { $item.value = $IdentityWebServiceAddress; Update_Value $item.key $item.value }
		}
	}
}

function MaintainFilesInFoler([string]$monitorFolder, [int]$keepXFiles = 0) {
    
    if ($keepXFiles -lt 0) {
        $keepXFiles = 0;
    }

    [int]$index = 1;
    $filesToLoop = $(Get-ChildItem $monitorFolder | Sort LastWriteTimeUtc -Descending)
    foreach($file in $filesToLoop)
    {
        if ($index -gt $keepXFiles) {
            "Removing: " + $file.FullName
            Remove-Item $file.FullName -Force
        }

        $index++;
    }
}

function GetLightningVersion([string]$webEngineZip, [string]$tempFolder) {
    $ADMIT10File = "$tempFolder\ADMITServer.Shared.dll";

    Add-Type -Assembly System.IO.Compression.FileSystem;
    $zip = [IO.Compression.ZipFile]::OpenRead($webEngineZip);
    $zip.Entries | where {$_.Name -eq "ADMITServer.Shared.dll"} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $ADMIT10File, $true)};
    $zip.Dispose();

    $ADMIT10Version = "";
    $ADMIT10File = Get-Item $ADMIT10File;
    if ($ADMIT10File) {
        $ADMIT10Version = $ADMIT10File.VersionInfo.ProductVersion;
        Remove-Item $ADMIT10File -Force -ErrorAction Ignore -ErrorVariable e
    }

    return $ADMIT10Version;
}

function GetVersionFromXML([Xml]$VersionXML, [string]$VersionName, [string]$ProductName) {
    [String]$Result = "";

    foreach($item in $VersionXML.Versions.Version)
    {
        if ($item.Name.ToLower().Equals($VersionName.ToLower())) {
            # First the major version
            if ($item."$ProductName".Major) {
                $Result = $item."$ProductName".Major;
            }

            # Now the Minor
            if ($item."$ProductName".Minor) {
                if ($Result) {
                    $Result = $Result + "."
                }

                $Result = $Result + $item."$ProductName".Minor;
            }
            
            # Now the BuildNumber
            if ($item."$ProductName".BuildNumber) {
                if ($Result) {
                    $Result = $Result + "."
                }

                $Result = $Result + $item."$ProductName".BuildNumber;
            }
            
            # Finally the Revision
            if ($item."$ProductName".Revision) {
                if ($Result) {
                    $Result = $Result + "."
                }

                $Result = $Result + $item."$ProductName".Revision;
            }

            # No need to look at anything else
            break;
        }
    }

    return $Result;
}

function GetVersionFromParam([string]$AssemblyVersion) {
    [Array]$splitVers = $AssemblyVersion.Split(".");
    $Result = New-Object PSObject -Property @{Major = ""; Minor = ""; BuildNumber = ""; Revision = ""};

    # First the major version
    if ($splitVers.Length -gt 0) {
        $Result.Major = $splitVers[0].ToString();
    }

    # Now the Minor
    if ($splitVers.Length -gt 1) {
        $Result.Minor = $splitVers[1].ToString();
    }
            
    # Now the BuildNumber
    if ($splitVers.Length -gt 2) {
        $Result.BuildNumber = $splitVers[2].ToString();
    }
            
    # Finally the Revision
    if ($splitVers.Length -gt 3) {
        $Result.Revision = $splitVers[3].ToString();
    }

    # Return Variables
    return $Result;
}

function GetVersionFromParams([string]$Major, [string]$Minor, [string]$BuildNumber, [string]$Revision) {
    # First the major version
    $Result = $Major;

    # Now the Minor
    if ($Minor) {
        if ($Result) {
            $Result = $Result + "."
        }

        $Result = $Result + $Minor;
    }
            
    # Now the BuildNumber
    if ($BuildNumber) {
        if ($Result) {
            $Result = $Result + "."
        }

        $Result = $Result + $BuildNumber;
    }
            
    # Finally the Revision
    if ($Revision) {
        if ($Result) {
            $Result = $Result + "."
        }

        $Result = $Result + $Revision;
    }

    return $Result;
}

function SetVersionFromParams([Xml]$VersionXML, [String]$VersionName, [String]$ProductName, [String]$Major, [String]$Minor, [String]$BuildNumber, [String]$Revision) {
    foreach($item in $VersionXML.Versions.Version)
    {
        if ($item.Name.ToLower().Equals($VersionName.ToLower())) {
            # First the major version
            if ($item."$ProductName".Major) {
                $item."$ProductName".Major = $Major;
            }

            # Now the Minor
            if ($item."$ProductName".Minor) {
                $item."$ProductName".Minor = $Minor;
            }
            
            # Now the BuildNumber
            if ($item."$ProductName".BuildNumber) {
                $item."$ProductName".BuildNumber = $BuildNumber;
            }
            
            # Finally the Revision
            if ($item."$ProductName".Revision) {
                $item."$ProductName".Revision = $Revision;
            }

            # No need to do anything else
            break;
        }
    }
}

function SetVersionFromParam([Xml]$VersionXML, [string]$VersionName, [string]$ProductName, [string]$AssemblyVersion) {
    $splitVers = GetVersionFromParam $AssemblyVersion;

    foreach($item in $VersionXML.Versions.Version)
    {
        if ($item.Name.ToLower().Equals($VersionName.ToLower())) {
            # First the major version
            if ($item."$ProductName".Major) {
                $item."$ProductName".Major = $splitVers.Major;
            }

            # Now the Minor
            if ($item."$ProductName".Minor) {
                $item."$ProductName".Minor = $splitVers.Minor;
            }
            
            # Now the BuildNumber
            if ($item."$ProductName".BuildNumber) {
                $item."$ProductName".BuildNumber = $splitVers.BuildNumber;
            }
            
            # Finally the Revision
            if ($item."$ProductName".Revision) {
                $item."$ProductName".Revision = $splitVers.Revision;
            }

            # No need to do anything else
            break;
        }
    }
}

function GetTagFrom([Xml]$VersionXML, [String]$VersionName, [String]$ProductName) {
    # First the major version
    $Result = "";

    foreach($item in $VersionXML.Versions.Version)
    {
        if ($item.Name.ToLower().Equals($VersionName.ToLower())) {
            # Does the tag exist?
            if ($item."$ProductName".GitTagFrom) {
                $Result = $item."$ProductName".GitTagFrom;
            }

            # No need to do anything else
            break;
        }
    }

    return $Result;
}

function SetTagFrom([Xml]$VersionXML, [String]$VersionName, [String]$ProductName, [String]$GitTagFrom) {
    # Find the tag and set it.
    foreach($item in $VersionXML.Versions.Version)
    {
        if ($item.Name.ToLower().Equals($VersionName.ToLower())) {
            # Does the tag exist?
            if ($item."$ProductName".GitTagFrom) {
                $item."$ProductName".GitTagFrom = $GitTagFrom;
            }

            # No need to do anything else
            break;
        }
    }
}

function GetTagTo([Xml]$VersionXML, [String]$VersionName, [String]$ProductName) {
    # First the major version
    $Result = "";

    foreach($item in $VersionXML.Versions.Version)
    {
        if ($item.Name.ToLower().Equals($VersionName.ToLower())) {
            # Does the tag exist?
            if ($item."$ProductName".GitTagTo) {
                if ($item."$ProductName".GitTagTo -eq "{CURRENT}") {
                    $Result = GetVersionFromXML $VersionXML $VersionName $ProductName;
                }
                else {
                    $Result = $item."$ProductName".GitTagTo;
                }
            }

            # No need to do anything else
            break;
        }
    }

    return $Result;
}

function SetTagTo([Xml]$VersionXML, [String]$VersionName, [String]$ProductName, [String]$GitTagTo) {
    # Find the tag and set it.
    foreach($item in $VersionXML.Versions.Version)
    {
        if ($item.Name.ToLower().Equals($VersionName.ToLower())) {
            # Does the tag exist?
            if ($item."$ProductName".GitTagTo) {
                $item."$ProductName".GitTagTo = $GitTagTo;
            }

            # No need to do anything else
            break;
        }
    }
}