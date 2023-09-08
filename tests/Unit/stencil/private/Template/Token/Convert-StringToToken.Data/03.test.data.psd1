@{
    Description = 'Test the indent'
    Enabled = $true
    # -- Data
    Count  = 2
    Tokens = @(
        @{
            Index               = 0
            Type                = 'ELMT'
            Start               = @{
                Index = 4
                Line = 0
                Column = 4
            }
            End                 = @{
                Index = 28
                Line = 0
                Column = 28
            }
            #
            Prefix              = ''
            Indent              = '    '
            Content             = " This is an element "
            RemainingWhiteSpace = ''
            Suffix              = ''
            #
            RemoveIndent        = $false
            RemoveNewLine       = $false
        },
        @{
            Index               = 1
            Type                = 'TEXT'
            Start               = @{
                Index  = 29
                Line   = 0
                Column = 29
            }
            End                 = @{
                Index  = 51
                Line   = 0
                Column = 51
            }
            #
            Prefix              = ''
            Indent              = ''
            Content             = " This is a basic test`r`n"
            RemainingWhiteSpace = ''
            Suffix              = ''
            #
            RemoveIndent        = $false
            RemoveNewLine       = $false
        }
    )
}
