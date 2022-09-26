---
external help file: stencil-help.xml
Module Name: stencil
online version: /main/blob/C:\Users\taldrich\projects\github\stencil/docs/stencil/Get-Stencil.md
schema: 2.0.0
---

# Get-Stencil

## SYNOPSIS
Get all the stencils in the given path

## SYNTAX

```
Get-Stencil [[-Path] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
\`Get-Stencil\` returns a \`Stencil.JobInfo\` object for each job defined in the stencil manifests found in each
path given. 
If no paths are given, the Default.Directory from the configuration is used.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Path
Specifies a path to one or more locations.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: PSPath

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
