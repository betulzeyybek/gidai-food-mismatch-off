import base64
import json
import os
import re
import tempfile
from pathlib import Path
from typing import Dict, List

import cv2
from dotenv import load_dotenv
from openai import OpenAI

from app.utils.text_cleaner import clean_ocr_text

load_dotenv()


def _prepare_image_for_grok(image_path: str, max_side: int = 1100, quality: int = 78) -> str:
    """
    Grok'a büyük fotoğraf göndermek çok yavaşlatıyor.
    Bu fonksiyon görseli küçültür ve JPEG olarak sıkıştırır.
    OCR dosyasına dokunmaz, sadece Grok için geçici kopya oluşturur.
    """

    image = cv2.imread(image_path)

    if image is None:
        return image_path

    height, width = image.shape[:2]
    longest_side = max(height, width)

    if longest_side > max_side:
        scale = max_side / longest_side
        new_width = int(width * scale)
        new_height = int(height * scale)
        image = cv2.resize(image, (new_width, new_height), interpolation=cv2.INTER_AREA)

    temp_dir = tempfile.mkdtemp()
    output_path = os.path.join(temp_dir, "grok_fast_image.jpg")

    cv2.imwrite(
        output_path,
        image,
        [
            int(cv2.IMWRITE_JPEG_QUALITY),
            quality,
        ],
    )

    return output_path


def _encode_image_to_base64(image_path: str) -> str:
    path = Path(image_path)

    if not path.exists():
        raise FileNotFoundError(f"Görüntü bulunamadı: {image_path}")

    suffix = path.suffix.lower()

    if suffix in [".jpg", ".jpeg"]:
        mime_type = "image/jpeg"
    elif suffix == ".png":
        mime_type = "image/png"
    else:
        mime_type = "image/jpeg"

    with open(path, "rb") as image_file:
        encoded = base64.b64encode(image_file.read()).decode("utf-8")

    return f"data:{mime_type};base64,{encoded}"


def _get_xai_client() -> OpenAI:
    api_key = os.getenv("XAI_API_KEY")

    if not api_key:
        raise RuntimeError("XAI_API_KEY .env içinde bulunamadı.")

    timeout_seconds = float(os.getenv("XAI_TIMEOUT_SECONDS", "15"))

    return OpenAI(
        api_key=api_key,
        base_url="https://api.x.ai/v1",
        timeout=timeout_seconds,
        max_retries=0,
    )


def _extract_json_object(text: str) -> Dict:
    if not text:
        return {}

    cleaned = text.strip()

    try:
        return json.loads(cleaned)
    except Exception:
        pass

    match = re.search(r"\{.*\}", cleaned, flags=re.DOTALL)

    if not match:
        return {}

    try:
        return json.loads(match.group(0))
    except Exception:
        return {}


def _normalize_visual_label(label: str) -> str:
    lower = label.lower().strip()

    mapping = {
        "milk": "süt",
        "süt": "süt",
        "sut": "süt",
        "dairy": "süt",
        "yogurt": "süt",
        "yoğurt": "süt",

        "cocoa": "kakao",
        "kakao": "kakao",
        "chocolate": "kakao",
        "çikolata": "kakao",
        "cikolata": "kakao",

        "hazelnut": "fındık",
        "hazelnuts": "fındık",
        "fındık": "fındık",
        "findik": "fındık",

        "strawberry": "çilek",
        "strawberries": "çilek",
        "çilek": "çilek",
        "cilek": "çilek",

        "raisin": "üzüm",
        "raisins": "üzüm",
        "grape": "üzüm",
        "grapes": "üzüm",
        "üzüm": "üzüm",
        "uzum": "üzüm",

        "orange": "portakal",
        "portakal": "portakal",

        "lemon": "limon",
        "limon": "limon",

        "honey": "bal",
        "bal": "bal",

        "vanilla": "vanilya",
        "vanilya": "vanilya",

        "banana": "muz",
        "muz": "muz",

        "coconut": "hindistan cevizi",
        "hindistan cevizi": "hindistan cevizi",

        "oat": "yulaf",
        "oats": "yulaf",
        "yulaf": "yulaf",

        "wheat": "buğday",
        "buğday": "buğday",
        "bugday": "buğday",
    }

    return mapping.get(lower, lower)


def _unique_clean_list(values: List[str]) -> List[str]:
    result = []

    if not isinstance(values, list):
        return result

    for value in values:
        if not value:
            continue

        normalized = _normalize_visual_label(str(value))

        if normalized and normalized not in result:
            result.append(normalized)

    return result


def run_grok_vision_ocr(image_path: str) -> str:
    """
    PaddleOCR başarısız olduğunda Grok Vision ile içerik metni çıkarır.
    Bu fallback artık süre limitli çalışır.
    """

    model = os.getenv("XAI_MODEL", "grok-4.3")
    client = _get_xai_client()

    fast_image_path = _prepare_image_for_grok(
        image_path,
        max_side=1200,
        quality=80,
    )

    image_data = _encode_image_to_base64(fast_image_path)

    prompt = """
Bu görsel bir paketli gıda ürününün içerik/etiket fotoğrafı olabilir.
Görevin:
1. Görseldeki metni mümkün olduğunca doğru OCR olarak çıkar.
2. Özellikle 'İçindekiler', 'Ingredients', aroma, E-kodları, katkı maddeleri ve alerjen ifadelerini yakala.
3. Sadece okunabilen metni döndür.
4. Açıklama, yorum, analiz, madde işareti ekleme.
5. Emin olmadığın kelimeleri tahmin ederek uydurma; okunamıyorsa boş bırak.
"""

    completion = client.chat.completions.create(
        model=model,
        temperature=0,
        messages=[
            {
                "role": "system",
                "content": "Sen gıda ambalajı etiketlerinden metin çıkaran dikkatli bir OCR yardımcısısın.",
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt,
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": image_data,
                        },
                    },
                ],
            },
        ],
    )

    content = completion.choices[0].message.content or ""

    return clean_ocr_text(content)


def detect_visual_claims_with_grok(image_path: str) -> Dict:
    """
    Ambalaj ön yüzündeki görsel vaatleri Grok Vision ile tespit eder.
    Bu fonksiyon hızlı çalışması için görseli küçültüp gönderir.
    Grok geç cevap verirse exception fırlatır; main.py bunu yakalayıp analizi devam ettirir.
    """

    model = os.getenv("XAI_MODEL", "grok-4.3")
    client = _get_xai_client()

    fast_image_path = _prepare_image_for_grok(
        image_path,
        max_side=1000,
        quality=75,
    )

    image_data = _encode_image_to_base64(fast_image_path)

    prompt = """
Bu görsel bir paketli gıda ürününün ÖN YÜZ ambalaj fotoğrafıdır.

Görevin:
1. Ambalaj üzerinde görülen gıda görsellerini tespit et.
2. Sadece gerçekten görsel olarak görünen veya ambalajda açıkça vurgulanan gıda unsurlarını yaz.
3. Ürün üzerindeki iddiaları da kısa şekilde çıkar. Örnek: yüksek lif, kalsiyum, demir, protein, şekersiz.
4. Cevabı SADECE JSON olarak döndür.
5. JSON dışı açıklama yazma.

Önemli:
- detected_visuals alanındaki etiketler mümkünse şu Türkçe anahtarlarla uyumlu olsun:
  kakao, süt, fındık, çilek, üzüm, portakal, limon, bal, vanilya, muz, hindistan cevizi, yulaf, buğday
- Emin olmadığın görselleri ekleme.
- Logo, marka, tabak, kaşık, kase, bardak gibi gıda olmayan nesneleri detected_visuals içine ekleme.

JSON formatı:
{
  "detected_visuals": ["kakao", "yulaf"],
  "visual_claims": ["yüksek lif", "kalsiyum", "demir"],
  "product_type": "granola",
  "confidence": 0.85
}
"""

    completion = client.chat.completions.create(
        model=model,
        temperature=0,
        messages=[
            {
                "role": "system",
                "content": (
                    "Sen gıda ambalajlarının ön yüzündeki görsel vaatleri tespit eden "
                    "dikkatli bir bilgisayarlı görü yardımcısısın. Sadece JSON döndürürsün."
                ),
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt,
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": image_data,
                        },
                    },
                ],
            },
        ],
    )

    content = completion.choices[0].message.content or ""
    parsed = _extract_json_object(content)

    detected_visuals = _unique_clean_list(parsed.get("detected_visuals", []))

    visual_claims = parsed.get("visual_claims", [])
    if not isinstance(visual_claims, list):
        visual_claims = []

    product_type = parsed.get("product_type")
    confidence = parsed.get("confidence", 0.0)

    try:
        confidence = float(confidence)
    except Exception:
        confidence = 0.0

    return {
        "detected_visuals": detected_visuals,
        "visual_claims": [str(x).strip() for x in visual_claims if str(x).strip()],
        "product_type": str(product_type).strip() if product_type else None,
        "confidence": max(0.0, min(confidence, 1.0)),
        "source": "grok_vision",
    }