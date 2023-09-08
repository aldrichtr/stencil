@{
    Description = 'Basic test with one line of text only'
    Enabled = $true
    # -- Data
    Count  = 1
    Tokens = @(
        @{
            Index               = 0
            Type                = 'TEXT'
            Start = @{
                Index = 0
                Line = 1
                Column = 1
            }
            End = @{
                Index = 21
                Line = 1
                Column = 21
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
