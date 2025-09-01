#requires -Modules WPF

function Import-IniFile {
    param (
        [string]$Path
    )
    $ini = @{}
    $valueTrimmer = { [string]$_.Trim('"').Trim() }
    switch -regex -file $Path
    {
        '^\[(.+)\](;.*)?' # Section
        {
            $section = $matches[1];
            $ini[$section] = @{};
        }
        '^[;|#](.*)$' # Comment
        {
            # Ignore comments
        }
        '(.+?)\s*=(.*)(;.*)?' # Key
        {
            $name,$value = $matches[1..2]
            $name = $name.Trim('"').Trim();
            if ($value.Contains('|')) {
                $value = $value.Split('|') | ForEach-Object $valueTrimmer;
            } else {
                $value = $value.Trim('"').Trim();
            }

            $ini[$section][$name] = $value;
        }
    }
    return $ini
}


function Write-ActionLog {
    [CmdletBinding()]
    param (
        [System.Windows.Window]$Window,
        [string]$Message
    )
    Invoke-ControlDispatcher -Control $window -ScriptBlock {
        $actionLog = $window.FindName("ActionLog");
        $actionLog.AppendText("$Message`n");
        Write-Verbose $Message
        $actionLog.ScrollToEnd();
        $window.UpdateLayout();
    };
}

function New-Wizard {
    [CmdletBinding()]
    param (
        [string]$Title,
        [string]$XamlPath = $PSScriptRoot,
        [string]$XamlFile = "Wizard.xaml"
    )

    $window = Import-Xaml (Join-Path $XamlPath $XamlFile);
    $window.Title = $Title;

    return $window;
}

function Set-WizardStep {
    [CmdletBinding()]
    param (
        [System.Windows.Window]$Window,
        [hashtable[]]$Steps,
        [int]$StepIndex
    )

    Write-Verbose "Setting step: $StepIndex, $($Steps.Count) steps"

    if ($null -eq $Window -or `
        $null -eq $StepIndex -or `
        $null -eq $Steps -or `
        $StepIndex -lt 0 -or `
        $StepIndex -ge $Steps.Count
    ) {
        Write-Verbose "Hiding Window";
        $window.Hide();
        return $null;
    }
    
    $step = $Steps[$StepIndex];
    $stepName = $step.Keys[0];
    [scriptblock[]]$stepAction = $step[$stepName][0];
    
    Write-Verbose "Step: $stepName at index $StepIndex";

    $backButton   = $window.FindName("BackButton");
    $nextButton   = $window.FindName("NextButton");
    $buttonGrid   = $window.FindName("ButtonGrid");
    $progressGrid = $window.FindName("ProgressGrid");
    $progressBar  = $window.FindName("ProgressBar");

    Write-Verbose "Determine Button States"

    $backStep = if ($StepIndex -gt 0 -and $null -ne $step) { 
        $Steps[$StepIndex - 1] 
    } else { 
        $null 
    };

    $nextStep = if ($StepIndex -lt $Steps.Count - 1 -and $null -ne $step) {
        $Steps[$StepIndex + 1] 
    } else { 
        $null 
    };

    $backLabel = if ($backStep) { "Back" } else { "Close" };
    $nextLabel = if ($nextStep) { "Next" } else { "Finish" };

    Write-Verbose "Toggle Panel / Set Buttons"

    
    foreach ($stp in $Steps) {
        $k = $stp.Keys[0]
        $stepControl = $window.FindName($k);
        if ($stepControl) { 
            if ($k -eq $stepName) { 
                Write-Verbose "Showing $k"
                Invoke-ControlDispatcher -Control $window -ScriptBlock { $stepControl.Visibility = "Visible" }
            } else {
                Write-Verbose "Hiding $k"
                Invoke-ControlDispatcher -Control $window -ScriptBlock { $stepControl.Visibility = "Hidden" }
            }
        } 
    }
    Invoke-ControlDispatcher -Control $window -ScriptBlock {
        $backButton.Content = $backLabel;
        $nextButton.Content = $nextLabel;
    }
    

    
    if ($stepAction -and $stepAction.Count -gt 0) {
        $progress = 0;
        Write-Verbose "Executing Step Actions"
        Invoke-ControlDispatcher -Control $window -ScriptBlock {
            if ($buttonGrid) { $buttonGrid.Visibility = "Hidden"; }
            if ($progressGrid) { $progressGrid.Visibility = "Visible"; }
            if ($progressBar) { $progressBar.Value = 0; }
        };
        [int]$ticks = 100 / $stepAction.Count;
        foreach ($action in $stepAction) {
            $action.Invoke() | Out-Null;
            #pause;
            $progress += $ticks;
            Invoke-ControlDispatcher -Control $window -ScriptBlock {
                if ($progressBar) { $progressBar.Value = $progress; }
            };
            Write-Verbose "Progress: $progress%"
        }

        Write-Verbose "Re-enabling Buttons"
        Invoke-ControlDispatcher -Control $window -ScriptBlock {
            if ($StepIndex -eq $Steps.Count-1) { 
                $backButton.IsEnabled = $false; 
            }
            if ($progressGrid) { $progressGrid.Visibility = "Hidden"; }
            if ($buttonGrid) { $buttonGrid.Visibility = "Visible"; }
        };
        
    }

    return $stepIndex;
}
