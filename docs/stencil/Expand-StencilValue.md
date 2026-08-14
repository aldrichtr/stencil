---
external help file: stencil-help.xml
Module Name: stencil
online version: https://github.com/aldrichtr/stencil/main/blob/docs/stencil/Expand-StencilValue.md
schema: 2.0.0
---

# Expand-StencilValue

## SYNOPSIS

Expand any variables in the given string

## SYNTAX

```powershell
Expand-StencilValue [-Value] <String[]> [[-Data] <Object>] [<CommonParameters>]
```

## DESCRIPTION

`Expand-StencilValue` is a *private* function in the `stencil` module.  It is used when processing the text contained in
[stencil files](about_stencil_syntax).  The primary purpose is to allow for variable replacement in the definitions,
such as environment variable values and path shortcuts. The variable "tokens" are written similar to snippets, like
`${<name>}` within the `Value` string(s).  Each token will be replaced with the value from the `Data` table, any tokens
not found in the data will not be processed and will still be present in the result.  Additionally, `Expand-StencilValue
will expand any PowerShell variables in the `Value`, such as `$env:LOCALAPPDATA`, `~`, `$PSVersionTable.Platform`, etc.

## EXAMPLES

### EXAMPLE 1 Expand Tokens in a string

```powershell
Expand-StencilValue "Hello ${env.UserName}" -Data @{ env = @{ UserName = 'Bob'; Age = 44 }}
```

Hello Bob

### EXAMPLE 2 Expand Tokens and variables

```powershell
"Hello ${env.UserName}, you are in $PWD" | Expand-StencilValue  -Data @{ env = @{ UserName = 'Bob'; Age = 44 }}
```

Hello Bob, you are in c:\Users\Bob\Documents

## PARAMETERS

### -Data

Optionally provide a data table to use in replacing variables

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value

The string to be expanded

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

[String]

## OUTPUTS

[String]

## NOTES

## RELATED LINKS
