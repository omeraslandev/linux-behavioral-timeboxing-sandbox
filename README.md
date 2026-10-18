# 🔒 Linux Behavioral Timeboxing Sandbox

> **Linux PATH Wrapper ve Cron Tabanlı Davranışsal Zaman Sınırlama Sandboxing Mimarisi**

Bu proje, dijital oyun erişimini **nörobiyolojik ilkelere (dopamin toleransı)** ve **bilişsel psikolojiye (Kahneman Sistem 1 / Sistem 2)** dayalı olarak sınırlayan; işletim sistemi seviyesinde çift aşamalı güvenlik mekanizması sunan bir Linux sandboxing altyapısıdır.

---

## 💡 Neden Bu Sistem? (Bilişsel & Psikolojik Motivasyon)

1. **Dopamin Toleransı & Ödül Değeri:** Günlük tekrarlanan haz eylemleri zamanla zihnin "varsayılan alışkanlığına" dönüşür. Oyun oynama eylemini haftada tek bir zaman penceresine (Cuma 19:30–21:30) sıkıştırmak, onun zihinsel ödül değerini korur.
2. **Sıkıntı Toleransı (Boredom Tolerance):** Zihnin derin okumalardan (ör. *Mukaddime*, *Devlet*) sonra bilgiyi işlemesi için dijital uyaranlardan arınmış "boşluk anlarına" ihtiyacı vardır.
3. **Sistem 1 Tuzaklarını Engelleme:** Kahneman'ın tanımladığı otomatik pilot karar mekanizmasını (Sistem 1) kırarak, irade zayıflığı anlarında oyunların bir "kaçış çukuru" olmasını engeller.

---

## 🛠️ Teknik Mimari (Çift Aşamalı Güvenlik)

Sistem, işletim sistemi katmanında 2 temel mekanizma ile çalışır:

```text
[Kullanıcı "steam" komutunu çalıştırır]
         │
         ▼
 1. AŞAMA: PATH Wrapper (/usr/local/bin/steam)
 ├── Zaman Kontrolü: Cuma 19:30 - 21:30 aralığında mı?
 ├── İZİNLİ  --> /usr/bin/steam çalıştırılır.
 └── YASAKLI --> notify-send ile masaüstü uyarısı basılır & çıkış yapılır (exit 1).
         │
         ▼
 2. AŞAMA: Sert Şalter & Cron (Cuma 21:30)
 ├── Akıllı İnfaz Scripti (~/scripts/sert_salter.sh) tetiklenir.
 ├── OYUNLAR dizisi taranır (pgrep/pkill).
 ├── SIGTERM (5s yumuşak kaydetme süresi) --> SIGKILL (sert kapatma).
 └── Steam süreci kapatılır.

```

---

## 🚀 Kurulum

### 1. Giriş Engelini Kurma (PATH Wrapper)

`/usr/local/bin` dizininin PATH önceliğini kullanarak asıl Steam başlatıcısının önüne engel koyun:

```bash
sudo cp scripts/steam /usr/local/bin/steam
sudo chmod +x /usr/local/bin/steam

```

### 2. Çıkış Engelini Kurma (İnfaz Betiği)

Süre dolduğunda çalışacak akıllı kapatıcıyı yerel ortama taşıyın:

```bash
mkdir -p ~/scripts
cp scripts/sert_salter.sh ~/scripts/
chmod +x ~/scripts/sert_salter.sh

```

### 3. Zamanlanmış Görevi Tanımlama (Cron)

Cuma saat 21:30'da sert şalterin atması için `crontab -e` komutuyla kuralı ekleyin:

```cron
30 21 * * 5 /home/$USER/scripts/sert_salter.sh >> /home/$USER/scripts/salter.log 2>&1

```

---

## 📚 Detaylı Dokümantasyon

Projenin felsefi, teknik ve mimari detaylarına `docs/` klasöründen erişebilirsiniz:

* 📜 **[Haftalık Deşarj Protokolü & 3 Sütun Mimarisi (docs/01-architecture-protocol.md)](https://www.google.com/search?q=docs/01-architecture-protocol.md)**
* 🧠 **[Nörobiyolojik ve Bilişsel Motivasyon Analizi (docs/02-behavioral-motivation.md)](https://www.google.com/search?q=docs/02-behavioral-motivation.md)**
* ⚙️ **[Detaylı Sistem ve Kod Dokümantasyonu (docs/03-technical-implementation.md)](https://www.google.com/search?q=docs/03-technical-implementation.md)**


---

## 📄 Lisans

MIT License
