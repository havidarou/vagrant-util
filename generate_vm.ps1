#------------------------- Gather parameters --------------------------#

param (
    [switch]$reset,
    [string]$os = "centos-7",
    [string]$destroy = "",
    [string]$memory = "1024",
    [switch]$help
    )

#------------------------- Gather parameters --------------------------#

# Usage
function Usage
{
    "Usage"
}

# ------------------------- Common functions ------------------------- #

#--------------------------- Main workflow ----------------------------#

if ($usage.isPresent) {
    usage
} else {

    if ($destroy -ne "") {
        # Clean VM
        cd $destroy
        vagrant halt
        vagrant destroy
        cd ..
        rmdir $destroy -Force -Recurse
        (Get-Content "C:\Users\havid\Documents\MobaXterm\MobaXterm.ini" -Raw) -replace("$destroy.*`r`n", "") | Set-Content "C:\Users\havid\Documents\MobaXterm\MobaXterm.ini"

    } else {
        if ($reset.isPresent) {
            # Reset counter
            Set-Content -Path .\storedId -Value 0
        } else {
            $vagrantfile = '
    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    Vagrant.configure("2") do |config|

    config.vm.box = "bento/MY_OS"
    #config.disksize.size = "8GB"

    config.ssh.username = 'root'
    config.ssh.password = 'vagrant'
    config.ssh.insert_key = 'true'
    
    #config.vm.network "public_network", ip: "192.168.1.201", bridge: "Marvell AVASTAR Wireless-AC Network Controller", bootproto: "static", gateway: "192.168.1.1"
    config.vm.network "private_network", ip: "MY_IP"

    # Set memory for the default VM
    config.vm.provider "virtualbox" do |vb|
    vb.memory = "MY_MEMORY"
    vb.name = "MY_NAME"
    end

    # Configure the hostname for the default machine
    config.vm.hostname = "MY_NAME"

    end    
    '
            $vagrantfile = $vagrantfile -replace 'MY_OS', "$os"

            # Read stored ID
            if (Test-Path .\storedId) {
                $storedId = Get-Content .\storedId
            } else {
                $storedId = 0
            }

            if ($storedId -ne 0) {
                $id = [int]$storedId + 1
            } else {
                $id = 1
            }

            Set-Content -Path .\storedId -Value $id
            $vagrantfile = $vagrantfile -replace 'MY_IP', "10.0.0.$id"
            $vagrantfile = $vagrantfile -replace 'MY_NAME', "vagrant-$os-$id"
            $vagrantfile = $vagrantfile -replace 'MY_MEMORY', "$memory"

            $folderName = "$os-$id"
            mkdir $folderName
            mkdir $folderName\shared

            Set-Content -Path .\$folderName\Vagrantfile -Value $vagrantfile

            $session = "$os-$id=#109#0%10.0.0.$id%22%vagrant%%-1%-1%%%22%%0%0%0%%%-1%0%0%0%%1080%%0%0%1#MobaFont%10%0%0%0%15%236,236,236%0,0,0%180,180,192%0%-1%0%%xterm%-1%0%0,0,0%54,54,54%255,96,96%255,128,128%96,255,96%128,255,128%255,255,54%255,255,128%96,96,255%128,128,255%255,54,255%255,128,255%54,255,255%128,255,255%236,236,236%255,255,255%80%24%0%1%-1%<none>%%0#0#"

            (Get-Content "C:\Users\havid\Documents\MobaXterm\MobaXterm.ini" -Raw) -replace("SubRep=VMs`r`nImgNum=41", "SubRep=VMs`r`nImgNum=41`r`n$session") | Set-Content "C:\Users\havid\Documents\MobaXterm\MobaXterm.ini"

            cd $folderName
            vagrant up

            cd ..
        }
    }
}

#--------------------------- Main workflow ----------------------------#
