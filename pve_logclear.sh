#!/usr/bin/env bash

# Script başlığı ve bilgileri
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

# Bilgilendirme mesajları için fonksiyonlar
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

# Script başlık kısmını göster
header_info

# Gerekli dizine geç ve istenen işlemi gerçekleştir
cd /var/log/pve/tasks || { msg_error "Dizin bulunamadı! Çıkılıyor."; exit 1; }

# İlgili dosyaları sil
msg_info "Dosyalar siliniyor"
rm -f active index */UPID*
msg_ok "Dosyalar başarıyla silindi"

