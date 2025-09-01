#requires -RunAsAdministrator

# 2025/9/1 - Adapted from the original Vogons MW2 installer script by Myne

function Find-MW2Disc {
    [CmdletBinding()]
    param(
        [hashtable]$Editions
    )


    $inipaths="product.ini","splash\product.ini"       #location of product.ini on cdrom. Two are known so far.
    #$editionTable = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "discs.psd1");
    return @(
        $cdrom = Get-WmiObject Win32_CDROMDrive;
        foreach ($letter in $cdrom.drive) {
            #get the disk that corrosponds to the current letter
            Write-Verbose "Drive: $letter"
            $cdlabel=Get-Volume -driveletter $letter.trim(":")
            #get the label of the cd corrosponding to the current letter
            $cdlabel=$cdlabel.FileSystemLabel
            #get rid of spaces before/after
            $cdlabel="$cdlabel".trim()
            #this part gets the productid and productname from the product.ini
            #So far, there are two known locations of it which are set above in $inipaths.
            #there are also two spellings of productid and possibly name. Note the "[space] *"
            foreach ($path in $inipaths) {   
                if (Test-Path ("$letter\$path")) {
                    $ProductID=Get-Content "$letter\$path" | Select-String "^Product *ID=" | Select-Object -ExpandProperty Line
                    $ProductID=($ProductID -split "=" | Select-Object -Skip 1)
                    $ProductName="$ProductId".trim()
                    $ProductName=Get-Content "$letter\$path" | Select-String "^Product *name=" | Select-Object -ExpandProperty Line
                    $ProductName=($ProductName -split "=" | Select-Object -Skip 1)
                    $ProductName="$ProductName".trim()
                }
            } #endforeach
            #this is where we decide which of the following "edition sections" to run. 
            #First we're combining the cd's volume label with the product.ini's productid and product name so that we can hopefully get the granularity we might need.
            #there are apparently nearly 40 editions so... hopefully this is enough to separate them all if they need different approaches.

            $discKey = "$cdlabel-$ProductID-$ProductName"
            if ($Editions.ContainsKey($discKey)) {
                Write-Verbose "Found edition: $($Editions[$discKey]) ($discKey)"
                [pscustomobject]@{
                    CDDrive = $letter
                    Edition = $Editions[$discKey]
                    CDLabel = $cdlabel
                    ProductName = $ProductName
                }
            }
        } #end foreach
    ); 
}

function Get-MW2Edition {
    [CmdletBinding()]
    param(
        [object]$Disc,
        [hashtable]$IniFile
    )
    #$CDDRIVE = $Disc.CDDrive;
    #These ARE used...
    $dxwmw2icon="0000010001002020100000000000E802000016000000280000002000000040000000010004000000000080020000000000000000000000000000000000000000000000008000008000000080800080000000800080008080000080808000C0C0C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0000000000000000000000000000000000000008827007770000827002277000000000008227722000000872777700000000000000007200000000870000000000000000000B27200000027290000000000000000009777B00009772B000000000000000000B29790000B7C290000000000000000009707B000092C7B000000000000000000B82290000B2279000000000000000000087700000087200000000000000000000082000000820000000000000000000000820000008700000000000002700000227700000087220000072000872700082727000000777220002722008007000827777277227727200080070020020002772888888888777000800200827700008800777772008700002777000870000000000727700000000008200000700000000282277220000000070000009B00000008982777200000009B000000B92002208888877777022002B9000000087227708ECC77CCC707722270000000008722708EEE88CCC707777700000000000887708EE7EE2CC2027270000000000000022708E7EE8C207220000000000008772277708EEEE80727777270000000082009097728888277909007700000000870909020888888070909077000000008290909700000000890909720000000087777727000000008777777200000000888888880000000087227277000000000000000000000000000000000000F001800FF001800FF803C01FFC07E03FFF0180FFFF0180FFFF0180FFFF0180FFFF0180FFFF0180FFFF83C1FF8703C0E10203C04002000040020000400200004002000040031008C083E007C1C0000003C0000003C0000003F0000007F800000FE0000007E0000007E2000047E0000007E0000007E007E007E007E007E007E007"
    $dxwgblicon="0000010001002020100000000000E802000016000000280000002000000040000000010004000000000080020000000000000000000000000000000000000000000000008000008000000080800080000000800080008080000080808000C0C0C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0088F8F888088F80088778FF8FFFF7FF7F0FFFF8FF8F8707FF8F8478F0787F8F8F0FFFFF07F8008F8708FF707F0888880F0FFF78FF707FF707707FF808F7F0F70F4FF788F707FFF0788708FF877F044F4F44008F718F8F803777078FFF77F84FFF040FF738FFFF700770008FFFF77FF06FF04F70FFFF88000000008FFFFF77F74FF0F708FFFF87000000007FFFFFF87F0F0F008888FF80000000007FFFF88F77F0F878FFFFF8F3000000000788FFFFF80F707FFFFF888300000000778FFFFFFF70007FFFF888700000000078FFFFFFFF70707FFFFFF8700000000007FFFFFFFF77707FFFFFFF800878878707FFFFFFF87FF77FFF88FF8007777777078FFFFFF77FF808FF8FFF800088787007FFFFFFF78FFF08FFFFFF7078F87FF877FFFFFF8788FF77FFFF8877F877077F87FFFFFF87F7FF808FFF8877F7000008888FFFFF77F0F8F07FFF8F808700000F78FF887878F880F70FF8FFF1770477787888888870F8F7F808F88F800777777778FFFFF84F0FF77F07F888F8088888878FFFFFF77F4F668708F8FF873000040788FFFFF7748440F878FFFF7000777700007FF87777F4F0F7767FF800000777000007F80777F0F0F7770FF807888FFF887777F80777F0F0F87707FFFFFFFF8FFFF8FFF73870F6004F7788FFFFFFF7778FFFFF88888F74046F007837888867F0707877788FFF07000008788777788FF8E70777FFFFFF61FFF00FFFFFE007FFFF8003FFFF0000FFFE00007FFC00003FF800001FF000000FE0000007E000000380000003800000018000000180000001800000018000000180000001C0000003C0000003C0000003E0000003E0000007F0000007F0000007F0000007E0000003E0000003E0000003E0000007F0000007F800C00FFF83E0FF"
    $dxwMercsicon="0000010001002020100000000000E802000016000000280000002000000040000000010004000000000080020000000000000000000000000000000000000000000000008000008000000080800080000000800080008080000080808000C0C0C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000000000700000000700000000000000000000007000000007000000000000000000000070000000070000000000000000000000700777700700000000000000000000077070000000000000000000000000070707077077700000000000000000007700000770777700007000000000000000000700000077007077000000000000000007077770077000770000000000000000077000007777700000000000000000077777000077777707000000000000007777770007777007070000000000000770007700077000000070000000000007000000000700000070000000000000700000000000000000700000000000000770000007000000077000000000000007777000770000777700000000000000000777777707770007000000000000000000777777000000000000000000000700007777777777770000000000000000700077777777777770077000000000777000777788877777770777000000077770077778888888777777777000007770070777787778887770700777000777000007787777888877000007770007770000077787777888770000007770077000000077777788877000000007700700000000007777777000000000077707000000000000077000000000000077077000000000000000000000000000700770000000000000000000000000077000700000000000000000000000000800FFDFEFFFFFCFCFFFFFCFCFFFFFC007FFFF0003FFFE0000FFFC00007FFC00003FF800003FF800003FF800003FF800003FF800001FF800001FF800001FF800001FF800001FF800001FF000000FE0000007C0000007800000038000000102000041060000E00F0001F01F8003F03FE007F83FFE7FFC1FFFFFFC9FFFFFF9DFFFFFFB"

    #$editions = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "editions.psd1");

    $edition = $IniFile[$Disc.Edition];
    $edition.dxwicon = (Get-Variable -Name $edition.dxwicon).Value; # <-- Right here

    return $edition;
}

function Get-MW2InstallVariables {
    [CmdletBinding()]
    param (
        [object]$Disc,
        [string[]]$Root
    )

    return @{
        CDDrive = $Disc.CDDrive;
        commonfiles = "$Root\common";
        titFixes = "$Root\MW2Tit";
        _11mw2patch = "$Root\11mw2patch";
        _11gblpatch = "$Root\11gblpatch";
        _11merpatch = "$Root\11merpatch";
        _3dfxpatch = "$Root\3dfxpatch";
        compatibilitypath = "$Root\compatpatch";
        subfolders = "GIDDI", "KEATING", "SMK", "MEK", "HELP", "LAUNCH", "SPLASH"
    }   
}

function Remove-EmptyAndUnneeded([hashtable]$Edition, [string]$InstallPath) {
    #tidy empty directories
    $dirs = Get-ChildItem $InstallPath -Directory -Recurse `
            | Where-Object { (Get-ChildItem $_.fullName).Count -eq 0 } `
            | Select-Object -ExpandProperty FullName
    $dirs | ForEach-Object { 
        Remove-Item $_
    }

    #delete files if required
    if ($null -eq $Edition.delfiles) {
        foreach ($file in $Edition.delfiles) {
            Remove-Item "$InstallPath\$file" -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-MW2InstallSteps {
    [CmdletBinding()]
    param (
        [hashtable]$Variables
    )
    $Script:CDDrive=$Variables.CDDrive
    $Script:commonfiles=$Variables.commonfiles
    $Script:titFixes=$Variables.titFixes
    $Script:11mw2patch=$Variables._11mw2patch
    $Script:11gblpatch=$Variables._11gblpatch
    $Script:11merpatch=$Variables._11merpatch
    $Script:3dfxpatch=$Variables._3dfxpatch
    $Script:compatibilitypath=$Variables.compatibilitypath
    $Script:subfolders=$Variables.subfolders

    #Write-Host ($Variables | ConvertTo-Json)
    #Write-Host ($Edition | ConvertTo-Json)

    return @(
        { $Script:InstallPath = $window.FindName("InstallPath").Text }

        {
            
            if (!(Test-Path $Script:InstallPath)) {
                Write-ActionLog $window "Creating install path"
                New-Item -Path $Script:InstallPath -ItemType Directory -Force | Out-Null
            }
            Write-ActionLog $window "Install path is ready"
        }


        {    
            #make subfolders in installpath
            Write-ActionLog $window "Creating subfolders in $Script:InstallPath"
            foreach ($subs in $Script:subfolders) {
                try {
                    New-Item -Path $Script:InstallPath\$subs  -ItemType directory -ErrorAction Stop
                } 
                catch [System.IO.IOException] {
                   
                }
            }
        }
        {
            #copyfolders
            foreach ($folder in $edition.copyfolders) {
                Write-ActionLog $window "Copying $folder"
                Copy-Item -Path "$Script:CDDrive\$folder\" -Destination "$Script:InstallPath" -Force -Recurse -PassThru | ForEach-Object { Write-ActionLog $window $_.Fullname }
            #        xcopy /s /y /h "$Script:CDDrive\$folder" "$Script:InstallPath\$folder\"
            }
        }
        {
            foreach ($folder in $edition.copyotherfolders) {
                Write-ActionLog $window "Copying $folder"
                Copy-Item -Path "$Script:CDDrive\$folder\*" -Destination $Script:InstallPath -Force -Recurse -PassThru | ForEach-Object { Write-ActionLog $window $_.Fullname }
                #xcopy /s /y /h $folder $Script:InstallPath
            }
        }
        {
            # copy individual files
            if (![string]::IsNullOrWhiteSpace($edition.copyfiles)) {
                Write-ActionLog $window "Copying individual files"
                foreach ($file in $edition.copyfiles) {
                    #write-host $file
                    Copy-Item -Path $Script:CDDrive\$file -Destination $Script:InstallPath -force -PassThru | ForEach-Object { Write-ActionLog $window $_.Fullname }
                    #xcopy /y /h $Script:CDDrive\$file $Script:InstallPath
                }
            }
        }
            #fix attributes if necessary. GBL 95 may or may not need this but might as well anyway.
        {   
            Write-ActionLog $window "Fixing file attributes"
            Get-ChildItem $Script:InstallPath -Recurse | ForEach-Object {$_.Attributes = 'Normal'}  # <-- This is what you really want to do }
        }
        {
            #copy commonfile
            if ($edition.copycommonfiles -eq $true) {
                Write-ActionLog $window "Copying common files"
                Copy-Item -path "$Script:commonfiles\*.*"  -Destination $Script:InstallPath -force -PassThru | ForEach-Object { Write-ActionLog $window $_.Fullname }
            #    xcopy /y $Script:commonfiles $Script:InstallPath
            }
        }
        {
            #copy titaniumfixes
            if ($edition.copytitfixes -eq $true) {
                Write-ActionLog $window "Copying titanium fixes"
                Copy-Item -path "$Script:titFixes\*.*"  -Destination $Script:InstallPath -force -PassThru | ForEach-Object { Write-ActionLog $window $_.Fullname }
                #xcopy /y $Script:titFixes $Script:InstallPath
            }
        }
        {
            #copy 1.1 mw2 patch
            if ($edition.copy11mw2patch -eq $true) {
                Write-ActionLog $window "Copying 1.1 MW2 patch"
                Copy-Item -Path "$Script:11mw2patch\*.*"  -Destination $Script:InstallPath -force -PassThru | ForEach-Object { Write-ActionLog $window $_.Fullname }
                #Xcopy /y $Script:11mw2patch $Script:InstallPath
            }
        }
        {
            #copy 1.1 gbl patch
            if ($edition.copy11gblpatch -eq $true) {
                Write-ActionLog $window "Copying 1.1 GBL patch"
                Copy-Item -Path "$Script:11gblpatch\*.*"  -Destination $Script:InstallPath -force -PassThru | ForEach-Object { Write-ActionLog $window $_.Fullname }
                #Xcopy /y $11gblpatch $Script:InstallPath
            }
        }
        {
            #copy 1.1 mer patch
            if ($edition.copy11merpatch -eq $true) {
                Write-ActionLog $window "Copying 1.1 mercs patch"
                Copy-Item -Path "$Script:11merpatch\*.*"  -Destination $Script:InstallPath -force -PassThru | ForEach-Object { Write-ActionLog $window $_.Fullname }
                #Xcopy /y $11merpatch $Script:InstallPath
            }
        }
        {
            #copy 3dfx patch
            if ($edition.copy3dfxpatch -eq $true) {
                Write-ActionLog $window "Copying 3dfx patch"
                Copy-Item -Path "$Script:3dfxpatch\*.*" -Destination $Script:InstallPath -force -PassThru | ForEach-Object { Write-ActionLog $window $_.Fullname }
                #Xcopy /y $Script:3dfxpatch $Script:InstallPath
            }
        }
        {
                #copy the ex_, rename to exe and remove readonly (cds are readonly). xcopy doesn't work because it's renaming it too
            if (![string]::IsNullOrWhiteSpace($edition.cdexe)) {
                Write-ActionLog $window "Copying $Script:CDDrive\$($edition.cdexe) to $Script:InstallPath\$($edition.renameexename)"
                Copy-Item "$Script:CDDrive\$($edition.cdexe)" "$Script:InstallPath\$($edition.renameexename)" -PassThru | Set-ItemProperty -Name IsReadOnly -Value $false
            }
        }
        {
            If ($edition.movehelp -eq $true) {
                Write-ActionLog $window "Moving help files to $helppath"
                $helppath=$Script:InstallPath + "\Help"
                Move-Item $Script:InstallPath\*.hlp $helppath -Force
                Move-Item $Script:InstallPath\*.cnt $helppath -Force
                Move-Item $Script:InstallPath\help.exe $helppath -Force
            }
        }
        {
            #rename exe
            if ($edition.origexe -ne $($edition.renameexename)) {
                Write-ActionLog $window "Renaming $($edition.origexe) to $($edition.renameexename)"
                if (Test-Path ("$Script:InstallPath\$($edition.renameexename)")) {
                    Remove-Item $Script:InstallPath\$($edition.renameexename)
                }
                Rename-Item $Script:InstallPath\$($edition.origexe) $($edition.renameexename)
            }

        }
        {
            if ($copydirectplay -eq $true) {
                Write-ActionLog $window "Copying DirectPlay DLL"
                Copy-Item -Path "$Script:CDDrive\directx\dplay.dll"  -Destination $Script:InstallPath -Force
                #xcopy /y "$Script:CDDrive\directx\dplay.dll" $Script:InstallPath
            }
        }
        {
            if (![string]::IsNullOrWhiteSpace($edition.compatpatch)) {
                Write-ActionLog $window "Executing compatibility patch"
                Copy-Item "$Script:compatibilitypath\$($edition.compatpatch)" "$Script:InstallPath\" -Force
                sdbinst.exe -q $Script:InstallPath\$($edition.compatpatch)
            }
        }
        {
            #Edit the dxwnd ini file to the path the user chose and version
            Write-ActionLog $window "Editing ini file"
            $inifile=$Script:InstallPath+"\dxwnd.ini"
            
            #exe full path and name
            $repline="Path0=$Script:InstallPath"+"\"+"$($edition.renameexename)"
            $line = Get-Content $inifile | Select-String "^path0" | Select-Object -ExpandProperty Line
            (Get-Content $inifile) -replace "^$line", "$repline" | Set-Content $inifile
            
            #Name of edition
            $repline="title0=$($edition.title)"
            $line = Get-Content $inifile | Select-String "^title0" | Select-Object -ExpandProperty Line
            (Get-Content $inifile) -replace "$line", "$repline" | Set-Content $inifile
            
            #icon in dxwnd
            $repline="icon0=$($edition.dxwicon)"
            $line = Get-Content $inifile | Select-String "^icon0" | Select-Object -ExpandProperty Line
            (Get-Content $inifile) -replace "^$line", "$repline" | Set-Content $inifile
        }
        {
            #create desktop shortcut
            Write-ActionLog $window "Creating desktop shortcut"
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\" + $edition.title +".lnk")
            $Shortcut.TargetPath = ("$Script:InstallPath"+"\dxwnd.exe")
            $Shortcut.Arguments= "/Q /R:1"
            $Shortcut.IconLocation = $Script:InstallPath+"\"+$edition.shortcuticon
            $Shortcut.WorkingDirectory=$Script:InstallPath
            $Shortcut.Save()
        }
        {
            Write-ActionLog $window "Creating launch script"
            'Start-Process -FilePath "$PSScriptRoot\dxwnd.exe" -ArgumentList  "/Q","/R:1"' | Out-File "$Script:InstallPath/launch-mw2.ps1" -Force;
            
        }
        {
            Write-ActionLog $window "Creating uninstall script"
            "Remove-Item `"$Script:InstallPath`" -Recurse -Force -ErrorAction SilentlyContinue;`n" + `
            "Remove-Item `"`$Home\Desktop\$($edition.title).lnk`" -Force;`n" +
            "Remove-Item `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)`" -Recurse -Force -ErrorAction SilentlyContinue" | Out-File "$Script:InstallPath/uninstall-mw2.ps1" -Force;

            if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)") {
                Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        {
            Write-ActionLog $window "Creating uninstaller registry entries"
            $pwsh = if ($Host.Version -ge [version]"6.0") { "pwsh" } else { "powershell" };
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)" -Force | Out-Null
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)" -Name "DisplayName" -Value "$($edition.title)" -Force | Out-Null
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)" -Name "UninstallString" -Value "$pwsh `"$Script:InstallPath\uninstall-mw2.ps1`"" -Force | Out-Null
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)" -Name "Publisher" -Value "Vogons" -Force | Out-Null
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)" -Name "Version" -Value "1.0" -Force | Out-Null
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)" -Name "InstallLocation" -Value $Script:InstallPath -Force | Out-Null
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($edition.id)" -Name "DisplayIcon" -Value "$Script:InstallPath\$($edition.shortcuticon)" -Force | Out-Null

        }
        {
            Remove-EmptyAndUnneeded -Edition $Edition -InstallPath $Script:InstallPath;
        }
    );
}


