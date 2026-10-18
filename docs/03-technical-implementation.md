# **Steam Ödül Sistemi Sandboxing Dokümantasyonu (Hibrit Mimari)**

Bu doküman, dijital oyun erişimini **çift aşamalı emniyet mekanizması** ile kilit altına alan hibrit teknik mimariyi tanımlar:

1. **Giriş Engeli (PATH Wrapper):** Belirlenen zaman penceresi dışında Steam’in açılmasını işletim sistemi seviyesinde engeller.
2. **Esnek Çıkış Engeli (Akıllı İnfaz Script'i + Cron):** Süre dolduğunda (21:30) açık olan oyuna 5 saniyelik güvenli kaydetme penceresi sunar, ardından oyunu ve Steam’i otomatik kapatır.

* **İzin Verilen Pencere:** Sadece **Cuma günleri 19:30 – 21:30** arası (2 Saat).

---

## **1. AŞAMA: Giriş Kilidi (`/usr/local/bin/steam`)**

PATH önceliğinden yararlanılarak asıl Steam başlatıcısının (`/usr/bin/steam`) önüne bir sarmalayıcı (wrapper) betik yerleştirilmiştir.

### **Uygulama Adımları:**

Dosyayı açmak ve düzenlemek için:

```bash
sudo nano /usr/local/bin/steam

```

Çalıştırılabilir haklarını vermek için:

```bash
sudo chmod +x /usr/local/bin/steam

```

### **Sarmalayıcı Kod (`/usr/local/bin/steam`):**

```bash
#!/bin/bash

# Gün kontrolü (%u: 1=Pazartesi, 5=Cuma, 7=Pazar)
DAY=$(date +%u)

# Saat ve dakikayı dakika cinsine çevirerek hassas kıyaslama yapıyoruz
HOUR=$(date +%H)
MIN=$(date +%M)
TOTAL_MINS=$(( 10#$HOUR * 60 + 10#$MIN ))

# İzin Verilen Aralık: Cuma (5. gün) ve 19:30 (1170 dk) - 21:30 (1290 dk) arası
START_MINS=$(( 19 * 60 + 30 )) # 1170. dakika
END_MINS=$(( 21 * 60 + 30 ))   # 1290. dakika

if [ "$DAY" -eq 5 ] && [ "$TOTAL_MINS" -ge "$START_MINS" ] && [ "$TOTAL_MINS" -le "$END_MINS" ]; then
    echo "[Özgürlük Alanı] Cuma 19:30 - 21:30 aralığındasınız. Steam başlatılıyor..."
    exec /usr/bin/steam "$@"
else
    # Terminal ve Masaüstü Bildirimi
    echo -e "\n=================================================="
    echo -e "🔒 STEAM İRADE KİLİDİ AKTİF"
    echo -e "Giriş İzni: Sadece Cuma Günleri 19:30 - 21:30 arası."
    echo -e "Şu anki Zaman: $(date '+%A %H:%M')"
    echo -e "==================================================\n"
    
    # Masaüstü grafik bildirimi gönder
    if command -v notify-send &> /dev/null; then
        notify-send -u critical "🔒 Steam İrade Kilidi" "Steam sadece Cuma 19:30 - 21:30 arasında açılabilir.\nŞu an: $(date '+%A %H:%M')" -i dialog-warning
    fi
    
    exit 1
fi

```

---

## **2. AŞAMA: Esnek Çıkış Betiği (`~/scripts/sert_salter.sh`)**

Yeni oyunlar eklendiğinde `crontab` düzenleme ihtiyacını ortadan kaldıran, 2 aşamalı (SIGTERM -> SIGKILL) akıllı infaz betiğidir.

### **Uygulama Adımları:**

Klasörü oluşturup betik dosyasını açmak için:

```bash
mkdir -p ~/scripts
nano ~/scripts/sert_salter.sh

```

Çalıştırılabilir haklarını vermek için:

```bash
chmod +x ~/scripts/sert_salter.sh

```

### **Bileşik İnfaz Kodu (`~/scripts/sert_salter.sh`):**

```bash
#!/bin/bash
# ==============================================================================
# HAFTALIK DEŞARJ PROTOKOLÜ - SERT ŞALTER
# Cuma 21:30 Otomatik Oyun & Steam Kapatıcı
# ==============================================================================

# Kütüphaneye yeni oyun eklendiğinde sürecin (process) adını buraya eklemen yeterlidir:
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
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sert Şalter Taraması Başladı." >> "$LOG_FILE"

# 1. Aşama: Çalışan Oyunları Güvenli/Zorla Kapatma
for oyun in "${OYUNLAR[@]}"; do
    if pgrep -fi "$oyun" > /dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tespit edildi: $oyun. Kapatılıyor..." >> "$LOG_FILE"
        
        # Masaüstü uyarısı gönder
        if command -v notify-send &> /dev/null; then
            notify-send -u critical "🔒 Sert Şalter Devrede" "$oyun için 21:30 süresi doldu. Oyun kapatılıyor."
        fi
        
        # Yumuşak kapatma sinyali (SIGTERM - 5 saniye kaydetme imkanı)
        pkill -fi "$oyun"
        sleep 5
        
        # Hala kapanmadıysa sert kapatma sinyali (SIGKILL)
        if pgrep -fi "$oyun" > /dev/null; then
            pkill -9 -fi "$oyun"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $oyun zorla sonlandırıldı (SIGKILL)." >> "$LOG_FILE"
        fi
    fi
done

# 2. Aşama: Steam Sürecini Kapatma
if pgrep -f "steam" > /dev/null; then
    pkill -f "steam"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Steam istemcisi sonlandırıldı." >> "$LOG_FILE"
fi

```

---

## **3. AŞAMA: Zamanlanmış Görev (`crontab`)**

Her Cuma saat tam 21:30'da arka planda tetiklenen tek satırlık cron kuralıdır.

### **Uygulama Adımları:**

Cron düzenleyicisini açmak için:

```bash
crontab -e

```

En alt satıra eklenecek kural:

```cron
30 21 * * 5 /home/$USER/scripts/sert_salter.sh >> /home/$USER/scripts/salter.log 2>&1

```

---

## **Yeni Oyun Ekleme Protokolü**

Kütüphaneye kurala uygun yeni bir oyun eklendiğinde yapılması gereken tek işlem:

1. Oyunun süreç adını bul:
```bash
pgrep -l -f "oyun_adi"

```


2. `~/scripts/sert_salter.sh` dosyasını açıp `OYUNLAR` dizisinin içine tırnak içinde sürecin adını yazmak. `crontab` veya `/usr/local/bin/steam` dosyalarına tekrar dokunmaya gerek kalmaz.