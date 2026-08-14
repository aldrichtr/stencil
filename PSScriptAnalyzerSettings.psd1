@{
  Severity            = @('Information', 'Warning', 'Error')

  IncludeDefaultRules = $true

  ExcludeRules        = @(
    'PSDSCDscExamplesPresent',
    'PSDSCDscTestsPresent',
    'PSDSCReturnCorrectTypesForDSCFunctions',
    'PSDSCUseIdenticalMandatoryParametersForDSC',
    'PSDSCUseIdenticalParametersForDSC',
    'PSDSCStandardDSCFunctionsInResource',
    'PSDSCUseVerboseMessageInDSCResource'
  )

  # IncludeRules          = @()
  # CustomRulePath        = @()
  # RecurseCustomRulePath = $true

  Rules               = @{
    # SECTION Braces
    PSPlaceOpenBrace                 = @{
      <# OTBS style #>
      Enable             = $true
      OnSameLine         = $true
      NewLineAfter       = $true
      IgnoreOneLineBlock = $true
    }
    PSPlaceCloseBrace                = @{
      Enable             = $true
      NoEmptyLineBefore  = $false
      IgnoreOneLineBlock = $true
      NewLineAfter       = $true
    }
    # !SECTION

    # SECTION Whitespace
    PSUseConsistentIndentation       = @{
      Enable              = $true
      Kind                = 'space'
      IndentationSize     = 2
      PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
    }
    PSUseConsistentWhitespace        = @{
      Enable                                  = $true
      CheckInnerBrace                         = $true
      CheckOpenBrace                          = $true
      CheckOpenParen                          = $true
      CheckOperator                           = $true
      CheckPipe                               = $true
      CheckPipeForRedundantWhitespace         = $true
      CheckSeparator                          = $true
      CheckParameter                          = $true
      IgnoreAssignmentOperatorInsideHashTable = $true
    }
    # !SECTION

    PSAlignAssignmentStatement       = @{
      Enable                                  = $true
      CheckHashtable                          = $true
      AlignHashtableKvpWithInterveningComment = $true
      CheckEnum                               = $true
      AlignEnumMemberWithInterveningComment   = $true
      IncludeValuelessEnumMembers             = $true
    }

    PSAvoidLongLines                 = @{
      Enable            = $true
      MaximumLineLength = 108
    }

    # SECTION Naming standards
    PSAvoidUsingCmdletAliases        = @{
      allowlist = @( 'task')
    }
    PSUseCorrectCasing               = @{
      Enable        = $true
      CheckCommands = $true
      CheckKeyword  = $true
      CheckOperator = $true
    }
    PSUseSingularNouns               = @{
      NounAllowList = @()
    }

    # !SECTION

    PSProvideCommentHelp             = @{
      Enable                  = $true
      ExportedOnly            = $false
      BlockComment            = $true
      VSCodeSnippetCorrection = $true
      Placement               = 'begin'
    }

    PSReviewUnusedParameter          = @{
      CommandsToTraverse = @()
    }

    PSUseConstrainedLanguageMode     = @{
      Enable           = $false
      IgnoreSignatures = $false  # Enforce full CLM compliance for all scripts
    }

    # SECTION Compatability Settings
    PSAvoidOverwritingBuiltInCmdlets = @{
      PowerShellVersion = @('core-6.1.0-windows')
    }
    PSUseCompatibleCmdlets           = @{
      compatibility = @('core-6.1.0-windows')
    }
    PSUseCompatibleCommands          = @{
      Enable         = $true
      TargetProfiles = @(
      )
      # You can specify commands to not check like this, which also will ignore its parameters:
      IgnoreCommands = @()
    }
    PSUseCompatibleSyntax            = @{
      Enable         = $true
      TargetVersions = @( '6.0', '5.1', '4.0')
    }
    PSUseCompatibleTypes             = @{
      Enable         = $true
      TargetProfiles = @(
        'ubuntu_x64_18.04_6.1.3_x64_4.0.30319.42000_core'
        'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
        'MyProfile'
        'another_custom_profile_in_the_profiles_directory.json'
        'D:\My Profiles\profile1.json'
      )
      # You can specify types to not check like this, which will also ignore methods and members on it:
      IgnoreTypes    = @(
        'System.IO.Compression.ZipFile'
      )
    }
    # !SECTION
  }
}
