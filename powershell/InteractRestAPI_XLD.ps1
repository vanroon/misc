###################################################################################
# Example script to interact with XL Deploy API.                                  #
#                                                                                 #
# This script it NOT supported. Use only for reference and at your own risk.      #
#                                                                                 #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


Function XLD-setCredential {
<#
.SYNOPSIS
Create credential object for use with the XL Deploy REST API.

.DESCRIPTION
This function requires a username and a password. The password will be stored as a secure string and only in memory, not on disk.
The result of this function is a credential object that can be used to interact with the XL Deploy REST API and in specific with other functions defined in this file.

#>
    param (
        [Parameter(Mandatory = $true)][String]$Username
    )
    process{
        $password = Read-Host -AsSecureString 
        $CredentialObject = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$password
        return $CredentialObject
    }        
}

Function XLD-ListCI {
<#
.SYNOPSIS
Returns an XML documents based on an XL Deploy REST API Query. Result of function must be stored in a variable.

.DESCRIPTION
This function returns an XML document with the results of a query. The following query parameters are mandatory:
 - namePattern

The following query parameters are optional:
 - Parent CI

Example of a query: 

    Invoke-WebRequest $rootUrl"/deployit/repository/query?namePattern=Environments/ITI/Prodlan/GFS-R%&type=udm.DeployedApplication&resultsPerPage=-1"

.PARAMETER credentialObject

Mandatory. Credential object to authenticate with XL Deploy. Create an object using function XLD-setCredential.

.PARAMETER NamePattern

Mandatory. A search pattern for the name. This is like the SQL "LIKE" pattern: the character '%' represents any string of zero or more characters, and the character '_' (underscore) represents any single character. Any literal use of these two characters must be escaped with a backslash ('\'). Consequently, any literal instance of a backslash must also be escaped, resulting in a double backslash ('\\').

.PARAMETER Parent

Optional. Contains path of the parent CI.

.EXAMPLE

$var = XLD-ListCIs -NamePattern %test% -parent Environments/TEST

#>
    Param (
        [Parameter(Mandatory = $true)][String]$rootUrl,
        [Parameter(Mandatory = $true)][PSCredential]$CredentialObject,
        [Parameter(Mandatory = $true)][String]$NamePattern,
        [Parameter(Mandatory = $false)]$Parent,
        [Parameter(Mandatory = $false)]$Type
    )
    Process {
        $Query = "namePattern=$NamePattern"
        if($Parent) {
            $Query += "&parent=$Parent"
        }
        if($Type) {
            $Query += "&type=$Type"
        }
        $url = $rootUrl + "/deployit/repository/query?$Query&resultsPerPage=-1"
        $result = Invoke-RestMethod -Uri $url -Method Get -Credential $CredentialObject -ContentType "Application/xml"
        write-host "`nfound" $result.SelectNodes("//ci").count "CIs:`n"
        foreach($i in $result.SelectNodes("//ci").ref){
            write-host $i
        } 
        return $result     
    }
}

Function XLD-DeleteCI {
<#
.SYNOPSIS

Delete multiple CIs from XL Deploy with the REST API.

.DESCRIPTION

Takes in an XML document that is returned by XLD REST API. Don't alter the document and pass it to this function.

.EXAMPLE

XLD-DeleteCI -CredentialObject $credentialObject -file $resultFromXLD-ListCIs
#>
    Param (
        [Parameter(Mandatory = $true)][String]$rootUrl,
        [Parameter(Mandatory = $true)][PSCredential]$CredentialObject,
        [Parameter(Mandatory = $true)][System.Xml.XmlDocument]$file
    )
    Process {
        Write-host "`nThe following CIs will be deleted:`n"
        foreach($i in $file.SelectNodes("//ci").ref){
            write-host $i
        }
        Write-host "`nAre you sure? (Default is No):" -ForegroundColor Yellow -BackgroundColor Red
        $ReadHost = Read-Host "( y / n ) "
        Switch ($ReadHost.ToLower()){
            {($_ -eq "y" ) -or ($_ -eq "yes")} {
                Write-host "`nCIs will be deleted";
                foreach($i in $file.SelectNodes("//ci").ref){
                    $url = $rootUrl + "/deployit/repository/ci/" + $i  
                    Invoke-RestMethod -Uri $url -Method Delete -Credential $CredentialObject -ContentType "Application/xml"
                    write-host $url
                }
            }
            {($_ -eq "n" ) -or ($_ -eq "no")} {
                Write-host "`nCIs will NOT be deleted"
            }        
        }           
    }
}

Function XLD-getRoles {
<#
.SYNOPSIS

.DESCRIPTION

.EXAMPLE

#>
    Param (
        [Parameter(Mandatory = $true)][String]$rootUrl,
        [Parameter(Mandatory = $true)][PSCredential]$CredentialObject
    )
    Process {
        # Create array to put in roles
        $roleArray = @()
        $url = $rootUrl + "/deployit/security/role"
        $result = Invoke-RestMethod -Uri $url -Method Get -Credential $CredentialObject -ContentType "Application/xml"
        foreach($i in $result.list.string){
            $roleArray += $i
        }
        return $roleArray     
            
    }
}

Function XLD-CreateRoles {
<#
.SYNOPSIS

.DESCRIPTION

.EXAMPLE

#>
    Param (
        [Parameter(Mandatory = $true)][String]$rootUrl,
        [Parameter(Mandatory = $true)][PSCredential]$CredentialObject,
        [Parameter(Mandatory = $true)][String]$roleName
    )
    Process {
        $url = $rootUrl + "/security/role/" + $roleName
        Invoke-RestMethod -Uri $url -Method post -Credential $CredentialObject -ContentType "Application/xml"     
    }
}

Function XLD-GetListWithAppSupDirs {
    Param (
        [Parameter(Mandatory = $true)][String]$rootUrl,
        [Parameter(Mandatory = $true)][PSCredential]$CredentialObject     
    )
    Process {
        #create empty array to put CIs
        $appDirCisArray = @()
        $appDirCisArrayList = new-object System.collections.Arraylist

        #Get all 'parent' folders
        $parentApplicationDirs = XLD-ListCI -rootUrl $rootUrl -CredentialObject $CredentialObject -parent Applications -type core.Directory -NamePattern %%

        #For all parent application directories find their sub dirs
        foreach($i in $parentApplicationDirs.SelectNodes("//ci").ref){
            $appSubDir = XLD-ListCI -rootUrl $rootUrl -CredentialObject $CredentialObject -parent $i -type core.Directory -NamePattern %%
            foreach($j in $appSubDir.SelectNodes("//ci").ref){
                $appDirCisArrayList.Add($j) > $null
                $appDirCisArray += $j
            }
        }


        #foreach($i in $var.SelectNodes("//ci").ref){
        #    $permission = "read"
        #    $url = $rootUrl + "/deployit/security/check/" + $permission + "/" + $i
        #    Invoke-RestMethod -Uri $url -Method Get -Credential $cred -ContentType "Application/xml" 
        #}
        return $appDirCisArray
    }
}


Function XLD-RevokeRepoEditPermissions {
    Param (
        [Parameter(Mandatory = $false)][String]$rootUrl = "http://urltolocation.com",
        [Parameter(Mandatory = $true)][PSCredential]$CredentialObject,
        [Parameter(Mandatory = $true)][Object]$roleArray,
        [Parameter(Mandatory = $true)][Object]$appDirsArray
    )
    Process {
        #sort arrays
        $roleArraySorted = $roleArray | Sort-Object
        $appDirsArraySorted = $appDirsArray | Sort-Object
        # for each CI, check for each role if they have repo#edit permission        
        foreach($j in $roleArraySorted){
            foreach($i in $appDirsArraySorted){            
                $url = $rootUrl + "/deployit/security/permission/repo%23edit/$j/$i"
                $res = Invoke-RestMethod -Uri $url -Method get -Credential $CredentialObject
                #write-host $res.selectNodes("boolean").ref
                $xmlFile = [xml]$res
                if($xmlFile.boolean -eq "true"){
                    write-host "$j has repo#edit permission on $i`nThis permission is revoked!"
                    Invoke-RestMethod -Uri $url -Method delete -Credential $CredentialObject                
                }
            }
        }
    }
}