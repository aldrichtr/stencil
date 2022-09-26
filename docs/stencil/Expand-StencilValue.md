---
external help file: stencil-help.xml
Module Name: stencil
online version: /main/blob/C:\Users\taldrich\projects\github\stencil/docs/stencil/Expand-StencilValue.md
schema: 2.0.0
---

# Expand-StencilValue

## SYNOPSIS
Expand any variables in the given string

## SYNTAX

```
Expand-StencilValue [-Value] <String[]> [[-Data] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Expand-StencilValue will replace tokens in the given string with the variable value if found

## EXAMPLES

### EXAMPLE 1
```
Expand-StencilValue "Hello ${env.UserName}"
```

Hello Bob

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

## OUTPUTS

## NOTES

## RELATED LINKS
