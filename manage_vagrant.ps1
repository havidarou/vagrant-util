#------------------------- Gather parameters --------------------------#

param (
    [switch]$list,
    [string]$os = "ubuntu-18.04",
    [string]$base_path = "C:\Users\havidarou\",
    [string]$memory = "1024",
    [string]$cpu = "1",
    [string]$halt = "",
    [string]$ssh = "",
    [string]$name = "",
    [string]$destroy = ""
)

#------------------------- Gather parameters --------------------------#

# ------------------------- Common functions ------------------------- #

# Init vagrant file
function init
{
    $vagrantfile = '
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

    config.vm.box = "MY_FAMILY/MY_OS"
    config.vm.synced_folder ".", "/vagrant", type: "smb", smb_username:"havidarou", smb_password:"Hitojanaiyo32!"
    config.vm.define "VAGRANT_NAME"
    config.vm.hostname = "MY_NAME"
    config.vm.network "public_network", bridge: "Default Switch"

    config.vm.provider "hyperv" do |hv|
        hv.memory = "MY_MEMORY"
        hv.cpus = "MY_CPU"
        hv.vmname = "MY_NAME"
    end

end'
    return $vagrantfile
}

# Configure vagrant box
function configure
{
    $vagrantfile = init

    # Windows like system
    if ($os -like "*win*") {
        if ($os -eq "windows-2012") {
            $vagrantfile = $vagrantfile -replace 'MY_OS', "Windows2012R2"
            $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "mwrock"
        }
        if ($os -eq "windows-2008") {
            $vagrantfile = $vagrantfile -replace 'MY_OS', "win-2008r2-standard-amd64-nocm"
            $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "opentable"
        }
        if ($os -eq "windows-8") {
            $vagrantfile = $vagrantfile -replace 'MY_OS', "windows-8-professional-x64"
            $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "universalvishwa"
        }
        if ($os -eq "windows-7") {
            $vagrantfile = $vagrantfile -replace 'MY_OS', "win-7-enterprise"
            $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "senglin"
        }
        if ($os -eq "windows-10") {
            $vagrantfile = $vagrantfile -replace 'MY_OS', "EdgeOnWindows10"
            $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "Microsoft"
        }
        if ($os -eq "windows-xp") {
            $vagrantfile = $vagrantfile -replace 'MY_OS', "Windows_xp_sp2_Puppet"
            $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "therealslimpagey"
        }
        if ($os -eq "windows-2016") {
            $vagrantfile = $vagrantfile -replace 'MY_OS', "Windows2016"
            $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "mwrock"
        }
    }
    # Linux like system
    else {
        $vagrantfile = $vagrantfile -replace 'MY_OS', "$os"
        $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "bento"
    }

    $vagrantfile = $vagrantfile -replace 'MY_NAME', "$name-$os"
    $vagrantfile = $vagrantfile -replace 'VAGRANT_NAME', "$name-$os"
    $vagrantfile = $vagrantfile -replace 'MY_MEMORY', "$memory"
    $vagrantfile = $vagrantfile -replace 'MY_CPU', "$cpu"

    return $vagrantfile
}

# ------------------------- Common functions ------------------------- #

#--------------------------- Main workflow ----------------------------#

# Move to working directory
$current_path = pwd
cd $base_path\vagrant-util

# If name was provided, generate vm
if ($name -ne "") {

    # Configure vagrantfile
    $vagrantfile = configure

    # Create vagrant VM folder
    $folderName = "$name"
    mkdir $folderName

    # Write Vagrantfile to VM folder
    Set-Content -Path .\$folderName\Vagrantfile -Value $vagrantfile

    # Start vagrant VM
    cd $folderName
    vagrant up
    cd $current_path
}
# Otherwise, consider other commands
else {
    # ssh into VM
    if ($ssh -ne "") {
        cd $ssh
        vagrant up
        vagrant ssh
        cd $current_path
        exit
    }

    # Halt VM
    if ($halt -ne "") {
        cd $halt
        vagrant halt
        cd $current_path
        exit
    }

    # Clean vagrant VM
    if ($destroy -ne "") {
        cd $destroy
        vagrant halt
        vagrant destroy -f

        cd ..
        rmdir $destroy -Force -Recurse
        cd $current_path
        exit
    }

    # List vagrant VMs
    if ($list.isPresent) {
        vagrant global-status --prune
        cd $current_path
        exit
    }
}

#--------------------------- Main workflow ----------------------------#
