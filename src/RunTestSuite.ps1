$ErrorActionPreference = "Stop"

$UserName = "user"
$passwordPlain = "password"
$ServerInstance = "myServerInstance"
$Database_name = "myDatabase"
$Domain = "myDomain"
$NAVVersion = 'a' #a = Business Central AL (BC19), b = Business Central CAL (BC14), n = NAV 2018
$TargetMachine = "localhost" #the service tier computer/server

function Initialize-TestSuite
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ServerInstance,
        [Parameter(Mandatory=$true)][string]$TestCodeunitFilter,
        [string]$NAVVersion
    )
        $Modules = "NAVModuleImport.ps1" #change path if needed
        import-module $Modules -ArgumentList $NAVVersion | Out-Null

        #get the first company that is available 
        $CompanyName = Get-NAVCompany -ServerInstance $ServerInstance | Select-Object -First 1 -ExpandProperty "CompanyName"

        #Get SOAPServicesPort
        $xmlConfig = Get-NAVServerConfiguration -ServerInstance $ServerInstance -AsXml
        $Port = ($XmlConfig.configuration.appSettings.ChildNodes | Where-Object {$_.Key -eq "SOAPServicesPort"}).Value

        #build the connectionstring for the current database
        $ConnectionString = "http://${TargetMachine}:$Port/$ServerInstance/WS/$CompanyName/Codeunit/TestRunMgt"        
        $password = ConvertTo-SecureString $passwordPlain -AsPlainText -Force
        $MyCredential = New-Object System.Management.Automation.PSCredential ($UserName, $password) #Auth without domain!!!
        $proxy = New-WebServiceProxy -Uri $ConnectionString -Credential $MyCredential
        $proxy.Timeout = 1000 * 60 * 60 # 1 hour
        $proxy.InitializeTestRun($TestCodeunitFilter)

        $users = @()
        $users += Get-NAVServerUser -ServerInstance $ServerInstance
        foreach($user in $users) {
            if($user[1] -eq "$Domain\$User") {
                $existing = $true
            }
        }

        if($existing -ne $true) {
            New-NAVServerUser -WindowsAccount "$Domain\$User" -Password (ConvertTo-SecureString $passwordPlain -AsPlainText -Force) -LicenseType Full -ServerInstance $ServerInstance
            New-NAVServerUserPermissionSet -WindowsAccount "$Domain\$User" -PermissioNSetId SUPER -ServerInstance $ServerInstance
        }
}

function Run-TestSuite
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][String]$ServerInstance, 
        [string]$NAVVersion
    )    
        $Modules = "NAVModuleImport.ps1"
        import-module $Modules -ArgumentList $NAVVersion | Out-Null

        #get the first company that is available
        $CompanyName = Get-NAVCompany -ServerInstance $ServerInstance | Select-Object -First 1 -ExpandProperty "CompanyName"
        #extract the Client Services Port from the Service Tier configuration
        $XmlConfig = Get-NAVServerConfiguration -ServerInstance $ServerInstance -AsXml
        $Port = ($XmlConfig.configuration.appSettings.ChildNodes | Where-Object {$_.Key -eq "SOAPServicesPort"}).Value

        #build the connectionstring for the current database
        $ConnectionString = "http://${TargetMachine}:$Port/$ServerInstance/WS/$CompanyName/Codeunit/TestRunMgt"        
        $password = ConvertTo-SecureString $passwordPlain -AsPlainText -Force
        $MyCredential = New-Object System.Management.Automation.PSCredential ($User, $password) #Auth without domain!!!
        $proxy = New-WebServiceProxy -Uri $ConnectionString -Credential $MyCredential
        $proxy.Timeout = 1000 * 60 * 60 # 1 Hour
        $myOutput = [XML]$proxy.RunFromWebservice() 
        $myOutput.root.CALTestLine | Format-Table -Property TestCodeunit, CALtestLineName, CALTestLineResult, CALTestLineFirstError
        $TestFailures = $myOutput.root.CALTestLine | Where-Object {$_.CALTestLineResult -eq 'Failure'} | Format-Table -Property TestCodeunit, CALTestLineName, CALTestLineResult, CALTestLineFirstError
    }
}

write-host("$Database_name : Prepare Test Suite...")
#create a splat (collection of parameters) and pass the collection to Initialize-TestSuite function
$InitNAVAutomatedTestParameters = @{
    "ServerInstance" = $Database_name;
    "TestCodeunitFilter" = "50101..50110";
    "NAVVersion" = $NAVVersion
}

Initialize-TestSuite @InitNAVAutomatedTestParameters
write-host("$Database_name : Test Suite prepared.")

Write-Host("$Database_name : Run Test Suite...")
#create a splat (collection of parameters) and pass the collection to Run-TestSuite function
$StartNAVAutomatedTestParameters = @{
    "ServerInstance" = $Database_name;
    "NAVVersion" = $NAVVersion

}
Run-TestSuite @StartNAVAutomatedTestParameters
Write-Host("$Database_name : Test Suite executed.")