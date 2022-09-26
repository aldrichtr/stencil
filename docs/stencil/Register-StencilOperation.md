---
external help file: stencil-help.xml
Module Name: stencil
online version: /main/blob/C:\Users\taldrich\projects\github\stencil/docs/stencil/Register-StencilOperation.md
schema: 2.0.0
---

# Register-StencilOperation

## SYNOPSIS
Add a DSL word to the Stencil workflow

## SYNTAX

### Command (Default)
```
Register-StencilOperation [-Name] <String> [[-Command] <String>] [[-Description] <String>] [-Passthru] [-Force]
 [<CommonParameters>]
```

### ScriptBlock
```
Register-StencilOperation [-Name] <String> [[-ScriptBlock] <ScriptBlock>] [[-Description] <String>] [-Passthru]
 [-Force] [<CommonParameters>]
```

## DESCRIPTION
Register a DSL word (-Name) that maps to a Command or Scriptblock for use in stencil workflows

## EXAMPLES

### EXAMPLE 1
```
Register-StencilOperation -Name copy -Command Copy-Item -Description "Copy items from Path to Destination"
```

### EXAMPLE 2
```
Register-StencilOperation -Name 'read' -ScriptBlock { param($options)
   Set-Variable -Name $options.Name -Value (Read-Host $options.Prompt)
} -Description "Read a value from the user"
```

## PARAMETERS

### -Command
The Command that the operation calls

```yaml
Type: String
Parameter Sets: Command
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
An optional description

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Optionally overwrite an existing Operation

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of the Operation for use in stencils

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Passthru
Optionally return the registered operation

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptBlock
The scriptblock the operation calls

```yaml
Type: ScriptBlock
Parameter Sets: ScriptBlock
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
