@{
    Count  = 2
    Enabled = $true
    Tokens = @(
        @{
            Index               = 0
            Type                = 'ELMT'
            Start               = @{
                Index = 0
                Line = 0
                Column = 0
            }
            End                 = @{
                Index = 24
                Line = 0
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
        }
        @{
            Index               = 1
            Type                = 'TEXT'
            Start               = @{
                Index  = 25
                Line   = 0
                Column = 25
            }
            End                 = @{
                Index  = 46
                Line   = 0
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
