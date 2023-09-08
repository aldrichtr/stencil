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
                Line = 0
                Column = 0
            }
            End = @{
                Index = 22
                Line = 0
                Column = 22
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
