# Food Mismatch – Gıda Ambalaj İçerik Analiz Sistemi

Food Mismatch, gıda ürünlerinin ambalaj görselleri ile içerik listesi arasındaki uyumsuzlukları analiz eden yapay zeka destekli bir mobil uygulama prototipidir.

Proje; ambalajda öne çıkarılan çilek, fındık, süt, kakao gibi vaatlerin gerçekten içerikte bulunup bulunmadığını kontrol eder ve kullanıcıya **yanıltıcılık skoru** ile **sağlık risk skoru** sunar.

---

## Temel Özellikler

- Barkod ile ürün arama
- OpenFoodFacts API üzerinden ürün bilgisi çekme
- Ambalaj ve içindekiler fotoğrafı ile analiz
- Grok Vision destekli görsel vaat tespiti
- OCR ve gerektiğinde Grok destekli içerik okuma
- E-kodu ve katkı maddesi çıkarımı
- Yanıltıcılık ve sağlık risk skoru hesaplama
- Firebase Authentication ile kullanıcı girişi
- Yapılan analizleri “Kayıtlarım” ekranında saklama

---

## Kullanılan Teknolojiler

### Mobil
- Flutter
- Dart
- Firebase Authentication
- SharedPreferences
- Image Picker

### Backend
- FastAPI
- Python
- Uvicorn
- OpenFoodFacts API
- Grok API

### Analiz
- Grok Vision
- OCR
- Regex tabanlı E-kodu çıkarımı
- Kural tabanlı skor hesaplama

---

## Proje Yapısı

```text
food-mismatch-off/
│
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   └── services/
│   │       ├── grok_client.py
│   │       ├── local_ocr.py
│   │       ├── openfoodfacts.py
│   │       └── text_utils.py
│   ├── requirements.txt
│   └── .env.example
│
├── food_mismatch_off/
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   └── main.dart
│   └── pubspec.yaml
│
└── README.md
```

---

## Sistem Akışı

```text
Kullanıcı ürün analizi başlatır
        |
        |-- Barkod ile analiz
        |       └── OpenFoodFacts API’den ürün bilgisi alınır
        |
        |-- Fotoğraf ile analiz
                |-- Ambalaj ön yüzü Grok Vision ile analiz edilir
                |-- İçindekiler OCR ile okunur
                |-- OCR yetersizse Grok destekli okuma yapılır

Sonuç:
- İçerik metni temizlenir
- E-kodları çıkarılır
- Görsel vaat ve içerik karşılaştırılır
- Yanıltıcılık skoru hesaplanır
- Sağlık risk skoru hesaplanır
```

---

## Skor Mantığı

### Yanıltıcılık Skoru

Ambalaj vaadi ile gerçek içerik karşılaştırılır.

Örneğin:

- Çilek görseli var ama gerçek çilek yoksa skor artar.
- Fındık üründe çok düşük orandaysa skor artar.
- Gerçek içerik yerine aroma kullanılmışsa skor artar.

```text
0 - 30   : Düşük
31 - 60  : Orta
61 - 100 : Yüksek
```

### Sağlık Risk Skoru

Sağlık skoru; E-kodları ve içerikte geçen bazı dikkat gerektiren ifadeler üzerinden hesaplanır.

Dikkate alınan örnek ifadeler:

- Palm yağı
- Hidrojene yağ
- Aroma / vanilin
- Emülgatör
- Glukoz-fruktoz şurubu
- Tatlandırıcılar
- Fosforik asit
- Zero sugar / şekersiz ürün içerikleri

```text
0 - 19   : Düşük
20 - 54  : Orta
55 - 100 : Yüksek
```

---

## Backend Kurulumu

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cp .env.example .env
```

`.env` dosyasına Grok API key eklenir:

```env
XAI_API_KEY=your_xai_api_key
XAI_MODEL=grok-4.3
XAI_BASE_URL=https://api.x.ai/v1
ALLOW_FAKE_GROK=false
```

Backend başlatılır:

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Test:

```bash
curl http://127.0.0.1:8000/health
```

---

## Mobil Uygulama Kurulumu

```bash
cd food_mismatch_off
flutter pub get
```

Gerçek cihazda çalıştırmak için Mac IP adresi alınır:

```bash
ipconfig getifaddr en0
```

Uygulama çalıştırılır:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_MAC_IP:8000
```

Release mod:

```bash
flutter run --release --dart-define=API_BASE_URL=http://YOUR_MAC_IP:8000
```

---

## API Endpointleri

```http
GET /health
GET /product/barcode/{barcode}
GET /analyze-barcode/{barcode}
POST /analyze-product
```

Örnek test:

```bash
curl http://127.0.0.1:8000/analyze-barcode/3017620422003
```

---

## Güvenlik Notu

Grok API key `.env` dosyasında tutulur ve GitHub’a yüklenmemelidir.

`.gitignore` içinde şu satırlar bulunmalıdır:

```gitignore
.env
*.env
backend/.env
backend/.venv/
```

---

## Proje Durumu

Bu proje yarışma ve bitirme projesi sunumu için geliştirilmiş çalışan bir prototiptir.

Mevcut sürümde:

- Mobil uygulama çalışmaktadır.
- Backend API çalışmaktadır.
- Barkod analizi yapılabilmektedir.
- Fotoğrafla analiz desteklenmektedir.
- Grok Vision entegrasyonu eklenmiştir.
- Analiz geçmişi “Kayıtlarım” ekranında saklanmaktadır.

---

## Geliştirilebilecek Yönler

- Özel YOLO modeli ile görsel vaat tespiti geliştirilebilir.
- OCR doğruluğu artırılabilir.
- Katkı maddesi risk sınıflandırması genişletilebilir.
- Analiz sonuçları bulut veritabanında saklanabilir.
- Daha geniş ürün veri setiyle test yapılabilir.
