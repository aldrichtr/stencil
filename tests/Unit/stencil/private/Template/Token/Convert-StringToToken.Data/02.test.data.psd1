@{
    Description = 'An element and some tex on one line'
    Enabled = $true
    # -- Data
    Count  = 2
    Tokens = @(
        @{
            Index               = 0
            Type                = 'ELMT'
            Start               = @{
                Index = 0
                Line = 1
                Column = 1
            }
            End                 = @{
                Index = 23
                Line = 1
                Column = 24
            }
            #
            Prefix              = ''
            Indent              = ''
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
                Index  = 24
                Line   = 1
                Column = 25
            }
            End                 = @{
                Index  = 46
                Line   = 1
                Column = 46
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
