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
                Line = 1
                Column = 5
            }
            End                 = @{
                Index = 27
                Line = 1
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
                Index  = 28
                Line   = 1
                Column = 29
            }
            End                 = @{
                Index  = 50
                Line   = 1
                Column = 50
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
