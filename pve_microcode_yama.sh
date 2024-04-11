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

RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

msg_info() { echo -ne " ${HOLD} ${YW}$1..."; }
msg_ok() { echo -e "${BFR} ${CM} ${GN}$1${CL}"; }
msg_error() { echo -e "${BFR} ${CROSS} ${RD}$1${CL}"; }

header_info
current_microcode=$(journalctl -k | grep -oP "microcode: updated early: [^ ]+ -> \K[^,]+, date = [^ ]+" | head -n 1)
[ -z "$current_microcode" ] && current_microcode="Bulunamadı."

intel() {
  if ! dpkg -s iucode-tool >/dev/null 2>&1; then
    msg_info "Yükleniyor iucode-tool (Intel microcode kurulum)"
    apt-get install -y iucode-tool &>/dev/null
    msg_ok "iucode-tool intel Yüklendi."
  else
    msg_ok "Intel iucode-tool Yükleme Başarılı"
    sleep 1
  fi

  intel_microcode=$(curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode//" | grep -o 'href="[^"]*amd64.deb"' | sed 's/href="//;s/"//')
  [ -z "$intel_microcode" ] && { whiptail --backtitle "Proxmox VE  MİKROCODE Yükleyici" --title "Microcode Bulunamadı" --msgbox "Microcode PAketi Bulunamadı\n Daha Sonra Tekrar Deneyin." 10 68; msg_info "Exiting"; sleep 1; msg_ok "Done"; exit; }

  MICROCODE_MENU=()
  MSG_MAX_LENGTH=0

  while read -r TAG ITEM; do
    OFFSET=2
    (( ${#ITEM} + OFFSET > MSG_MAX_LENGTH )) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
    MICROCODE_MENU+=("$TAG" "$ITEM " "OFF")
  done < <(echo "$intel_microcode")

  microcode=$(whiptail --backtitle "Proxmox VE MİKROCODE Yükleyici" --title "Güncel  Microcode revizion:${current_microcode}" --radiolist "\nYüklemek için microcode packeti seçin:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${MICROCODE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit

  [ -z "$microcode" ] && { whiptail --backtitle "Proxmox VE  MİKROCODE Yükleyici" --title "Microcode Seçin" --msgbox "Mikrocode paketi seçilmedi" 10 68; msg_info "Çıkılıyor"; sleep 1; msg_ok "Tamam"; exit; }

  msg_info "Downloading the Intel Processor Microcode Package $microcode"
  wget -q http://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode/$microcode
  msg_ok "Intel Processor Microcode Package $microcode"

  msg_info "Yükleniyor $microcode "
  dpkg -i $microcode &>/dev/null
  msg_ok "Yüklendi $microcode"

  msg_info "Temizleniyor"
  rm $microcode
  msg_ok "Temizlendi"
  echo -e "\nSistemin Etkin olabilmesi için Yeniden Başlatılmalıdır.\n"
}

amd() {
  amd_microcode=$(curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode///" | grep -o 'href="[^"]*amd64.deb"' | sed 's/href="//;s/"//')

  [ -z "$amd_microcode" ] && { whiptail --backtitle "Proxmox VE MİKROCODE Yükleyici" --title "Microcode Bulunamadı" --msgbox "Mikrocode Paketi bulunamadı\n Daha sonra tekrar deneyin." 10 68; msg_info "Exiting"; sleep 1; msg_ok "Done"; exit; }

  MICROCODE_MENU=()
  MSG_MAX_LENGTH=0

  while read -r TAG ITEM; do
    OFFSET=2
    (( ${#ITEM} + OFFSET > MSG_MAX_LENGTH )) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
    MICROCODE_MENU+=("$TAG" "$ITEM " "OFF")
  done < <(echo "$amd_microcode")

  microcode=$(whiptail --backtitle "Proxmox VE MİKROCODE Yükleyici" --title "Güncel Microcode revizion:${current_microcode}" --radiolist "\nYüklenecek Mikrocode PAketini Seçiniz:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${MICROCODE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit

  [ -z "$microcode" ] && { whiptail --backtitle "Proxmox VE MİKROCODE Yükleyici" --title "Microcode Seçilmedi" --msgbox "Başka bir MikroCode PAketi seçiniz" 10 68; msg_info "Çıkılıyor"; sleep 1; msg_ok "Done"; exit; }

  msg_info "AMD Processor Microcode Paketi $microcode"
  wget -q https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode/$microcode
  msg_ok "AMD Processor Microcode Paketi Yükleniyor $microcode"

  msg_info "Yükleniyor $microcode "
  dpkg -i $microcode &>/dev/null
  msg_ok "Yüklendi. $microcode"

  msg_info "Temizleniyor"
  rm $microcode
  msg_ok "Temizlendi"
  echo -e "\nDeğişikliklerin Etkin Olabilmesi için yeniden başlatılmalıdır.\n"
}

if ! command -v pveversion >/dev/null 2>&1; then header_info; msg_error "PVE Bulunamadı"; exit; fi

whiptail --backtitle "Proxmox VE MİKROCODE Yükleyici" --title "Proxmox VE Processor Microcode" --yesno "Mikrocode yapısı güncellensin mi?" 10 58 || exit

msg_info "CPU Vendor Kontrol Ediliyor"
cpu=$(lscpu | grep -oP 'Vendor ID:\s*\K\S+' | head -n 1)
if [ "$cpu" == "GenuineIntel" ]; then
  msg_ok "${cpu} Bulundu"
  sleep 1
  intel
elif [ "$cpu" == "AuthenticAMD" ]; then
  msg_ok "${cpu} Bulundu"
  sleep 1
  amd
else
  msg_error "${cpu} Desteklenmeyen CPU"
  exit
fi
