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

  CHOICE=$(whiptail --backtitle "PROXMOX GÜNCELLEME" --title "KAYNAKLAR" --menu "Deneme yanılma ile bozduğunuz kaynakları düzeltir. Doğru güncelleme paketleri ile sistem güncellenir.\n \nDoğru Güncelleme verisi girilsin mi?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Kaynaklar Doğrulanıyor.."
    cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
echo 'APT::Get::Update::SourceListWarnings::NonFreeFirmware "false";' >/etc/apt/apt.conf.d/no-bookworm-firmware.conf
    msg_ok "Proxmox VE için kaynaklar doğrulandı "
    ;;
  no)
    msg_error "Kaynak doğrulamasını tercih etmediniz."
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox Güncelleme" --title "PVE-ENTERPRISE Kaynağı" --menu "PVE Enterprise destek almadıysanız,Bu özelliği kapatabilirsiniz.\n \nEnterprise Kaynağını kapat?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info " 'pve-enterprise' Kaynağı Devre Dışı Bırakılıyor "
    cat <<EOF >/etc/apt/sources.list.d/pve-enterprise.list
# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
EOF
    msg_ok "'pve-enterprise' Kaynağı Devre Dışı Bırakıldı"
    ;;
  no)
    msg_error "'pve-enterprise' Değiştirilmeden Bırakıldı"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox Güncelleme" --title "PVE Açık Kaynak Deposu" --menu "'pve-no-subscription' deposu Proxmox VE'nin tüm açık kaynak bileşenlerine erişim sağlar.\n \nAçık Kaynak Deposu Aktif Edilsin mi?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Açık Kaynak Deposu Aktif Ediliyor"
    cat <<EOF >/etc/apt/sources.list.d/pve-install-repo.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
    msg_ok "Açık Kaynak Deposu Aktif Edildi"
    ;;
  no)
    msg_error "Açık Kaynak Depoyu Kullanmamayı Tercih Ettiniz"
    ;;
  esac

    CHOICE=$(whiptail --backtitle "Proxmox Güncelleme" --title "CEPH Kaynak Deposu" --menu "'Ceph Paket Depoları' hem 'abonelik gerektirmeyen' hem de 'kurumsal' depolara erişim sağlar (başlangıçta devre dışı bırakılmıştır).\n \nCEPH Depolarını ve CEPH i Aktif Edeyi mi?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "CEPH Kaynak Depoları Aktif Ediliyor"
      cat <<EOF >/etc/apt/sources.list.d/ceph.list
# deb http://download.proxmox.com/debian/ceph-quincy bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
# deb http://download.proxmox.com/debian/ceph-reef bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-reef bookworm no-subscription
EOF
      msg_ok "CEPH Kaynak Depolar Aktifleştirildi"
      ;;
    no)
      msg_error "CEPH için Kaynak Depo aktifleştirilmesi İptal edildi"
      ;;
    esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Güncelleme" --title "TEST ORTAMLARI" --menu "Test kurulumları ve paketleri içerir.Canlı ortam için tavsiye edilmez.\n \nTEST Kaynağını DevreDışı Bırakayı mı?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Test Deposu Devre Dışı Bırakılıyor"
    cat <<EOF >/etc/apt/sources.list.d/pvetest-for-beta.list
# deb http://download.proxmox.com/debian/pve bookworm pvetest
EOF
    msg_ok "Test Deposu Eklendi"
    ;;
  no)
    msg_error "Test Deposu Devre Dışı"
    ;;
  esac

  if [[ ! -f /etc/apt/apt.conf.d/no-nag-script ]]; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Güncelleme" --title "ABONELİK UYARISI" --menu "Web üzerinden her giriş yaptığınızda Abone uyarısı görürsünüz.\n \nBu Uyarı Devre Dışı Bırakılsın mı?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      whiptail --backtitle "Proxmox VE Güncelleme" --msgbox --title "Abonelik Desteği" "Abonelik desteğini ve uyarılarını kaldırır" 10 58
      msg_info "Abonelik Uyarıları Kaldırılıyor"
        echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Arayüzden de Kaldırılıyor...'; sed -i '/.*data\.status.*{/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" >/etc/apt/apt.conf.d/no-nag-script
      apt --reinstall install proxmox-widget-toolkit &>/dev/null
      msg_ok "Devre Dışı Bırakıldı.Browserınızın cache ni temizleyiniz"
      ;;
    no)
      whiptail --backtitle "Proxmox VE Güncelleme" --msgbox --title "Abonelik Desteği" "Abonelik Desteği İhtiyaç dahilinde tekrar aktif edilebilir" 10 58
      msg_error "Abonelik Hizmeti Bıraktığınız gibi"
      ;;
    esac
  fi

  if ! systemctl is-active --quiet pve-ha-lrm; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Güncelleme" --title "HIGH AVAILABILITY" --menu "high availability Aktif edilsin mi?" 10 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "High availability Aktif Ediliyor"
      systemctl enable -q --now pve-ha-lrm
      systemctl enable -q --now pve-ha-crm
      systemctl enable -q --now corosync
      msg_ok "High availability Aktif"
      ;;
    no)
      msg_error "High availability Aktif Değil"
      ;;
    esac
  fi
  
  if systemctl is-active --quiet pve-ha-lrm; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Güncelleme" --title "HIGH AVAILABILITY" --menu "Cluster Yapısını değiştirmek ve Clusterdan vazgeçmek için.\n\nHigh availability Devre Dışı Bırakayım mı?" 18 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "High availability Devre Dışı Ediliyor"
      systemctl disable -q --now pve-ha-lrm
      systemctl disable -q --now pve-ha-crm
      systemctl disable -q --now corosync
      msg_ok "High availability Devre Dışı"
      ;;
    no)
      msg_error "High availability olduğu gibi bırakıldı"
      ;;
    esac
  fi
  
  CHOICE=$(whiptail --backtitle "Proxmox VE Güncelleme" --title "GÜNCELLE" --menu "\nŞimdi Güncelleyi mi?" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Proxmox Güncelleniyor"
    apt-get update &>/dev/null
    apt-get -y dist-upgrade &>/dev/null
    msg_ok " Proxmox Güncellendi"
    ;;
  no)
    msg_error "Güncellemeyi seçmediniz.Herhangi bir değişiklik olmayacak"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Güncelleme" --title "YENİDEN BAŞLAT" --menu "\nYeniden Başlatılsın mı? (Muhakkak Edin)" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Proxmox Yeniden Başlıyor"
    sleep 2
    msg_ok "Kurulumlar Tamamlandı"
    reboot
    ;;
  no)
    msg_error "Kurulumlar Tamamlandı (Yeniden başlatmayı unutma)"
    msg_ok "Kurulumlar Tamamlandı"
    ;;
  esac
}





header_info
echo -e "\nPROXMOX 8 ve ÜZERİ İÇİN GÜNCELLEME,AYAR PAKETLERİNİ İÇERİR..\n"
while true; do
  read -p "Bu Paketin sorumluluğu sizin üzerinizdedir.Devam etmek ister misin (y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) clear; exit ;;
  *) echo "Sadece yes yada  no." ;;
  esac
done

if ! pveversion | grep -Eq "pve-manager/8.[0-2]"; then
  msg_error "Bu Script sadece 8 ve üzerini desteklemektedir."
  echo -e "Proxmox Virtual Environment Version 8.0 ve üzerini destekler. 8 ve altı için çalışmam devam etmektedir.Bana mail ile ulaşabilirsin.husnu@husnuapak.com"
  echo -e "Çıkılıyor..."
  sleep 2
  exit
fi

start_routines
