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
header_info
whiptail --backtitle "Proxmox VE CPU Ölçeklendirme" --title "CPU Ölçeklendirme" --yesno "CPU Ölçekleme Yöneticilerini Görüntüle/Değiştir. Devam edelim mi?Current CPU Scaling Governor is set to " 10 58 || exit
current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
GOVERNORS_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  GOVERNORS_MENU+=("$TAG" "$ITEM " "OFF")
done < <(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors | tr ' ' '\n' | grep -v "$current_governor")
scaling_governor=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Geçerli CPU Ölçekleme Yöneticisi şu şekilde ayarlanmıştır $current_governor" --checklist "\nÖlçeklendirme Yöneticisi:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${GOVERNORS_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit
[ -z "$scaling_governor" ] && {
    whiptail --backtitle "Proxmox VE CPU Ölçeklendirme" --title "Ölçeklendirme için Seçilmedi" --msgbox "" 10 68
    clear
    exit
}
echo "${scaling_governor}" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
whiptail --backtitle "Proxmox VE CPU Ölçeklendirme" --msgbox --title "Mevcut CPU Ölçekleme Yöneticisi" "\nGeçerli CPU Ölçekleme Yöneticisi şu şekilde ayarlanmıştır $current_governor\n" 10 60
CHOICE=$(whiptail --backtitle "Proxmox VE CPU Ölçeklendirme" --title "CPU Ölçekleme Yöneticisi" --menu "Bu, CPU Ölçekleme Yöneticisi yapılandırmasını yeniden başlatmalar arasında korumak için bir crontab oluşturacaktır.\n \nBir crontab Çalıştırayım mı?" 14 68 2 \
  "yes" " " \
  "no" " " 3>&2 2>&1 1>&3)

case $CHOICE in
  yes)
    set +e
    NEW_CRONTAB_COMMAND="(sleep 60 && echo \"$current_governor\" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor)"
    EXISTING_CRONTAB=$(crontab -l 2>/dev/null)
    if [[ -n "$EXISTING_CRONTAB" ]]; then
      TEMP_CRONTAB_FILE=$(mktemp)
      echo "$EXISTING_CRONTAB" | grep -v "@reboot (sleep 60 && echo*" > "$TEMP_CRONTAB_FILE"
      crontab "$TEMP_CRONTAB_FILE"
      rm "$TEMP_CRONTAB_FILE"
    fi
    (crontab -l 2>/dev/null; echo "@reboot $NEW_CRONTAB_COMMAND") | crontab -
    echo -e "\nCrontab Set (use 'crontab -e' to check)"
    ;;
  no)
    echo -e "\n\033[31mNOTE: Yeniden başlatmadan sonra ayarlar varsayılana döner\033[m\n"
    ;;
esac
echo -e "Geçerli CPU Ölçekleme Yöneticisi şu şekilde ayarlanmıştır \033[36m$current_governor\033[m\n"
