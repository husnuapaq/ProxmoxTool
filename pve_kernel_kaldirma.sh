#!/usr/bin/env bash

# Copyright (c) 2024 HÜSNÜ APAK
# Web: husnuapak.com
# License: MIT
# https://github.com/husnuapaq/ProxmoxTool

function header_info {
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
YW=$(echo "\033[33m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
current_kernel=$(uname -r)
available_kernels=$(dpkg --list | grep 'kernel-.*-pve' | awk '{print $2}' | grep -v "$current_kernel" | sort -V)
header_info

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

whiptail --backtitle "Proxmox VE KERNEL TEMİZLEME" --title "Proxmox VE Kernel Temizleme" --yesno "Bu Script Kullanılmayan Kernel İmage larını temizler.BU BÜYÜK BİR RİSKTİR." 10 68 || exit
if [ -z "$available_kernels" ]; then
  whiptail --backtitle "Proxmox VE KERNEL TEMİZLEME" --title "Eski Kernel Yok" --msgbox "Sisteminizde Eski bir Kernel Bulunamadı. \nGüncel  kernel ($current_kernel)." 10 68
  echo "Çıkılıyor..."
  sleep 2
  clear
  exit
fi
  KERNEL_MENU=()
  MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  KERNEL_MENU+=("$TAG" "$ITEM " "OFF")
done < <(echo "$available_kernels")

remove_kernels=$(whiptail --backtitle "Proxmox VE KERNEL TEMİZLEME" --title "Güncel Kernel $current_kernel" --checklist "\nKaldırılıacak olan Kerneli seçin:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${KERNEL_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit
[ -z "$remove_kernels" ] && {
  whiptail --backtitle "Proxmox VE KERNEL TEMİZLEME" --title "Kernel Seçilmedi" --msgbox "Kernel Seçilmedi" 10 68
  echo "Exiting..."
  sleep 2
  clear
  exit
}
whiptail --backtitle "Proxmox VE KERNEL TEMİZLEME" --title "Kernelleri Kaldır" --yesno "Eski Kernelleri Kaldırmak istermisin $(echo $remove_kernels | awk '{print NF}') Öceki seçilen Kernel?" 10 68 || exit

msg_info "Eski Kernel Kaldırılıyor ${CL}${RD}$(echo $remove_kernels | awk '{print NF}') ${CL}${YW}old Kernels${CL}"
/usr/bin/apt purge -y $remove_kernels >/dev/null 2>&1
msg_ok "Kernel Başarıyla Kaldırıldı"

msg_info "GRUB Güncelleniyor"
/usr/sbin/update-grub >/dev/null 2>&1
msg_ok "GRUB Güncelleme Başarılı"
msg_info "Çıkılıyor."
sleep 2
msg_ok "Bitti"


