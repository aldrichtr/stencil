$cmd = 'reportgenerator'

$arglist = @(
'-reports:out\tests\*jacoco*.xml',
'-targetdir:out\coveragereport',
'-reporttypes:Html;'
'Html_Dark;',
'MarkdownSummaryGithub;',
'Badges',
'-sourcedirs:source\stencil',
'-historydir:docs\coverage'
)

& $cmd $arglist
