Add-Type -AssemblyName PresentationFramework;
# For things to work correctly in Windows Powershell, some Windows Forms components, like dialogs, are still needed.
Add-Type -AssemblyName System.Windows.Forms;

function Import-Xaml {
    [CmdletBinding()]
    param (
        [string]$Path
    )
    $xaml = Get-Content $Path -Raw;
    $reader = New-Object System.Xml.XmlNodeReader([xml]$xaml);
    $xamlObject = [Windows.Markup.XamlReader]::Load($reader);
    return $xamlObject
}

function Wait-DispatcherEvents {
    [CmdletBinding()]
    param ()
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    [void]([System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [System.Windows.Threading.DispatcherOperationCallback]{
            param($f) $f.Continue = $false; $null
        },
        $frame
    ))
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}


function Invoke-ControlDispatcher {
    [CmdletBinding()]
    param (
        [object]$Control,
        [scriptblock]$ScriptBlock
    )

    if ($Control.Dispatcher) {
        $Control.Dispatcher.Invoke($ScriptBlock);
    }
    Wait-DispatcherEvents;
}