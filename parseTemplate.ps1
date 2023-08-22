$templateName = '.\TestTemplate.pst1'

$content = Get-Content $templateName -Raw
$result = $content | Select-String '(?sm)(<%.*%>)' -AllMatches

result | Get-Member
