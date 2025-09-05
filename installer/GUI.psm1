#requires -Modules Wizard

$Script:TempAssets = @();
$fontPath = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'

function Add-Asset {
    param(
        [string]$Source,
        [string]$Destination,
        [scriptblock]$Condition
    )
    if ($Condition.Invoke()) {
        $Script:TempAssets += Copy-Item -Path $Source -Destination $Destination -Force -PassThru;
    }
}

function Remove-Assets {
    foreach ($asset in $Script:TempAssets) {
        Remove-Item $asset -Force -ErrorAction SilentlyContinue
    }
}


function CleanUp {
    # Clean up any temporary files or resources
    Remove-Assets
    Remove-Module MW2;
    Remove-Module Wizard;
    Remove-Module WPF;
    Remove-Module Ini;
    Pause;
}


function Show-Selector {
    param (
        [object[]]$Discs
    )
    if ($Discs.Count -eq 0) {
        return;
    }

    $selectorSteps = @(
        @{ 'SelectStep' = @() }
    )
    $theme = Import-Xaml -Path (Join-Path $PSScriptRoot "themes\InstallerTheme.xaml");
    $selector = New-Wizard -XamlFile "Selector.xaml" -Title "Select MechWarrior 2 Disc";
    $selector.Resources = $theme;
    $selector.FindName("BackButton").Add_Click({
        Set-WizardStep -Window $selector -Steps $selectorSteps -StepIndex -1;
    });
    $selector.FindName("NextButton").Add_Click({
        $selectedIndex = $selector.FindName("AvailableEditions").SelectedIndex;
        if ($selectedIndex -ge 0 -and $selectedIndex -lt $Discs.Count) {
            $Script:disc = $Discs[$selectedIndex];
            Set-WizardStep -Window $selector -Steps $selectorSteps -StepIndex 2;
        }
    });
    Set-WizardStep -Window $selector -Steps $selectorSteps -StepIndex 0 | Out-Null;
    
    $selector.FindName("AvailableEditions").ItemsSource = $Discs;
    $selector.FindName("NextButton").Content = "Next";

    $selector.ShowDialog() | Out-Null;
    return $selector.FindName("AvailableEditions").SelectedItem;
}


function Show-Splash {
    param (
        [string]$Message,
        [string]$Title = "Please wait..."
    )
    $theme = Import-Xaml -Path (Join-Path $PSScriptRoot "themes\InstallerTheme.xaml");
    $loadingSplash = Import-Xaml (Join-Path $PSScriptRoot "windows\Splash.xaml");
    $loadingSplash.Resources = $theme;
    $loadingSplash.Title = $Title;
    $loadingSplash.FindName("Text").Text = $Message;
    $loadingSplash.Show();
    return $loadingSplash;
}

function Select-Theme {
    param (
        [object]$Edition
    )
    $theme = $null;
    switch ($edition.title) {
        { $_ -like "*Ghost*"  } { $theme = Import-Xaml -Path (Join-Path $PSScriptRoot "themes\GBLTheme.xaml"); break }
        { $_ -like "*Merc*" } { $theme = Import-Xaml -Path (Join-Path $PSScriptRoot "themes\MERCSTheme.xaml"); break }
        default { $theme = Import-Xaml -Path (Join-Path $PSScriptRoot "themes\MW2Theme.xaml"); break }
    }
    return $theme;
}


function Show-Browser {
    param (
        [hashtable]$Data
    )
    $Data = $Data.Clone();
    $items = @();
    $sectionKeys = @($Data.Keys | Where-Object { $_ -ne "Editions" });
    foreach ($key in $sectionKeys) {
        
        $value = $Data[$key];
        #Write-Host "Key: $key"
        $valueKeys = @($value.Keys);
        $newValue = @{};
        foreach ($k in $valueKeys) {
            #Write-Host "Prop: $k"

            if ($value[$k] -is [object[]]) {
                #Write-Host "Is Array"
                $arrayString = @($value[$k]) -join ", ";
                $newValue[$k] = $arrayString;
            }
            else {
                $newValue[$k] = $value[$k];
            }
        }
        $items += [pscustomobject]$newValue;
    }
    $theme = Import-Xaml -Path (Join-Path $PSScriptRoot "themes\InstallerTheme.xaml");
    $window = Import-Xaml -Path (Join-Path $PSScriptRoot "windows\Browser.xaml");
    $window.Resources = $theme;
    $window.Title = "Data Browser";
    $window.FindName("Entries").ItemsSource = $items;
    $window.FindName("CloseButton").Add_Click({
        $window.Close();
    });
    $window.ShowDialog() | Out-Null;
    
}


# The XAML Parser WON'T load this font loose from loose xaml
# Documentation indicates that it should, but it doesn't.

Add-Asset -Source (Join-Path $PSScriptRoot "assets\Steiner.otf") `
          -Destination $fontPath `
          -Condition {-not (Test-Path (Join-Path $fontPath "Steiner.otf"))}