#requires -Modules Wizard

# If we don't find the Steiner font already, we need to install it and ensure we don't leave it behind
# The XAML Parser WON'T load this font loose from loose xaml
# Documentation indicates that it should, but it doesn't.
$removeFont = $false;
if (-not (Test-Path $env:LOCALAPPDATA\Microsoft\Windows\Fonts\Steiner.otf)) {
    $removeFont = $true;
    Copy-Item (Join-Path $PSScriptRoot "Steiner.otf") $env:LOCALAPPDATA\Microsoft\Windows\Fonts\Steiner.otf
}

function Remove-Assets {
    if ($removeFont) {
        Remove-Item $env:LOCALAPPDATA\Microsoft\Windows\Fonts\Steiner.otf -Force -ErrorAction SilentlyContinue
    }
}


function CleanUp {
    # Clean up any temporary files or resources
    Remove-Assets
    Remove-Module Wizard;
    Remove-Module WPF;
    Remove-Module MW2;
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
    $selector = New-Wizard -XamlFile "Selector.xaml" -Title "Locating MechWarrior 2 Disc(s)";
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
        [string]$Message
    )
    $loadingSplash = Import-Xaml (Join-Path $PSScriptRoot "Splash.xaml");
    $loadingSplash.Title = "Please wait...";
    $loadingSplash.FindName("Text").Text = $Message;
    $loadingSplash.Show();
    return $loadingSplash;
}