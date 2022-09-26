
#synopsis: Install the project's modules into the CurrentUser Scope
install_module install_modules_currentuser -Scope 'CurrentUser'

#synopsis: Uninstall the project's modules from the system
task uninstall_module {
    Uninstall-Module $Project.Name -AllVersions
}
