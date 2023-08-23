
function New-TemplateToken {
    <#
    .SYNOPSIS
        Create a new 'Stencil.TemplateToken' object
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'low'
    )]
    param(
        # The type of Template token to create
        [Parameter(
        )]
        [string]$Type,

        # The content text of the token
        [Parameter(
        )]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Content,

        # The starting position of the template token in the original content
        [Parameter(
        )]
        [int]$Start,

        # The length of the token
        [Parameter(
        )]
        [int]$Length,

        # The instruction just after the start marker
        [Parameter(
        )]
        [string]$Prefix,

        # The instruction just before the end marker
        [Parameter(
        )]
        [string]$Suffix,

        # Remove the preceding whitespace
        [Parameter(
        )]
        [switch]$RemoveIndent,

        # Remove the trailing newline
        [Parameter(
        )]
        [switch]$RemoveNewLine,
        # any trailing whitespace
        [Parameter(
        )]
        [string]$RemainingWhiteSpace
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)"
        $constOptions = @{
            Option      = 'Constant'
            Name        = 'DEFAULT_TYPE'
            Value       = 'TEXT'
            Description = 'The default TemplateToken Type'
        }

        New-Variable @constOptions

        function Format-UpperCase {
            param([string]$Text)
            (Get-Culture).TextInfo.ToUpper($Text)
        }

        function Format-TitleCase {
            param([string]$Text)
            (Get-Culture).TextInfo.ToTitleCase($Text)
        }
    }
    process {
        Write-Debug "Received : $($PSBoundParameters | ConvertTo-Psd)"
        if ([string]::IsNullorEmpty($Type)) {
            $Type = $DEFAULT_TYPE
        }
        if ($PSCmdlet.ShouldProcess($Name, 'Create new Stitch.TemplateToken')) {

            $tokenInfo = @{
                PSTypeName          = "Stencil.TemplateToken.$(Format-TitleCase $Type)"
                Type                = (Format-UpperCase $Type)
                Start               = $Start ?? 0
                Length              = $Length ?? 0
                Content             = $Content ?? ''
                RemainingWhiteSpace = $RemainingWhiteSpace
                Prefix              = $Prefix ?? ''
                Suffix              = $Suffix ?? ''
                # These may be set below after evaluating the Prefix and Suffix
                RemoveNewLine       = $RemoveNewLine
                RemoveIndent        = $RemoveIndent
            }

            #-------------------------------------------------------------------------------
            #region Parse content
            switch ($tokenInfo.Type) {
                'TEXT' {
                    # No processing of a Text chunk at this time
                    continue
                }
                'EXPR' {
                    switch -Regex ($tokenInfo.Content) {
                        '(?sm)---(?<fm>.*?)---' {
                            $tokenInfo.Type = 'FMTR'
                            $tokenInfo.PSTypeName = 'Stencil.TemplateToken.Fmtr'
                        }
                    }
                }

            }
            #endregion Parse content
            #-------------------------------------------------------------------------------




            $token = [PSCustomObject]$tokenInfo
            #-------------------------------------------------------------------------------
            #region Calculate 'End'

            $scriptBody = {
                return ($this.Start + $this.Length)
            }
            $memberOptions = @{
                MemberType = 'ScriptProperty'
                Name       = 'End'
                Value      = $scriptBody
            }

            $token | Add-Member @memberOptions

            #endregion Calculate 'End'
            #-------------------------------------------------------------------------------
            $token
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
