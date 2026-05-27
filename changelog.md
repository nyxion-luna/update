# Changelog

## 1.0.0

- dropped support for --quiet and --verbose until further notice
- implemented --yes flag
- renamed some variables to match format used everywhere else
- deprecated --log= in favour of shell redirection (update apt >> file.log)

## 0.4.0

- fixed list rendering without newlines since 0.3.2
- modified heading format
- implemented --dry-run flag

## 0.3.2

- moved global variables to the start of the script, alongside version number variable
- fixed bug where you could check the same manager multiple times
- fixed bug where you'd still be asked whether you wanted to update if there were no updates
- made the list into a variable that gets printed at the end of _pmm_list_packages
- added header to distinguish operations
- moved listing to per-package temporarily. will be moved back down once the rewrite is complete
- improved handling for _pmm_list_packages exiting

## 0.3.1

- fixed exit code handling with _pmm_list_packages to not overlap with existing code meanings

## 0.3.0

- moved listing logic into a separate function
- added function for printing log messages with color quickly
- removed old and unnecessarily complex flag handling
- implemented extra checks for sudo verification and update command in apt
- implemented --no-sudo flag
- listing the packages now happens after checking all managers
- removed unimplemented managers from the switch for manager checking
- renamed some variables to match format used everywhere else

## 0.2.1

- removed commented todo/reference from the bottom of the file
- fixed version flag not returning after being run
- modified the flag handling logic

## 0.2.0

- initial commit
