function update --description 'Update your packages without the hassle of juggling fifteen different managers'
    set -f _pmm_version 0.3.0

    function _pmm_print
        echo (set_color cyan)"$argv"(set_color normal)
    end

    function _pmm_list_packages
        if test (count $_pmm_pkgs) -eq 0
            _pmm_print 'No updates available.'
            return 2
        end

        if not test (count $_pmm_pkgs) -eq (count $_pmm_oldv) \
                -a (count $_pmm_pkgs) -eq (count $_pmm_newv)
            return 3
        end

        # get the largest item in each to pad.
        # (_pmm_newv is the last one so it doesn't need any padding)
        set -f ppad 0
        set -f opad 0
        for i in (seq (count $_pmm_pkgs))
            if test (string length $_pmm_pkgs[$i]) -ge $ppad
                set -f ppad (string length $_pmm_pkgs[$i])
            end
            if test (string length $_pmm_oldv[$i]) -ge $opad
                set -f opad (string length $_pmm_oldv[$i])
            end
        end
        # this sets some extra padding to make it look ok and not stuck together
        set -f ppad (math $ppad + 2)
        set -f opad (math $opad + 1)

        # header for the pkg list
        echo (set_color --bold)' '(string pad -r -w (math $ppad) 'Package')(string pad -r -w (math $opad + 3) 'Old')'New'(set_color normal)

        # print the pkg list
        for i in (seq (count $_pmm_pkgs))
            echo ' '(string pad -r -w (math $ppad) $_pmm_pkgs[$i])(string pad -r -w (math $opad) $_pmm_oldv[$i])"-> "$_pmm_newv[$i]
        end
    end

    argparse n/dry-run y/yes q/quiet v/verbose no-sudo 'log=' version -- $argv

    if set -q _flag_version
        echo "update, version $_pmm_version"
        return 0
    end


    set -g _pmm_pkgs
    set -g _pmm_oldv
    set -g _pmm_newv

    for manager in $argv
        switch $manager
            case apt
                if set -q _flag_no_sudo
                    _pmm_print 'Skipping apt: requires sudo.'
                    continue
                end
                sudo -v || begin
                    _pmm_print 'Skipping apt: failed sudo verification. '
                    continue
                end
                sudo apt-get update
                or begin
                    _pmm_print "Skipping apt: error while executing 'apt-get update'."
                    continue
                end

                # thanks to https://sleeplessbeastie.eu/2025/02/06/how-to-list-upgradeable-packages-with-apt-and-apt-get/ for this command
                set -f upgradable (string split \n (apt-get -o "APT::Get::Show-User-Simulation-Note=false" --quiet --quiet --simulate upgrade | grep ^Inst))

                # get the values for the upgradable packages list
                for line in $upgradable
                    set -l splitline (string split ' ' $line)
                    set -a _pmm_pkgs $splitline[2] # package names
                    set -a _pmm_oldv (string trim -c '[]' $splitline[3]) # the currently installed version
                    set -a _pmm_newv (string trim -c '(' $splitline[4]) # the installation candidate
                end
        end
    end

    _pmm_list_packages
    or begin
        set -l _pmm_status $status
        if test $_pmm_status -eq 2
            return 0
        else if test $_pmm_status -eq 3
            _pmm_print 'Error: mismatch in number of elements for packages list. Cannot display package list.'
        else
            return $_pmm_status
        end
    end
        
    # does the user want to update?
    read -P (set_color cyan)'Would you like to update these packages? [Y/n]: '(set_color normal) -l confirm
    or begin # mainly for ctrl+c but this should catch most other things
        _pmm_print 'Exiting.'
        return 1
    end

    # either y or n for updating. if unknown input given, exit
    switch $confirm
        case Y y '' # default value is Y. if no input is given and enter is pressed read will return ''
            _pmm_print 'Updating.'
            for manager in $argv
                switch $manager
                    case apt
                        sudo apt-get upgrade -y
                        or begin
                            _pmm_print 'Skipping apt update: error while updating.'
                            continue
                        end
                end
            end
        case N n
            _pmm_print 'Exiting.'
            return 0
        case "*"
            _pmm_print 'Unrecognized option.'
            return 1
    end
end
