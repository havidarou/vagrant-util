#------------------------- Gather parameters --------------------------#

param (
    [switch]$reset,
    [switch]$help,
    [switch]$list,
    [string]$os = "ubuntu-18.04",
    [string]$memory = "1024",
    [string]$base_path = "C:\Users\havida\",
    [string]$wsl_base_path = "/mnt/c/Users/havida/",
    [string]$cpu = "1",
    [string]$halt = "",
    [string]$ssh = "",
    [string]$version = "",
    [string]$name = "",
    [string]$destroy = "",
    [string]$deploy = ""
)

#------------------------- Gather parameters --------------------------#

# ------------------------- Common functions ------------------------- #

# Usage
function Usage
{
    "Usage"
}

# Init vagrant file
function init
{
    $vagrantfile = '
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

    config.vm.box = "MY_FAMILY/MY_OS"
    config.vm.synced_folder ".", "/vagrant", group:"root", owner:"root", mount_options: ["dmode=777,fmode=777"]

    #config.vm.provision "shell", inline: "netsh advfirewall set allprofiles state off"

    #config.vm.provision "shell", inline: "echo nameserver 8.8.8.8 > /etc/resolv.conf && cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys"

    #config.vm.provision "shell", inline: "curl -sSL https://get.docker.com/ | sh && curl -L https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose && echo vm.max_map_count=262144 >> /etc/sysctl.conf && sysctl -w vm.max_map_count=262144 && systemctl enable docker && systemctl start docker"

    config.vm.network "private_network", ip: "MY_IP"

    config.vm.define "VAGRANT_NAME"

    config.vm.provider "virtualbox" do |vb|
        vb.memory = "MY_MEMORY"
        vb.cpus = "MY_CPU"
        vb.name = "MY_NAME"
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate//vagrant", "1"]
        #vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end

    config.vm.hostname = "MY_NAME"
end'
    return $vagrantfile
}

# Destroy
function destroy
{
    cd $destroy
    vagrant halt
    vagrant destroy -f

    # Get VM IP
    $id = Get-Content .\Vagrantfile | findstr config.vm.network
    $id = $id.split(" ")[-1].trim('"')

    cd ..
    rmdir $destroy -Force -Recurse

    # Remove instance from ansible server hosts
    wsl sudo sed -i "/$id/d" /etc/ansible/hosts
}

# Configure vagrant box
function configure
{
    $vagrantfile = init

    # Windows like system
    if ($os -like "*win*") {
        $vagrantfile = $vagrantfile -replace '#config.vm.provision "shell", inline: "netsh', 'config.vm.provision "shell", inline: "netsh'
        $vagrantfile = $vagrantfile -replace '#vb.customize', 'vb.customize'
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

        $vagrantfile = $vagrantfile -replace '#config.vm.provision "shell", inline: "echo', 'config.vm.provision "shell", inline: "echo'

        if ($deploy -eq "docker") {
            $vagrantfile = $vagrantfile -replace '#config.vm.provision "shell", inline: "curl', 'config.vm.provision "shell", inline: "curl'
        }
    }

    $vagrantfile = $vagrantfile -replace 'MY_IP', "11.0.0.$id"
    $vagrantfile = $vagrantfile -replace 'MY_NAME', "$name-$id-$os"
    $vagrantfile = $vagrantfile -replace 'VAGRANT_NAME', "$id-$os"
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

    # Read stored ID
    if (Test-Path .\storedId) {
        $storedId = Get-Content .\storedId
    } else {
        $storedId = 3
    }

    # Increase ID counter
    $id = [int]$storedId + 1
    Set-Content -Path .\storedId -Value $id

    # Configure vagrantfile
    $vagrantfile = configure

    # Create vagrant VM folder
    $folderName = "$name"
    mkdir $folderName

    # Write Vagrantfile to VM folder
    Set-Content -Path .\$folderName\Vagrantfile -Value $vagrantfile

    # Copy ansible keys
    cp $base_path\DATA\keys\id_rsa.pub $folderName\

    # Add new instance to ansible server hosts
    wsl echo "11.0.0.$id ansible_ssh_user=vagrant" | wsl sudo tee -a /etc/ansible/hosts

    # Start vagrant VM
    cd $folderName
    vagrant up
    cd $current_path

    if ($deploy -eq "ansible") {
        # Clone wazuh-ansible repository
        git clone  --single-branch --branch master https://github.com/wazuh/wazuh-ansible $base_path\vagrant-util\$folderName\wazuh-ansible

        # Add target host to playbook
        (Get-Content "$base_path\vagrant-util\$folderName\wazuh-ansible\playbooks\wazuh-odfe-single.yml") -replace("<your server host>", "11.0.0.$id") | Set-Content "$base_path\vagrant-util\$folderName\wazuh-ansible\playbooks\wazuh-odfe-single.yml"

        # Execute playbook
        wsl ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook $wsl_base_path/vagrant-util/$folderName/wazuh-ansible/playbooks/wazuh-odfe-single.yml --become
    }

    if ($deploy -eq "docker") {
        # Download docker-compose.yml file
        if ($version -ne "") {
            wsl curl -so $wsl_base_path/vagrant-util/$folderName/docker-compose.yml https://raw.githubusercontent.com/wazuh/wazuh-docker/$version/docker-compose.yml
        } else {
            wsl curl -so $wsl_base_path/vagrant-util/$folderName/docker-compose.yml https://raw.githubusercontent.com/wazuh/wazuh-docker/master/docker-compose.yml
        }
    }
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
        destroy
        cd $current_path
        exit
    }

    # List vagrant VMs
    if ($list.isPresent) {
        vagrant global-status --prune
        cd $current_path
        exit
    }

    # Reset counter
    if ($reset.isPresent) {
        Set-Content -Path .\storedId -Value 3
        cd $current_path
        exit
    }

    # Print usage
    if ($usage.isPresent) {
        usage
        cd $current_path
        exit
    }
}

#--------------------------- Main workflow ----------------------------#
