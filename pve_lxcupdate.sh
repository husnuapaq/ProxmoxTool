#!/usr/bin/env bash

# Copyright (c) 2024 HÜSNÜ APAK
# Web: husnuapak.com
# License: MIT
# https://github.com/husnuapaq/ProxmoxTool

header_info() {
  clear
  cat <<"EOF"

  _   _ _   _ ____  _   _ _   _      _    ____   _    _  __
 | | | | | | / ___|| \ | | | | |    / \  |  _ \ / \  | |/ /
 | |_| | | | \___ \|  \| | | | |   / _ \ | |_) / _ \ | ' / 
 |  _  | |_| |___) | |\  | |_| |  / ___ \|  __/ ___ \| . \ 
 |_| |_|\___/|____/|_| \_|\___/  /_/   \_\_| /_/   \_\_|\_\
                                                           

    ____  ____  ____ _  __ __  _______ _  __    ____     _    ________
   / __ \/ __ \/ __ \ |/ //  |/  / __ \ |/ /   ( __ )   | |  / / ____/
  / /_/ / /_/ / / / /   // /|_/ / / / /   /   / __  |   | | / / __/   
 / ____/ _, _/ /_/ /   |/ /  / / /_/ /   |   / /_/ /    | |/ / /___   
/_/   /_/ |_|\____/_/|_/_/  /_/\____/_/|_|   \____/     |___/_____/   
                                                                      


EOF
}
set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
header_info
echo "Loading..."
whiptail --backtitle "Proxmox VE LXC Updater" --title "Proxmox VE LXC Updater" --yesno "LXC Containers için güncel Sistemleri çeker. Devam Edelim mi?" 10 58 || exit
NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
excluded_containers=$(whiptail --backtitle "Proxmox VE LXC Updater" --title "Containers on $NODE" --checklist "\nContainers seç ve hangilerinin update olacaklarını işaretle:\n" 16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit

function needs_reboot() {
    local container=$1
    local os=$(pct config "$container" | awk '/^ostype/ {print $2}')
    local reboot_required_file="/var/run/reboot-required.pkgs"
    if [ -f "$reboot_required_file" ]; then
        if [[ "$os" == "ubuntu" || "$os" == "debian" ]]; then
            if pct exec "$container" -- [ -s "$reboot_required_file" ]; then
                return 0
            fi
        fi
    fi
    return 1
}

function update_container() {
  container=$1
  header_info
  name=$(pct exec "$container" hostname)
  os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  if [[ "$os" == "ubuntu" || "$os" == "debian" || "$os" == "fedora" ]]; then
    disk_info=$(pct exec "$container" df /boot | awk 'NR==2{gsub("%","",$5); printf "%s %.1fG %.1fG %.1fG", $5, $3/1024/1024, $2/1024/1024, $4/1024/1024 }')
    read -ra disk_info_array <<<"$disk_info"
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}Boot Disk: ${disk_info_array[0]}% full [${disk_info_array[1]}/${disk_info_array[2]} used, ${disk_info_array[3]} free]${CL}\n"
  else
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}[No disk info for ${os}]${CL}\n"
  fi
  case "$os" in
  alpine) pct exec "$container" -- ash -c "apk update && apk upgrade" ;;
  archlinux) pct exec "$container" -- bash -c "pacman -Syyu --noconfirm" ;;
  fedora | rocky | centos | alma) pct exec "$container" -- bash -c "dnf -y update && dnf -y upgrade" ;;
  ubuntu | debian | devuan) pct exec "$container" -- bash -c "apt-get update 2>/dev/null | grep 'packages.*upgraded'; apt list --upgradable && apt-get -yq dist-upgrade 2>&1" ;;
  esac
}

containers_needing_reboot=()
header_info
for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    header_info
    echo -e "${BL}[Info]${GN} Skipping ${BL}$container${CL}"
    sleep 1
  else
    status=$(pct status $container)
    template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL} \n"
      pct start $container
      echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL} \n"
      sleep 5
      update_container $container
      echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL} \n"
      pct shutdown $container &
    elif [ "$status" == "status: running" ]; then
      update_container $container
    fi
    if pct exec "$container" -- [ -e "/var/run/reboot-required" ]; then
        # Get the container's hostname and add it to the list
        container_hostname=$(pct exec "$container" hostname)
        containers_needing_reboot+=("$container ($container_hostname)")
    fi
  fi
done
wait
header_info
echo -e "${GN}The process is complete, and the selected containers have been updated.${CL}\n"
if [ "${#containers_needing_reboot[@]}" -gt 0 ]; then
    echo -e "${RD}The following containers require a reboot:${CL}"
    for container_name in "${containers_needing_reboot[@]}"; do
        echo "$container_name"
    done
fi
echo ""
