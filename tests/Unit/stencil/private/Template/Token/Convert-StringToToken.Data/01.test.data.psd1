@{
    Count  = 1
    Enabled = $true
    Tokens = @(
        @{
            Index               = 0
            Type                = 'TEXT'
            Start = @{
                Index = 0
                Line = 0
                Column = 0
            }
            End = @{
                Index = 22
                Line = 1
                Column = 0
            }
            #
            Prefix              = ''
            Indent              = ''
            Content             = "This is a basic test`r`n"
            RemainingWhiteSpace = ''
            Suffix              = ''
            #
            RemoveIndent        = $false
            RemoveNewLine       = $false
        }
    )
}
