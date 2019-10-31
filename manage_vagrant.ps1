#------------------------- Gather parameters --------------------------#

param (
    [switch]$reset,
    [switch]$help,
    [switch]$list,
    [string]$os = "centos-7",
    [string]$memory = "1024",
    [string]$base_path = "C:\Users\havid\DATA\vagrant-util",
    [string]$wsl_base_path = "/mnt/c/Users/havid/DATA/vagrant-util",
    [string]$cpu = "1",
    [string]$halt = "",
    [string]$ssh = "",
    [string]$name = "",
    [string]$destroy = "",
    [string]$deploy = ""
)

#------------------------- Gather parameters --------------------------#

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

    #config.vm.provision "shell", inline: "echo nameserver 8.8.8.8 > /etc/resolv.conf && cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys && curl -sSL https://get.docker.com/ | sh && curl -L https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose && echo vm.max_map_count=262144 >> /etc/sysctl.conf && sysctl -w vm.max_map_count=262144 && systemctl enable docker && systemctl start docker"
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
    cd ..
    rmdir $destroy -Force -Recurse

    # Remove instance from ansible server hosts
    wsl sudo sed -i "s/11.0.0.$id ansible_ssh_user=vagrant//" /etc/ansible/hosts
}

# Configure vagrant box
function configure
{
    $vagrantfile = init

    if ($os -like "*win*") {
        $vagrantfile = $vagrantfile -replace '#config.vm.provision "shell", inline: "netsh', 'config.vm.provision "shell", inline: "netsh'
        $vagrantfile = $vagrantfile -replace '#vb.customize', 'vb.customize'
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
    # Linux like system
    else {
        $vagrantfile = $vagrantfile -replace 'MY_OS', "$os"
        $vagrantfile = $vagrantfile -replace 'MY_FAMILY', "bento"

        $vagrantfile = $vagrantfile -replace '#config.vm.provision "shell", inline: "echo', 'config.vm.provision "shell", inline: "echo'
    }

    $vagrantfile = $vagrantfile -replace 'MY_IP', "11.0.0.$id"
    $vagrantfile = $vagrantfile -replace 'MY_NAME', "vagrant-$os-$id"
    $vagrantfile = $vagrantfile -replace 'VAGRANT_NAME', "$name"
    $vagrantfile = $vagrantfile -replace 'MY_MEMORY', "$memory"
    $vagrantfile = $vagrantfile -replace 'MY_CPU', "$cpu"

    return $vagrantfile
}

# ------------------------- Common functions ------------------------- #

#--------------------------- Main workflow ----------------------------#

# ssh into VM
if ($ssh -ne "") {
    cd $ssh
    vagrant up
    vagrant ssh
    cd ..
    exit
}

# Halt VM
if ($halt -ne "") {
    cd $halt
    vagrant halt
    cd ..
    exit
}

# Clean vagrant VM
if ($destroy -ne "") {
    destroy
    exit
}

# List vagrant VMs
if ($list.isPresent) {
    vagrant global-status --prune
    exit
}

# Reset counter
if ($reset.isPresent) {
    Set-Content -Path .\storedId -Value 3
    exit
}

# Check name parameter
if ($name -eq "") {
    "No vagrant VM name was provided"
    exit
}

# Print usage
if ($usage.isPresent) {
    usage
    exit
}

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
cp C:\Users\havid\DATA\keys\ansible\id_rsa.pub $folderName\

# Add new instance to ansible server hosts
wsl echo "11.0.0.$id ansible_ssh_user=vagrant" | wsl sudo tee -a /etc/ansible/hosts

# Start vagrant VM
cd $folderName
vagrant up
cd ..

if ($deploy -eq "ansible") {
    # Clone wazuh-ansible repository
    git clone https://github.com/wazuh/wazuh-ansible $base_path\$folderName\wazuh-ansible

    # Add target host to playbook
    (Get-Content "$base_path\$folderName\wazuh-ansible\playbooks\wazuh-elastic_stack-single.yml") -replace("<your server host>", "11.0.0.$id") | Set-Content "$base_path\$folderName\wazuh-ansible\playbooks\wazuh-elastic_stack-single.yml"

    # Execute playbook
    wsl ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook $wsl_base_path/$folderName/wazuh-ansible/playbooks/wazuh-elastic_stack-single.yml --become
}

if ($deploy -eq "docker") {
    # Download docker-compose.yml file
    wsl curl -so $wsl_base_path/$folderName/docker-compose.yml https://raw.githubusercontent.com/wazuh/wazuh-docker/3.10.2_7.3.2/docker-compose.yml
}

# Print status
vagrant global-status

#--------------------------- Main workflow ----------------------------#
