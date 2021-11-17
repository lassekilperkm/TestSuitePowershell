param(
[string]$NAVVersion
)

if($NAVVersion -eq 'n') {
    $NAVFolder = "Microsoft Dynamics NAV\110"
    $HKLM = "Microsoft Dynamics NAV\110"
}
elseif($NAVVersion -eq 'b') {
    $NAVFolder = "Microsoft Dynamics 365 Business Central\140"
    $HKLM = "Microsoft Dynamics NAV\140"
}
elseif($NAVVersion -eq 'a') {
  $NAVFolder = "Microsoft Dynamics 365 Business Central\190"
  $HKLM = "Microsoft Dynamics NAV\190"
}

#NAV Module Import
if ($NAVVersion -eq 'a') {
  $DynamicsRoot = "C:\Program Files\$NAVFolder\Service"
  # Import NAV App cmdlets
  $navAppToolsAssembly = "Microsoft.Dynamics.Nav.Apps.Tools"
  $navAppManagementAssembly = "Microsoft.Dynamics.Nav.Apps.Management"
  Import-Module (Join-Path $DynamicsRoot ($navAppToolsAssembly + ".psd1"))
  Import-Module (Join-Path $DynamicsRoot ($navAppManagementAssembly + ".psd1"))  
}
else {
  $NavIde = "C:\Program Files (x86)\$NAVFolder\RoleTailored Client\finsql.exe"
  $DynamicsRoot = "C:\Program Files (x86)\$NAVFolder\RoleTailored Client"
  $module = Import-Module (Join-Path $DynamicsRoot 'Microsoft.Dynamics.Nav.Model.Tools.psd1') -ArgumentList $NavIde -DisableNameChecking -PassThru

  # Import NAV App cmdlets
  $navAppToolsAssembly = "Microsoft.Dynamics.Nav.Apps.Tools"
  $navAppManagementAssembly = "Microsoft.Dynamics.Nav.Apps.Management"
  Import-Module (Join-Path $DynamicsRoot ($navAppToolsAssembly + ".psd1"))
  Import-Module (Join-Path $DynamicsRoot ($navAppManagementAssembly + ".psd1"))
}


$errorVariable = $null

# Import-Module or register Snap-in, that will enable side-by-side registrations
function RegisterSnapIn($snapIn, $visibleName)
{
  if(Get-Module $snapIn)
  {
    return
  }
  $nstPath = "HKLM:\SOFTWARE\Microsoft\$HKLM\Service"

  $snapInAssembly = Join-Path (Get-ItemProperty -path $nstPath).Path "\$snapIn.psm1"
  if(!(Test-Path $snapInAssembly)) { $snapInAssembly = Join-Path (Get-ItemProperty -path $nstPath).Path "\$snapIn.psd1" }
  if(!(Test-Path $snapInAssembly)) { $snapInAssembly = Join-Path (Get-ItemProperty -path $nstPath).Path "\$snapIn.dll" }

  # First try to import the Snap-in
  Import-Module $snapInAssembly -ErrorVariable errorVariable -ErrorAction SilentlyContinue
  
  if (Check-ErrorVariable -eq $true)
  {
    # fallback to add the snap-in
    if ((Get-PSSnapin -Name $snapIn -ErrorAction SilentlyContinue) -eq $null)
    {
        if ((Get-PSSnapin -Registered $snapIn -ErrorAction SilentlyContinue) -eq $null)
        {
            write-host -fore Red "Couldn't register $visibleName"
            write-host -fore Red "Some cmdlets may not be available`n"
        }
        else
        {
            Add-PSSnapin $snapIn            
        }
    }
  }
}

# Check if there is any error in the ErrorVariable
function Check-ErrorVariable
{
    return ($errorVariable -ne $null -and $errorVariable.Count -gt 0)
}

# Register Microsoft Dynamics NAV Management Snap-in
RegisterSnapIn "Microsoft.Dynamics.Nav.Management" "Microsoft Dynamics NAV Management Snap-in"

# Register Microsoft Dynamics NAV Apps Management Snap-in
RegisterSnapIn "Microsoft.Dynamics.Nav.Apps.Management" "Microsoft Dynamics NAV App Management Snap-in"