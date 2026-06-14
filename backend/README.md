# Food Mismatch Backend

## Kurulum

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# .env içine XAI_API_KEY değerini girin
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Endpointler

- `GET /health`
- `GET /product/barcode/{barcode}`
- `POST /analyze-product` multipart alanları:
  - `front_image`
  - `ingredients_image`
  - opsiyonel: `barcode`, `product_name`, `ingredients_text_from_barcode`

## Flutter test notu

Gerçek telefonda `http://127.0.0.1:8000` çalışmaz. Mac'inizin IP adresini kullanın:

```bash
ipconfig getifaddr en0
```

Flutter çalıştırırken:

```bash
flutter run --dart-define=API_BASE_URL=http://MAC_IP_ADRESI:8000
```
