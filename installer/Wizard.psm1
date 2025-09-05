#requires -Modules WPF



function Write-ActionLog {
    param (
        [System.Windows.Window]$Window,
        [string]$Message
    )
    Invoke-ControlDispatcher -Control $Window -ScriptBlock {
        $actionLog = $Window.FindName("ActionLog");
        $actionLog.AppendText("$Message`n");
        $actionLog.ScrollToEnd();
        $Window.UpdateLayout();
    };
}

function New-Wizard {
    param (
        [string]$Title,
        [string]$XamlPath = (Join-Path $PSScriptRoot "windows"),
        [string]$XamlFile = "Wizard.xaml"
    )

    $Window = Import-Xaml (Join-Path $XamlPath $XamlFile);
    $Window.Title = $Title;

    return $Window;
}

function Set-WizardStep {
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
        $Window.Hide();
        return $null;
    }
    
    $step = $Steps[$StepIndex];
    $stepName = $step.Keys[0];
    [scriptblock[]]$stepAction = $step[$stepName][0];
    
    Write-Verbose "Step: $stepName at index $StepIndex";

    $backButton   = $Window.FindName("BackButton");
    $nextButton   = $Window.FindName("NextButton");
    $buttonGrid   = $Window.FindName("ButtonGrid");
    $progressGrid = $Window.FindName("ProgressGrid");
    $progressBar  = $Window.FindName("ProgressBar");

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
        $stepControl = $Window.FindName($k);
        if ($stepControl) { 
            if ($k -eq $stepName) { 
                Write-Verbose "Showing $k"
                Invoke-ControlDispatcher -Control $Window -ScriptBlock { $stepControl.Visibility = "Visible" }
            } else {
                Write-Verbose "Hiding $k"
                Invoke-ControlDispatcher -Control $Window -ScriptBlock { $stepControl.Visibility = "Hidden" }
            }
        } 
    }
    Invoke-ControlDispatcher -Control $Window  -ScriptBlock {
        $backButton.Content = $backLabel;
        $nextButton.Content = $nextLabel;
    }
    

    
    if ($stepAction -and $stepAction.Count -gt 0) {
        $progress = 0;
        Write-Verbose "Executing Step Actions"
        Invoke-ControlDispatcher -Control $Window -ScriptBlock {
            if ($buttonGrid) { $buttonGrid.Visibility = "Hidden"; }
            if ($progressGrid) { $progressGrid.Visibility = "Visible"; }
            if ($progressBar) { $progressBar.Value = 0; }
        };
        [int]$ticks = 100 / $stepAction.Count;
        foreach ($action in $stepAction) {
            $action.Invoke() | Out-Null;
            #pause;
            $progress += $ticks;
            Invoke-ControlDispatcher -Control $Window -ScriptBlock {
                if ($progressBar) { $progressBar.Value = $progress; }
            };
            Write-Verbose "Progress: $progress%"
        }

        Write-Verbose "Re-enabling Buttons"
        Invoke-ControlDispatcher -Control $Window -ScriptBlock {
            if ($StepIndex -eq $Steps.Count-1) { 
                $backButton.IsEnabled = $false; 
            }
            if ($progressGrid) { $progressGrid.Visibility = "Hidden"; }
            if ($buttonGrid) { $buttonGrid.Visibility = "Visible"; }
        };
        
    }

    return $stepIndex;
}
