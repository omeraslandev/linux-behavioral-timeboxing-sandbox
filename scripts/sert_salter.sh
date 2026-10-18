#!/usr/bin/env bash
# ==============================================================================
# File        : scripts/sert_salter.sh
# Description : Smart Process Termination (SIGTERM -> SIGKILL) for Steam & Games
# Installation: cp scripts/sert_salter.sh ~/scripts/ && chmod +x ~/scripts/sert_salter.sh
# ==============================================================================

# Kütüphaneye yeni oyun eklendiğinde sürecin (process) adını buraya ekleyin:
OYUNLAR=(
    "eurotrucks2"
    "Ets2"
    "PolyBridge3"
    "SnowRunner"
    "Frostpunk"
    "Frostpunk2"
    "victoria3"
    "PowerWashSimulator"
)

LOG_FILE="$HOME/scripts/salter.log"
mkdir -p "$HOME/scripts"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sert Şalter Taraması Başladı." >> "$LOG_FILE"

# 1. Aşama: Çalışan Oyunları Güvenli/Zorla Kapatma
for oyun in "${OYUNLAR[@]}"; do
    if pgrep -fi "$oyun" > /dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tespit edildi: $oyun. Kapatılıyor..." >> "$LOG_FILE"
        
        if command -v notify-send &> /dev/null; then
            notify-send -u critical "🔒 Sert Şalter Devrede" "$oyun için 21:30 süresi doldu. Oyun kapatılıyor."
        fi
        
        # Yumuşak kapatma sinyali (SIGTERM - 5 saniye kaydetme imkanı)
        pkill -fi "$oyun"
        sleep 5
        
        # Kapanmadıysa sert kapatma sinyali (SIGKILL)
        if pgrep -fi "$oyun" > /dev/null; then
            pkill -9 -fi "$oyun"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $oyun zorla sonlandırıldı (SIGKILL)." >> "$LOG_FILE"
        fi
    fi
done

# 2. Aşama: Steam İstemcisini Kapatma
if pgrep -f "steam" > /dev/null; then
    pkill -f "steam"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Steam istemcisi sonlandırıldı." >> "$LOG_FILE"
fi