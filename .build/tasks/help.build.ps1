
#synopsis: Output instructions for buildtool
task output_help_instructions {
    $instructions = @(
        '.\.build\workflow.ps1 file instructions',
        '.build\config\*.build.ps1 file instructions',
        '.build\tasks\*.build.ps1 file instructions',
        '.build\tasks\*.task.ps1 file instructions'
    )

    foreach ($line in $instructions) {
        Write-Build White $line
    }
}

#synopsis: Output a tree view of the tasks with their synopsis
task output_help_task_tree {
    <#------------------------------------------------------------------
    "workflows" is an arbitrary concept.  If the task is defined in
    'workflow.ps1' then we consider that to be "top-level" tasks.  A
    workflow can have any amount of subtasks, but the concept is that:
    - A workflow defines a _process_ to be done
    - 'jobs' _do something_
    ------------------------------------------------------------------#>
    $all_tasks = @()

    foreach ($key in ${*}.All.Keys) {
        $task = ${*}.All[$key]
        $task | Add-Member -NotePropertyName Synopsis -NotePropertyValue (Get-BuildSynopsis $task)
        $task | Add-Member -NotePropertyName Workflow -NotePropertyValue (( $task.InvocationInfo.ScriptName -like "*workflow.ps1" ) ? $true : $false)
        $task | Add-Member -NotePropertyName File -NotePropertyValue (Get-Item $task.InvocationInfo.ScriptName)
        $task | Add-Member -NotePropertyName Line -NotePropertyValue $task.InvocationInfo.ScriptLineNumber
        $all_tasks += $task
    }

    Write-Build DarkBlue "A total of $($all_tasks.Count) tasks"

    foreach ( $wf in ($all_tasks | Where-Object -Property Workflow -EQ $true)) {
        Write-Build DarkGreen "$($wf.Name) - $($wf.Synopsis)"
        foreach ($j in $wf.Jobs) {
            $job = $all_tasks | Where-Object -Property Name -Like $j
            if ($null -ne $job) {
                Write-Build White (" - {0,-48} {1}" -f "$($job.Name) ($($job.File.BaseName -replace '\.build$', ''):$($job.Line))", $job.Synopsis)
            }
        }
        Write-Build White ''
    }
}
