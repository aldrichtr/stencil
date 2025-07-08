
using namespace System.Text

<#
write: Write a message to the console.
params: Message, Foreground, Background, Blink, Bold
#>

Register-StencilOperation 'write' {
    param($params)
    if (-not ([string]::IsNullOrEmpty($params.Message))) {
        $message = [StringBuilder]::new()
        $needsReset = $false
        if ($params.ContainsKey('Foreground')) {
            if ($null -ne $PSStyle.Foreground.($params.Foreground)) {
                [void]$message.Append($PSStyle.Foreground.($params.Foreground))
                $needsReset = $true
            }
        }
        if ($params.ContainsKey('Background')) {
            if ($null -ne $PSStyle.Background.($params.Background)) {
                [void]$message.Append($PSStyle.Background.($params.Background))
                $needsReset = $true
            }
        }
        if ($params.ContainsKey('Blink')) {
            [void]$message.Append($PSStyle.Blink)
            $needsReset = $true
        }
        if ($params.ContainsKey('Bold')) {
            [void]$message.Append($PSStyle.Bold)
            $needsReset = $true
        }
        [void]$message.Append($params.Message)

        if ($needsReset) {
            [void]$message.Append($PSStyle.Reset)
        }

        $options = @{
            Tags              = $params.Tags
            MessageData       = $message.ToString()
            InformationAction = 'Continue'
        }
        Write-Information @options
    }
} -Description 'Write a message to the console'
