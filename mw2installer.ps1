#requires -RunAsAdministrator
[cmdletbinding()]
param(
    [switch]$Browser
)
Import-Module (Join-Path $PSScriptRoot "installer\Ini.psm1")
Import-Module (Join-Path $PSScriptRoot "installer\WPF.psm1")
Import-Module (Join-Path $PSScriptRoot "installer\Wizard.psm1")
Import-Module (Join-Path $PSScriptRoot "installer\GUI.psm1")
Import-Module (Join-Path $PSScriptRoot "installer\MW2.psm1")

$DefaultInstallRoot = "C:\Games"
$Script:disc = $null;

$ini = Import-IniFile (Join-Path $PSScriptRoot "mw2Installer.ini");

if ($Browser) {
    Write-Host "Starting Browser"
    Show-Browser -Data $ini;
    Cleanup;
    return;
}


$loadingSplash = Show-Splash -Message "Locating MechWarrior 2 Disc(s)...";
$Script:discs = @( Find-MW2Disc -Editions $ini.Editions );
$loadingSplash.Close();

#pause;

$Script:disc = if ($Script:discs.Count -gt 1) {
    Show-Selector -Discs $Script:discs;
}
elseif ($Script:discs.Count -eq 1) {
    $Script:discs[0];
} 

if ($null -eq $Script:disc)
{
    Write-Error "MechWarrior 2 disc not found or no edition was selected."
    CleanUp;
    return;
}

$edition = Get-MW2Edition -Disc $Script:disc -IniFile $ini;

$steps = Get-MW2InstallSteps -Disc $Script:disc -InstallerPath $PSScriptRoot;

$stepDefinitions = @(
    @{ 'AgreementStep' = @() }
    $steps
)

Write-Verbose "Loading Wizard UI";
$theme = Select-Theme -Edition $edition;

$window = New-Wizard -Title "$($edition.title) Installer"; 
$window.Resources = $theme;

Write-Verbose "Initializing Wizard UI";
$readme = Get-Content (Join-Path $PSScriptRoot "README.txt") -Raw;
$window.FindName("AgreementText").Text = $readme;
$window.FindName("InstallPath").Text = (Join-Path $DefaultInstallRoot $edition.title);

Write-Verbose "Set Step 0"
$Script:current_step = Set-WizardStep -Window $window -Steps $stepDefinitions -StepIndex 0

Write-Verbose "Add Handlers"
$window.FindName("BrowseButton").Add_Click({    
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select a folder"
    $folderDialog.ShowNewFolderButton = $true
    
    if (Test-Path $DefaultInstallRoot) {
        $folderDialog.SelectedPath = $DefaultInstallRoot
    } else {
        $folderDialog.SelectedPath = "C:\Program Files (x86)\$($edition.title)"
    }

    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Invoke-ControlDispatcher -Control $window -ScriptBlock {
            $window.FindName("InstallPath").Text = $folderDialog.SelectedPath;
        };
    }
});

$window.FindName("BackButton").Add_Click({
    $Script:current_step = Set-WizardStep -Window $window -Steps $stepDefinitions -StepIndex ($Script:current_step - 1);
});


$window.FindName("NextButton").Add_Click({
    $Script:current_step = Set-WizardStep -Window $window -Steps $stepDefinitions -StepIndex ($Script:current_step + 1);
});

Write-Verbose "Show Dialog"
$window.ShowDialog() | Out-Null;



CleanUp;