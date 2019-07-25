#------------------------- Gather parameters --------------------------#

param (
    [switch]$reset,
    [string]$os = "centos-7",
    [string]$family = "linux",
    [string]$name = "default",
    [string]$destroy = "",
    [string]$memory = "1024",
    [string]$cpu = "1",
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
        vagrant destroy -f
        cd ..
        rmdir $destroy -Force -Recurse

    } else {
        if ($reset.isPresent) {
            # Reset counter
            Set-Content -Path .\storedId -Value 3
        } else {
            $vagrantfile = '
            # -*- mode: ruby -*-
            # vi: set ft=ruby :

            Vagrant.configure("2") do |config|

                config.vm.box = "MY_FAMILY/MY_OS"

                #config.vm.network "public_network", ip: "192.168.1.201", bridge: "Marvell AVASTAR Wireless-AC Network Controller", bootproto: "static", gateway: "192.168.1.1"
    
                #config.vm.provision "shell", inline: "netsh advfirewall set allprofiles state off"

                #config.vm.provision "shell", inline: "echo nameserver 8.8.8.8 > /etc/resolv.conf && cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys && rm -f /vagrant/id_rsa.pub"        
                config.vm.network "private_network", ip: "MY_IP"

                config.vm.define "VAGRANT_NAME"

                config.vm.provider "virtualbox" do |vb|
                    vb.memory = "MY_MEMORY"
                    vb.cpus = "MY_CPU"
                    vb.name = "MY_NAME"
                    #vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"] 
                end

                config.vm.hostname = "MY_NAME"

                #config.vm.provision "ansible_local" do |ansible|
                    #ansible.become = "yes"
                    #ansible.provisioning_path = "/vagrant/provisioning/wazuh-ansible"
                    #ansible.inventory_path = "inventory"
                    #ansible.playbook = "wazuh-agent.yml"
                    #ansible.limit = "all"
                    #ansible.verbose = "true"
                    #ansible.playbook_command = "sudo ansible-playbook"
                #end    

            end'

            if ($family -eq "windows") {
                if ($os -eq "windows-2012") {
                    $vagrantfile = $vagrantfile -replace 'MY_OS', "win-2012r2-standard-amd64-nocm"
                    $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "opentable"
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
            if ($family -eq "linux") {
                $vagrantfile = $vagrantfile -replace 'MY_OS', "$os"
            }

            # Read stored ID
            if (Test-Path .\storedId) {
                $storedId = Get-Content .\storedId
            } else {
                $storedId = 3
            }

            $id = [int]$storedId + 1

            Set-Content -Path .\storedId -Value $id
            $vagrantfile = $vagrantfile -replace 'MY_IP', "11.0.0.$id"
            $vagrantfile = $vagrantfile -replace 'MY_NAME', "vagrant-$os-$id"
            $vagrantfile = $vagrantfile -replace 'VAGRANT_NAME', "$name"
            $vagrantfile = $vagrantfile -replace 'MY_MEMORY', "$memory"
            $vagrantfile = $vagrantfile -replace 'MY_CPU', "$cpu"
            if ($family -eq "linux") {
                $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "bento"
                $vagrantfile = $vagrantfile -replace '#config.vm.provision "shell", inline: "echo', 'config.vm.provision "shell", inline: "echo'
            } 
            if ($family -eq "windows") {
                $vagrantfile = $vagrantfile -replace '#config.vm.provision "shell", inline: "netsh', 'config.vm.provision "shell", inline: "netsh'
                $vagrantfile = $vagrantfile -replace '#vb.customize', 'vb.customize'
            }

            $folderName = "$os-$id"
            mkdir $folderName

            Set-Content -Path .\$folderName\Vagrantfile -Value $vagrantfile

            # Copy ansible keys
            cp C:\Users\havid\DATA\keys\ansible\id_rsa.pub $folderName\

            # Add new instance to ansible server hosts
            wsl echo "11.0.0.$id ansible_ssh_user=vagrant" | wsl sudo tee -a /etc/ansible/hosts
            cd $folderName
            vagrant up

            cd ..
        }
    }
}

#--------------------------- Main workflow ----------------------------#
