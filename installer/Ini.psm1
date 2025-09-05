function Import-IniFile {
    [CmdletBinding()]
    param (
        [string]$Path
    )

    <#
        INI File Format       
        ```````````````````````````````````
        VALUE is *

        COMMENT is ;<VALUE>
        COMMENT is #<VALUE> 

        Comments are parsed, but ignored

        ARRAY is <VALUE>|<VALUE2>|...

        [<SECTION>]
        <KEY>=<VALUE or ARRAY><COMMENT?>

        this becomes:

        @{
            SECTION = @{
                KEY = VALUE
                    or
                KEY = @(
                    VALUE
                    VALUE2
                )
            }
        }
    #>
    $ini = @{}
    $valueTrimmer = { [string]$_.Trim('"').Trim() }
    switch -regex -file $Path
    {
        '^\[(.+)\]([;#].*)?$' # Section, optional comment
        {
            $section = $matches[1];
            $ini[$section] = [ordered]@{};
        }
        '^[;|#](.*)$' # Comment
        {
            # Ignore comments
        }
        '^\s*([^=;[]+?)\s*=\s*"?([^";\n\r]*)' # Key, optional comment
        {
            $name,$value = $matches[1..2]
            $name = $name.Trim('"').Trim();
            if ($value.Contains('|')) {
                $value = $value.Split('|') `
                         | ForEach-Object $valueTrimmer;
            } else {
                $value = $value | ForEach-Object $valueTrimmer `
                                | Select-Object -First 1;
            }

            $ini[$section][$name] = $value;
        }
    }
    return $ini
}

function Export-IniFile {
    [CmdletBinding()]
    param (
        [string]$Path,
        [hashtable]$InputObject
    )

    $iniContent = @()

    foreach ($section in $InputObject.Keys) {
        $iniContent += "[$section]"
        foreach ($key in $InputObject[$section].Keys) {
            $value = $InputObject[$section][$key]
            if ($value -is [array]) {
                $value = $value -join '|'
            }
            $iniContent += "$key=$value"
        }
    }

    Set-Content -Path $Path -Value $iniContent
}

function Find-KeyPattern {
    param (
        [string]$Pattern,
        [hashtable]$InputObject
    )
    foreach ($section in $InputObject.Keys) {
        foreach ($key in $InputObject[$section].Keys) {
            if ($key -match $Pattern) {
                return $InputObject[$section][$key];
            }
        }
    }
    return $null;
}
