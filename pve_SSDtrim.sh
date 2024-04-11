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
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
header_info
echo "Loading..."

ROOT_FS=$(df -Th "/" | awk 'NR==2 {print $2}')
if [ "$ROOT_FS" != "ext4" ]; then
    echo "Sadece ext4 Formatını destekler."
    exit 1
fi

whiptail --backtitle "Proxmox VE TRIM SSD" --title "Proxmox VE EXT4 için TRIM Desteği" --yesno "Bu Script  kullanılmayan blokları yöneterek SSD performansını korur.Gereksiz depolama kullanımını önlemek için optimizasyon sağlar. VM'ler fstrim'i otomatikleştirir. Devam edelim mi?" 10 58 || exit
NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
excluded_containers=$(whiptail --backtitle "Proxmox VE TRIM SSD" --title "Containers on $NODE" --checklist "\nTRIM işleminden atlanacak Containerleri seçin:\n" \
  16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit  

function trim_container() {
  local container=$1
  header_info
  echo -e "${BL}[Info]${GN} Trimming ${BL}$container${CL} \n"
  local before_trim=$(lvs | awk -F '[[:space:]]+' 'NR>1 && (/Data%|'"vm-$container"'/) {gsub(/%/, "", $7); print $7}')
  echo -e "${RD}Data TRIM Öncesi $before_trim%${CL}"
  pct fstrim $container
  local after_trim=$(lvs | awk -F '[[:space:]]+' 'NR>1 && (/Data%|'"vm-$container"'/) {gsub(/%/, "", $7); print $7}')
  echo -e "${GN}Data TRIM Sonrası $after_trim%${CL}"
  sleep 1.5
}



for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    header_info
    echo -e "${BL}[Info]${GN} Geçiliyor.. ${BL}$container${CL}"
    sleep 1
  else
    template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "true" ]; then
      header_info
      echo -e "${BL}[Info]${GN} Skipping ${container} ${RD}$container is a template ${CL} \n"
      sleep 1
      continue
    fi
      trim_container $container
  fi
done

wait
header_info
echo -e "${GN} LXC Containers Trimmi  Bitti ${CL} \n"
