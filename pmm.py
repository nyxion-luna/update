#!/usr/bin/env python3
import subprocess
import argparse
import sys

version = '2.0.0-beta.1'
parser = argparse.ArgumentParser(
    prog='pmm',
    description='Update your packages without the hassle of juggling fifteen different managers.',
)

parser.add_argument(
    '-n',
    '--dry-run',
    help='run the script without making any changes to the system',
    action='store_true',
)
parser.add_argument(
    '-y',
    '--yes',
    help='automatically update without asking for verification, assuming yes',
    action='store_true',
)
parser.add_argument(
    '--no-sudo',
    help='skips all package managers that require sudo',
    action='store_true',
)
parser.add_argument(
    '--version', help='print the program version and exit', action='store_true'
)
parser.add_argument(
    'managers', nargs='*', help='package managers to update (apt, flatpak, etc.)'
)

args = parser.parse_args()

if args.version:
    print(f'pmm, version {version}')
    sys.exit(0)

print(args)

args.managers = list(dict.fromkeys(args.managers))
for manager in args.managers:
    match manager:
        case 'apt':
            sudo = subprocess.run(['sudo', '-v'])
            if sudo.returncode != 0:
                print('Skipping apt: failed sudo verification.')
                continue
            aptupdate = subprocess.run('sudo apt-get update', shell=True)
            if aptupdate.returncode != 0:
                print("Skipping apt: error while executing 'sudo apt-get update'.")
                continue

            upgradableshell = subprocess.run(
                'apt-get -o "APT::Get::Show-User-Simulation-Note=false" --quiet --quiet --simulate upgrade | grep ^Inst',
                capture_output=True,
                text=True,
                shell=True,
            )

            upgradable = upgradableshell.stdout.split('\n')

            packages = []
            for line in upgradable:
                splitline = line.split(' ')
                packages.append(
                    [
                        splitline[1],
                        splitline[2].replace(']', '').replace('[', ''),
                        splitline[3].replace('(', ''),
                    ]
                )
