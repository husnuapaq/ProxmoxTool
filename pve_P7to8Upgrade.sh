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

set -euo pipefail
shopt -s inherit_errexit nullglob

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

start_routines() {
  header_info

  whiptail --backtitle "Proxmox VE 7to8 Upgrade" --msgbox --title "PVE8 SOURCES" "Bu Script, Proxmox VE 8'i güncellemek ve yüklemek için doğru kaynakları ayarlayacaktır." 10 58
    msg_info "Proxmox VE 8 Kaynakları değiştiriliyor"
    cat <<EOF >/etc/apt/sources.list
deb http://ftp.debian.org/debian bookworm main contrib
deb http://ftp.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
    msg_ok "Proxmox VE 8 Kaynaklar Değişti"

  whiptail --backtitle "Proxmox VE 7to8 Upgrade" --msgbox --title "PVE8-ENTERPRISE" "pve-enterprise' deposu yalnızca Proxmox VE aboneliği satın alan kullanıcılar tarafından kullanılabilir." 10 58
    msg_info "pve-enterprise' deposunu devre dışı bırakılıyor"
    cat <<EOF >/etc/apt/sources.list.d/pve-enterprise.list
# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
EOF
    msg_ok "'pve-enterprise' deposu devredışı"

  whiptail --backtitle "Proxmox VE 7to8 Upgrade" --msgbox --title "PVE8-Açık Kaynak" "'pve-no-subscription' deposu, Proxmox VE'nin tüm açık kaynaklı bileşenlerine erişim sağlar." 10 58
    msg_info "Açık Kaynak deposu Aktif Hale Getiriliyor"
    cat <<EOF >/etc/apt/sources.list.d/pve-install-repo.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
    msg_ok "Açık Kaynak Deposu Aktif"

  whiptail --backtitle "Proxmox VE 7to8 Upgrade" --msgbox --title "PVE8 CEPH Kaynak Deposu" "'Ceph Paket Depoları' hem 'abonelik gerektirmeyen' hem de 'kurumsal' depolara erişim sağlar." 10 58
    msg_info "'ceph package repositories' Aktif Ediliyor"
    cat <<EOF >/etc/apt/sources.list.d/ceph.list
# deb http://download.proxmox.com/debian/ceph-quincy bookworm enterprise
deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
EOF
    msg_ok "'ceph package repositories'Aktif Edildi"

  whiptail --backtitle "Proxmox VE 7to8 Upgrade" --msgbox --title "PVE8 TEST" "'pvetest' deposu, ileri düzey kullanıcılara resmi olarak yayınlanmadan önce yeni özelliklere ve güncellemelere erişim sağlayabilir (Devre dışı)." 10 58
    msg_info "'pvetest' deposu ekleme ve devre dışı bırakma"
    cat <<EOF >/etc/apt/sources.list.d/pvetest-for-beta.list
# deb http://download.proxmox.com/debian/pve bookworm pvetest
EOF
    msg_ok "'pvetest' repositorysi eklendi"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8 UPDATE" "Updating to Proxmox VE 8" 10 58
    msg_info "Updating to Proxmox VE 8 (Patience)"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -y
    msg_ok "Updated to Proxmox VE 8"

  CHOICE=$(whiptail --backtitle "Proxmox VE 7to8 Upgrade" --title "YENİDEN BAŞLAT" --menu "\nProxmox VE 8 Yeniden Başlatılsın mı? (Tavsiye Edilen)" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Proxmox VE 8 Yeniden Başlıyor"
    sleep 2
    msg_ok "Kurulum Tamamlandı"
    reboot
    ;;
  no)
    msg_error "Yeniden Başlatma Seçilmedi.Yeniden başlatılmalı!."
    msg_ok "Kurulum Tamamlandı"
    ;;
  esac
}

header_info
while true; do
  read -p "Bu Scriptle Proxmox 7 den Proxmox VE 8 e UPGRADE İmkanı sağlanacaktır. (y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) clear; exit ;;
  *) echo "Lütfen  yes yada no." ;;
  esac
done

if ! command -v pveversion >/dev/null 2>&1; then
  header_info
  msg_error "\n  PVE Bulamadım!\n"
  exit
fi

if ! pveversion | grep -Eq "pve-manager/(7\.4-(13|14|15|16|17))"; then
  header_info
  msg_error "Muhtemelen 7.4.13 den küçük yada zaten 8.x bir versiyon kullanıyorsunuz"
  echo -e "  PVE Version 7.4-13 or üstünü destekler.Halen 8.x bir versiyon kullanıyorsanız UI tarafında upgrade yapabilirsiniz."
  echo -e "\nÇıkılıyor...."
  sleep 3
  exit
fi

start_routines
