
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

        # The index number of the token
        [Parameter(
        )]
        [int]$Index,

        # The spaces or tabs prior to the start tag
        [Parameter(
        )]
        [string]$Indent,

        # The content text of the token
        [Parameter(
        )]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Content,

        # The starting position of the template token in the original content
        [Parameter(
        )]
        [hashtable]$Start,

        # The ending position of the template token in the original content
        [Parameter(
        )]
        [hashtable]$End,

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

        $keywords = @(
            'include'
            'wrapper'
        )
    }
    process {
        Write-Debug "Received : $($PSBoundParameters | ConvertTo-Psd | Out-String)"
        if ([string]::IsNullorEmpty($Type)) {
            $Type = $DEFAULT_TYPE
        }
        if ($PSCmdlet.ShouldProcess($Name, 'Create new Stitch.TemplateToken')) {

            $tokenInfo = @{
                PSTypeName = "Stencil.TemplateToken.$(Format-TitleCase $Type)"
                Type       = (Format-UpperCase $Type)
                Index      = $Index ?? 0
                Start      = @{
                    Index  = 0
                    Line   = 0
                    Column = 0
                }
                End                 = @{
                    Index  = 0
                    Line   = 0
                    Column = 0
                }
                Length              = ($Content.Length) ?? 0
                Indent              = $Indent ?? ''
                Content             = $Content ?? ''
                RemainingWhiteSpace = $RemainingWhiteSpace
                Prefix              = $Prefix ?? ''
                Suffix              = $Suffix ?? ''
                # These may be set below after evaluating the Prefix and Suffix
                RemoveNewLine = $RemoveNewLine
                RemoveIndent  = $RemoveIndent
            }
            if ($PSBoundParameters.ContainsKey('Start')) {
                $TokenInfo.Start.Index  = $Start.Index
                $TokenInfo.Start.Line   = $Start.Line
                $TokenInfo.Start.Column = $Start.Column
            }
            if ($PSBoundParameters.ContainsKey('End')) {
                $TokenInfo.End.Index  = $End.Index
                $TokenInfo.End.Line   = $End.Line
                $TokenInfo.End.Column = $End.Column
            }


            #-------------------------------------------------------------------------------
            #region ! Parse content
            switch ($tokenInfo.Type) {
                'TEXT' {
                    # No processing of a Text chunk at this time
                    $tokenInfo = $tokenInfo | New-TextToken
                    continue
                }

                'ELMT' {
                    switch ($tokenInfo.Prefix) {
                        '#' {
                            if ($tokenInfo.Suffix -eq '#') {
                                $tokenInfo = $tokenInfo | New-CommentToken
                            }
                        }
                        '-' {
                            $tokenInfo.RemoveIndent = $true
                        }
                        # The Expression type is used to *evaluate* some chunk of powershell code,
                        # capture the output, and put that back into the output, such as
                        '=' {
                            $tokenInfo.Type       = 'STMT'
                            $tokenInfo.PSTypeName = 'Stencil.Template.ExpressionToken'
                        }
                    }

                    # Look for "special content"
                    switch -Regex ($tokenInfo.Content) {
                        '(?sm)---(?<fm>.*?)---' {
                            $tokenInfo.Type       = 'FMTR'
                            $tokenInfo.PSTypeName = 'Stencil.Template.FrontMatterToken'
                            $tokenInfo['YAML'] = $Matches.fm
                        }
                    }




                }
            }
            #endregion Parse content
            #-------------------------------------------------------------------------------



            Write-Debug "Creating Token $($tokenInfo.Index): TokenInfo :`n $($tokenInfo | ConvertTo-Psd | Out-String)"
            Write-Verbose "Creating Token $($tokenInfo.Index) -> $($tokenInfo.PSTypeName)"
            $token = [PSCustomObject]$tokenInfo

            # Insert the "Parent Class" name
            $token.PSObject.TypeNames.Insert(1, 'Stencil.Template.Token')

            $token | Write-Output
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
