# function to install nodejs and npm
npmnjs() {
sudo apt update
sudo apt install -y curl build-essential ca-certificates
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
node --version
npm --version
}

# function to install cuda
function cudi() {
    # Add contrib and non-free repositories
    sudo sed -i '/^deb .* \(main\|universe\|restricted\|multiverse\)/s/$/ contrib non-free/' /etc/apt/sources.list
    
    # Download CUDA repository package
    wget https://developer.download.nvidia.com/compute/cuda/12.8.1/local_installers/cuda-repo-debian12-12-8-local_12.8.1-570.124.06-1_amd64.deb
    
    # Install CUDA repository package
    sudo dpkg -i cuda-repo-debian12-12-8-local_12.8.1-570.124.06-1_amd64.deb
    
    # Copy GPG key to correct location
    sudo cp /var/cuda-repo-debian12-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
    
    # Update package lists
    sudo apt-get update
    
    # Install CUDA toolkit
    sudo apt-get -y install cuda-toolkit-12-8
    
    # Add CUDA paths to environment variables
    echo 'export PATH=/usr/local/cuda-12.8/bin${PATH:+:${PATH}}' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
    
    # Install additional CUDA packages and dependencies
    sudo apt-get -y install cuda build-essential cmake freeglut3-dev libx11-dev libxmu-dev libxi-dev libgl1-mesa-glx libglu1-mesa libglu1-mesa-dev libglfw3-dev libgles2-mesa-dev libglx-dev libopengl-dev
    
    # Enable changes in current session
    source ~/.bashrc
    
    echo "CUDA 12.8 installation completed successfully!"
    echo "Remember to restart your session or log out and back in for the changes to take effect."
}

# function for quick edit lxc conf file
lxe() {

nano "/etc/pve/lxc/$1.conf"

 }

alias olp='ollama pull'
alias ni='netstat -i'
alias th='tree -h'

# VM disk import function
vmdi() {
    echo "=== Proxmox Disk Import Function ==="

    # Step 1: Prompt for VMID
    read -rp "Enter VMID of the target VM: " VMID
    if [[ -z "$VMID" ]]; then
        echo "VMID is required!"
        return 1
    fi

    # Step 2: Find supported disk image files
    echo "Scanning for disk image files in current directory..."
    mapfile -t disk_images < <(find . -maxdepth 1 -type f \( -iname "*.raw" -o -iname "*.qcow2" -o -iname "*.vmdk" -o -iname "*.ova" -o -iname "*.ovf" \) | sort)

    if [[ ${#disk_images[@]} -eq 0 ]]; then
        echo "No supported disk images found in current directory."
        return 1
    fi

    echo "Available disk images:"
    select disk_file in "${disk_images[@]}"; do
        [[ -n "$disk_file" ]] && break
        echo "Invalid selection."
    done

    # Step 3: Handle OVA/OVF extraction
    extension="${disk_file##*.}"
    if [[ "$extension" == "ova" || "$extension" == "ovf" ]]; then
        echo "Extracting $disk_file..."
        tar -xvf "$disk_file"
        # Find new disk file from extracted contents
        mapfile -t extracted_disks < <(find . -maxdepth 1 -type f \( -iname "*.vmdk" -o -iname "*.qcow2" -o -iname "*.raw" \) | sort)

        if [[ ${#extracted_disks[@]} -eq 0 ]]; then
            echo "No usable disk image found after extraction."
            return 1
        fi

        echo "Select extracted disk image to import:"
        select extracted_disk in "${extracted_disks[@]}"; do
            [[ -n "$extracted_disk" ]] && break
            echo "Invalid selection."
        done
        disk_to_import="$extracted_disk"
    else
        disk_to_import="$disk_file"
    fi

    # Step 4: Prompt for destination storage
    echo "Enter destination storage name (e.g., local/local-lvm/local-zfs):"
    read -rp "> " DEST
    if [[ -z "$DEST" ]]; then
        echo "Destination storage is required!"
        return 1
    fi

    # Step 5: Run import
    echo "Running: qm importdisk $VMID \"$disk_to_import\" $DEST"
    qm importdisk "$VMID" "$disk_to_import" "$DEST"
}

# ─────────────────────────────────────────
# ✅ GLOBAL SETTINGS
# ─────────────────────────────────────────
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"

# ─────────────────────────────────────────
# 📁 FILE & DIRECTORY LISTING
# ─────────────────────────────────────────
alias l='ls $LS_OPTIONS -lah --group-directories-first'
alias ld='ls -ld */'                       # List directories only
alias la='ls -AF'                          # List all files
alias l1='ls -1AF'                         # One file per line
alias l1a='ls -lhAF'                       # All file details
alias lg='ls -AF | grep'                   # Grep filenames
alias lt='ls -Alt'                         # Sort by time
alias lss='ls -AFlS'                       # Sort by size
alias lsd='ls $LS_OPTIONS -lAhF --group-directories-first'

# ─────────────────────────────────────────
# 📂 FILE OPERATIONS (SAFETY)
# ─────────────────────────────────────────
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias chmod='chmod --preserve-root'
alias chown='chown --preserve-root'
alias chgrp='chgrp --preserve-root'
alias cx='chmod a+x'

# ─────────────────────────────────────────
# 📚 SEARCH / GREP
# ─────────────────────────────────────────
alias grep='grep --color=always'
alias egrep='egrep --color=always'
alias fgrep='fgrep --color=always'
hs() { history | grep "$1"; }              # History search function

# ─────────────────────────────────────────
# 📦 PACKAGE MANAGEMENT
# ─────────────────────────────────────────
alias ud='apt update'
alias ug='apt update && apt full-upgrade -y && apt dist-upgrade -y'
alias ai='apt install'
alias ar='apt remove'
alias san='sudo /usr/local/bin/sync-lxc-aliases.sh'

# ─────────────────────────────────────────
# 🐳 DOCKER & DEV OPS
# ─────────────────────────────────────────
alias dr='docker run'
alias dc='docker compose'
alias gc='git clone'
alias gl='git log --oneline --graph --decorate --all'
alias gs='git status -sb'
alias rtd="sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker"

# ─────────────────────────────────────────
# 🖥️ SYSTEM MONITORING & NETWORKING
# ─────────────────────────────────────────
alias mem='free -m -l -t'
alias memapps1='ps auxf | sort -nr -k 4'
alias memapps2='ps auxf | sort -nr -k 4 | head -10'
alias cpuapps1='ps auxf | sort -nr -k 3'
alias cpuapps2='ps auxf | sort -nr -k 3 | head -10'
alias df='df -H'
alias du='du -ch'
alias mt='mount | column -t'
alias ports='netstat -tulanp'

# ─────────────────────────────────────────
# 🌐 NETWORK INTERFACES (custom setups)
# ─────────────────────────────────────────
alias dnsbs2='dnstop -l 5 enp6s0'
alias vnsbs2='vnstat -i enp6s0'
alias ifbs2='iftop -pP -i enp6s0'
alias tcpbs2='tcpdump -p --buffer-size=4096 -i enp6s0'
alias ethbs2='ethtool enp6s0'

alias dnsbs1='dnstop -l 5 eno1'
alias vnsbs1='vnstat -i eno1'
alias ifbs1='iftop -pP -i eno1'
alias tcpbs1='tcpdump -p --buffer-size=4096 -i eno1'
alias ethbs1='ethtool eno1'

alias dnsct='dnstop -l 5 eth0'
alias vnsct='vnstat -i eth0'
alias ifct='iftop -pP -i eth0'
alias tcpct='tcpdump -p --buffer-size=4096 -i eth0'
alias ethct='ethtool eth0'
alias etht='ethtool'

# ─────────────────────────────────────────
# 📂 NAVIGATION & CONVENIENCE
# ─────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../../'
alias 1u='cd ..'
alias 2u='cd ../..'
alias 3u='cd ../../..'
alias 4u='cd ../../../..'
alias 5u='cd ../../../../..'
alias ~='cd ~'

# ─────────────────────────────────────────
# 🧹 UTILS & SHORTCUTS
# ─────────────────────────────────────────
alias c='clear'
alias cl='clear; l'
alias cla='clear; la'
alias x='exit'
alias r='reboot'
alias po='poweroff'
alias fm='sync && echo 3 | sudo tee /proc/sys/vm/drop_caches'
alias a='echo "------------Your aliases------------"; alias'
alias h='echo "Use --help with a command, not as a command!"'
alias fd='fdfind'  # Optional: if installed
alias nv='nvidia-smi'
alias nvd='nvidia-smi dmon'
alias nvt='nvtop'
alias msa='nano /etc/shared-aliases.sh'
alias mss='nano /usr/local/bin/sync-lxc-aliases.sh'
alias msl='nano  /var/log/lxc-alias-sync.log'
alias sb='source ~/.bashrc'
alias lx='cd /etc/pve/lxc/'
alias upin='update-initramfs -u -k all'
# ─────────────────────────────────────────
# ⚡ BONUS UTILS
# ─────────────────────────────────────────

# Quick file sharing over HTTP
alias serve='python3 -m http.server'
alias nvh="wget https://us.download.nvidia.com/XFree86/Linux-x86_64/570.133.07/NVIDIA-Linux-x86_64-570.133.07.run
chmod +x NVIDIA-Linux-x86_64-570.133.07.run
./NVIDIA-Linux-x86_64-570.133.07.run --dkms"
alias nvc="wget https://us.download.nvidia.com/XFree86/Linux-x86_64/570.133.07/NVIDIA-Linux-x86_64-570.133.07.run
chmod +x NVIDIA-Linux-x86_64-570.133.07.run
./NVIDIA-Linux-x86_64-570.133.07.run --no-kernel-modules"
alias lxi="apt-get update --fix-missing -y apt update && apt full-upgrade -y && apt dist-upgrade -y && apt install -y  && apt install -y curl python3-pip tree dkms wget btop nvtop htop  pciutils build-essential software-properties-common make libgl1 libegl1 libglvnd-dev libsasl2-modules  iftop dnstop vnstat net-tools pkg-config fd-find qemu-guest-agent gcc cloud-init git cmake nfs-kernel-server mailutils vulkan-validationlayers libvulkan1 -y && apt clean && apt autoremove -y && update-pciids && usermod -aG render,video,audio root"
alias nvcont="curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit -y"

# Extract any archive type
ext() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1" ;;
      *.tar.gz)    tar xzf "$1" ;;
      *.tar.xz)    tar xf "$1" ;;
      *.bz2)       bunzip2 "$1" ;;
      *.rar)       unrar x "$1" ;;
      *.gz)        gunzip "$1" ;;
      *.tar)       tar xf "$1" ;;
      *.tbz2)      tar xjf "$1" ;;
      *.tgz)       tar xzf "$1" ;;
      *.zip)       unzip "$1" ;;
      *.Z)         uncompress "$1" ;;
      *.7z)        7z x "$1" ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# docker install function
dki() {
    echo "Are you on Debian or Ubuntu? (d/u): "
    read -r distro

    # Uninstall old Docker versions
    echo "Removing old Docker versions..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove -y "$pkg"
    done

    # Update and upgrade system
    echo "Updating system packages..."
    sudo apt update && sudo apt full-upgrade -y && sudo apt dist-upgrade -y

    # Common setup
    echo "Installing prerequisites..."
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings

    if [[ $distro == "d" ]]; then
        echo "Setting up for Debian..."

        # Add Docker's GPG key
        curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc

        # Add Docker repo
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    elif [[ $distro == "u" ]]; then
        echo "Setting up for Ubuntu..."

        # Add Docker's GPG key
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add Docker repo
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    else
        echo "Invalid option. Please enter 'd' for Debian or 'u' for Ubuntu."
        return 1
    fi

    # Install Docker
    echo "Updating package index and installing Docker..."
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


    echo "Installing Dockge..."
    mkdir -p /opt/stacks /opt/dockge
    cd /opt/dockge
    
    curl https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml --output compose.yaml
    
    # Start the server using docker compose (Docker Compose V2+)
    docker compose up -d
    
    # If you are using Docker Compose V1 or Podman, uncomment and run:
    # docker-compose up -d

    # Get the local IP address using hostname command
    local ip=$(hostname -I | awk '{print $1}')
    
    # Remove the /24 CIDR notation if it exists
    ip=${ip%/*}
    
    # Append the port number
    local ip_with_port="http://${ip}:5001"
    
    # Display the IP with port
    clear
    echo -e "\e[1;32mDockge address\e[0m" 
    echo -e "\e[1;37;41m$ip_with_port\e[0m" 
    echo -e "\e[1;32mDocker accessed via CLI\e[0m"
    echo -e "\e[1;32mDocker and Dockge installation completed!\e[0m"
echo
}

# List ANSI colours
col() {

# Print 256 foreground colors
echo "256 Foreground Colors:"
for i in {0..255}; do
    echo -e "\e[38;5;${i}mColor ${i}\e[0m"
done

# Print 256 background colors
echo "256 Background Colors:"
for i in {0..255}; do
    echo -e "\e[48;5;${i}mBackground Color ${i}\e[0m"
done
}

# IP address along with port
ipp() {
    # Get the local IP address using hostname command
    local ip=$(hostname -I | awk '{print $1}')
    
    # Remove the /mask if present (e.g., 10.0.3.20/24 -> 10.0.3.20)
    ip=${ip%/*}

    # Scan the container for open ports using ss command
    local open_ports=$(ss -tuln | awk '{print $5}' | cut -d':' -f2)

    if [ -z "$open_ports" ]; then
        echo "No open ports found."
        return 1
    fi

    # Display the IP address with each open port prepended by http://
clear
    echo -e "\n\e[1;37;41mIP details\e[0m"
    echo -e "\e[1;33mIP no port\e[0m" 
    echo -e "\e[1;33mhttp://$ip:\e[0m"  
#    echo -e "\e[1;33mThis is only if Dockge installed\e[0m"  
#    echo -e "\e[1;33mhttp://$ip:5001\e[0m"  
    echo -e "\e[1;32mIP with Open Ports\e[0m"  
    for port in $open_ports; do
        echo -e "\e[1;32mhttp://$ip:$port\e[0m"  
    done
echo
}

# Add Nvidia devices to lxc conf file

ndevs() {
    echo "Enter the LXC container ID:"
    read -r CTID

    if [ -z "$CTID" ]; then
        echo "❌ No container ID entered. Exiting."
        return 1
    fi

    # Define the devices to be added
    local devices=(
        "dev0: /dev/nvidia0"
        "dev1: /dev/nvidia1"
        "dev2: /dev/nvidiactl"
        "dev3: /dev/nvidia-uvm"
        "dev4: /dev/nvidia-uvm-tools"
        "dev5: /dev/nvidia-caps/nvidia-cap1"
        "dev6: /dev/nvidia-caps/nvidia-cap2"
    )

    # Define the path to the LXC configuration file
    local config_file="/etc/pve/lxc/${CTID}.conf"

    # Check if the container ID exists and has a valid configuration file
    if [ ! -f "$config_file" ]; then
        echo "❌ Container ID $CTID not found or does not have a valid configuration file. Exiting."
        return 1
    fi

    # Append the devices to the configuration file
    for device in "${devices[@]}"; do
        echo "$device" >> "$config_file"
    done

    echo "✅ Successfully added NVIDIA devices to container ID $CTID."
}

# Nopassword Logon
function ncp() {
    echo "Creating directory..."
    mkdir -p /etc/systemd/system/container-getty@1.service.d
    
    echo "Writing override configuration..."
    cat <<EOF > /etc/systemd/system/container-getty@1.service.d/override.conf
[Service]  
ExecStart=  
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud 115200,38400,9600 tty1 linux  
EOF
    
    echo "Reloading systemd daemon..."
    systemctl daemon-reexec
    
    echo "Restarting container-getty@1.service..."
    systemctl restart container-getty@1.service
}

#Bulk delete lxcs
bdc() {
    echo "📦 Listing all LXC containers:"
    pct list | awk 'NR==1 || NR>1 {printf "%-6s %-20s %-10s\n", $1, $3, $2}'
    
    echo -e "\nEnter container ID(s) to delete (e.g. 101 102 105):"
    read -r CTIDS
    
    if [ -z "$CTIDS" ]; then
        echo "❌ No container IDs entered. Exiting."
        return 1
    fi
    
    echo -e "\n⚠️ You are about to DELETE the following container(s): $CTIDS"
    echo "This will stop and destroy them permanently."
    
    read -p "Type YES to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "YES" ]; then
        echo "❌ Cancelled."
        return 1
    fi
    
    for CTID in $CTIDS; do
        echo -e "\n🧨 Deleting container $CTID..."
        
        if pct status "$CTID" &>/dev/null; then
            if pct status "$CTID" | grep -q running; then
                echo "⏹️ Stopping container $CTID..."
                pct shutdown "$CTID" --force-stop 1
                sleep 2
            fi
            
            pct destroy "$CTID" --force
            echo "✅ $CTID deleted."
        else
            echo "⚠️ Container $CTID not found, skipping."
        fi
    done
    
    echo -e "\n🧼 All done."
}

# Update nvidia repo keys

nrk() {
    # Delete the old NVIDIA GPG key
    sudo apt-key del 7fa2af80
    
    # Download the NVIDIA CUDA keyring package
    wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
    
    # Install the NVIDIA CUDA keyring package
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    
    # Add the new NVIDIA GPG key
    sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/3bf863cc.pub
    
    # Remove any existing entries for the NVIDIA CUDA repository from sources.list
    sudo sed -i '/developer\.download\.nvidia\.com\/compute\/cuda\/repos/d' /etc/apt/sources.list
    
    # Update the package lists
    sudo apt update
}



alias pi312='pip3.12'
alias py312='python3.12'
alias pi3='pip3'
alias py3='python3'
alias n='nano'
alias pi='pip3'
alias py='python3'
alias pi3='pip3'
alias py3='python3'
alias ver='cat /etc/*-release'
alias fresh='rm -f /etc/ssh/ssh_host_* && sudo truncate -s 0 /etc/machine-id && sudo apt clean && sudo apt autoremove -y' #  && poweroff'
alias cmi='cat /etc/machine-id'
alias gg='ls -la /dev/nvidia* && ls -l /dev/dri*'
alias nas='mount -t nfs 192.168.4.2:/hdd10tb/nas/  /mnt/nas && mount -t nfs 192.168.4.2:/hdd4tb/dump/ /mnt/bs1backup'
alias unas='umount /mnt/nas && umount /mnt/bs1backup'
alias rcm='rsync --ignore-existing -avprzh /mnt/nas/ai/sd/models/ /nv1a/subvol-502-disk-0/root/comfy/ComfyUI/models'
alias lnas='l  /mnt/nas && l /mnt/bs1backup'
alias doug='cd /opt/dockge docker compose pull && docker compose up -d'
alias lxb="apt-get update --fix-missing && apt update && apt full-upgrade -y && apt dist-upgrade -y && apt install -y  && apt install -y lshw cmake pciutils curl git pkg-config cmake vulkan-validationlayers libvulkan1 tree python3-pip dkms wget btop nvtop htop pciutils build-essential software-properties-common fd-find git -y && apt clean && apt autoremove -y && update-pciids && usermod -aG render,video,audio root"
alias tki='bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/turnkey/turnkey.sh)"'
alias tkp='cat turnkey-name.creds'
alias op='lsof -i TCP| fgrep LISTEN'
alias lvid='lspci -nn | egrep -i "3d|display|vga"'
alias lc='locale'
alias lca='locale -a'
alias torch='pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128 --break-system-packages'
alias pt='echo $PATH'
# Python 3.12.10 installation
pyin312() {
apt install -y sudo curl wget cmake idle python3-launchpadlib &&  apt-get build-dep python3 -y &&  apt install pkg-config -y apt-get install -y gcc python3-pip build-essential libssl-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libffi-dev zlib1
wget https://www.python.org/ftp/python/3.12.10/Python-3.12.10.tgz
tar -xvf Python-3.12.10.tgz
cd ~
cd  Python-3.12.10
./configure --enable-optimizations --prefix=/usr/local
make -j $(nproc)
# make altinstall
# python3.12 --version
echo "Make a Choice - make install or make altinstall"
}
