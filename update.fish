function update --description 'Update your packages without the hassle of juggling fifteen different managers'
    set -f update_version 0.2.1

    argparse n/dry-run y/yes q/quiet v/verbose no-sudo 'log=' version -- $argv

    if set -q _flag_version
        echo "update, version $update_version"
        return 0
    end

    if set -q _flag_dry_run
        set -f dry_run true
    end

    if set -q _flag_yes
        set -f yes true
    end

    if set -q _flag_quiet
        set -f quiet true
    end

    if set -q _flag_verbose
        set -f verbose true
    end

    if set -q _flag_no_sudo
        set -f no_sudo true
    end

    if set -q _flag_log
        set -f log _flag_log
    end

    for manager in $argv
        switch $manager
            case apt
                sudo -v || return 1
                sudo apt-get update

                # thanks to https://sleeplessbeastie.eu/2025/02/06/how-to-list-upgradeable-packages-with-apt-and-apt-get/ for this command
                set -f upgradable (string split \n (apt-get -o "APT::Get::Show-User-Simulation-Note=false" --quiet --quiet --simulate upgrade | grep ^Inst))

                # if there's no packages to upgrade, don't
                if test (count $upgradable) = 0
                    echo (set_color cyan)"No updates available."(set_color normal)
                    return 0
                end

                # get the values for the upgradable packages list
                set -f packages
                set -f oldversion
                set -f newversion
                for line in $upgradable
                    set -l splitline (string split ' ' $line)
                    set -a packages $splitline[2] # package names
                    set -a oldversion (string trim -c '[]' $splitline[3]) # the currently installed version
                    set -a newversion (string trim -c '(' $splitline[4]) # the installation candidate
                end

                # check that we have the same amount of each. 
                # otherwise the pkg list will be broken and something has to have gone wrong
                if not test (count $packages) -eq (count $oldversion) \
                        -a (count $packages) -eq (count $newversion)
                    return 1
                end

                # get the largest item in each to pad.
                # (newversion is the last one so it doesn't need any padding)
                set -f ppad 0
                set -f opad 0
                for i in (seq (count $packages))
                    if test (string length $packages[$i]) -ge $ppad
                        set -f ppad (string length $packages[$i])
                    end
                    if test (string length $oldversion[$i]) -ge $opad
                        set -f opad (string length $oldversion[$i])
                    end
                end
                # this sets some extra padding to make it look ok and not stuck together
                set -f ppad (math $ppad + 2)
                set -f opad (math $opad + 1)

                # header for the pkg list
                echo (set_color --bold)' '(string pad -r -w (math $ppad) 'Package')(string pad -r -w (math $opad + 3) 'Old')'New'(set_color normal)

                # print the pkg list
                for i in (seq (count $packages))
                    #        
                    echo ' '(string pad -r -w (math $ppad) $packages[$i])(string pad -r -w (math $opad) $oldversion[$i])"-> "$newversion[$i]
                end

                # does the user actually want to update?
                read -P (set_color cyan)"Would you like to update these apps? [Y/n]: "(set_color normal) -l confirm
                or begin # mainly for ctrl+c but this should catch most other things
                    echo (set_color cyan)"Exiting."(set_color normal)
                    return 1
                end
                # either y or n for updating. if unknown input given, exit
                switch $confirm
                    case Y y '' # default value is Y. if no input is given and enter is pressed read will return ''
                        echo (set_color cyan)"Updating."(set_color normal)
                        sudo apt-get upgrade -y || echo (set_color cyan)"Error while updating. Exiting."(set_color normal)
                    case N n
                        echo (set_color cyan)"Exiting."(set_color normal)
                        return 0
                    case "*"
                        echo (set_color cyan)"Unrecognized option."(set_color normal)
                        return 1
                end
            case flatpak
                # TODO: implement this manager
            case snap
                # TODO: implement this manager
            case dnf
                # TODO: implement this manager
            case pacman
                # TODO: implement this manager
            case brew
                # TODO: implement this manager
            case pip
                # TODO: implement this manager
            case npm
                # TODO: implement this manager
            case cargo
                # TODO: implement this manager
            case gem
                # TODO: implement this manager
            case nix
                # TODO: implement this manager
        end
    end
end
