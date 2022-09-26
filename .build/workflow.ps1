
#synopsis: Configure the environment for development
task Configure {},
    install_dependencies,
    create_directories

#synopsis: Reset the environment
task Clean {},
    remove_modules,
    remove_clean_items

#synopsis: Display helpful content about the build
task Help {},
    output_help_instructions,
    output_help_task_tree

#synopsis: Run the unit tests for the project
task UnitTest {},
    build_staging_module,
    run_unit_tests

task Docs {},
    build_staging_module,
    new_markdown_help

task Stage {},
    build_staging_module,
    copy_source_items,
    update_markdown_help

#synopsis: Assemble the source files into a powershell module
task Build {},
    build_module,
    copy_source_items,
    update_markdown_help,
    stage_external_help

#synopsis: Install the modules
task Install {},
    register_local_repo,
    install_modules_currentuser,
    unregister_local_repo

#synopsis: Create an official release of the modules
task Release {},
    Stage,
    register_local_repo,
    generate_nuget_package,
    unregister_local_repo
