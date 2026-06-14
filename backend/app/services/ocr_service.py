from typing import Dict, Any, List
import os
import statistics

from paddleocr import PaddleOCR
from PIL import Image

from app.models.schemas import OCRLine
from app.utils.image_preprocess import preprocess_image_for_ocr
from app.utils.text_cleaner import clean_ocr_text


ocr_model = PaddleOCR(
    use_angle_cls=True,
    lang="en"
)


def _is_large_image(image_path: str) -> bool:
    """
    Mobilde iPhone fotoğrafları genelde 3024x4032 gibi çok büyük geliyor.
    Bu durumda hem orijinal hem preprocess OCR çalıştırmak timeout'a sebep olabilir.

    Büyük görsellerde kaliteyi tamamen bozmadan sadece preprocess edilmiş görseli OCR'a sokuyoruz.
    """

    try:
        with Image.open(image_path) as img:
            width, height = img.size

        max_side = max(width, height)
        total_pixels = width * height

        # iPhone fotoğrafları için güvenli sınır.
        if max_side >= 2500:
            return True

        if total_pixels >= 4_000_000:
            return True

        return False

    except Exception:
        return False


def _parse_old_paddle_format(result: Any) -> Dict[str, Any]:
    """
    Eski PaddleOCR formatı:
    [
      [
        [box, (text, confidence)],
        ...
      ]
    ]
    """

    lines: List[OCRLine] = []
    raw_texts: List[str] = []
    confidences: List[float] = []

    if not result:
        return {
            "text": "",
            "avg_confidence": 0.0,
            "lines": [],
            "success": False,
        }

    first_result = result[0] if isinstance(result, list) and len(result) > 0 else result

    if not first_result:
        return {
            "text": "",
            "avg_confidence": 0.0,
            "lines": [],
            "success": False,
        }

    for item in first_result:
        try:
            text = str(item[1][0]).strip()
            confidence = float(item[1][1])
        except Exception:
            continue

        if text:
            raw_texts.append(text)
            confidences.append(confidence)
            lines.append(OCRLine(text=text, confidence=confidence))

    full_text = "\n".join(raw_texts)
    cleaned_text = clean_ocr_text(full_text)
    avg_confidence = statistics.mean(confidences) if confidences else 0.0

    return {
        "text": cleaned_text,
        "avg_confidence": round(avg_confidence, 4),
        "lines": lines,
        "success": bool(cleaned_text),
    }


def _parse_new_paddle_format(result: Any) -> Dict[str, Any]:
    """
    Yeni PaddleOCR / PaddleX formatı:
    [
      {
        'rec_texts': [...],
        'rec_scores': [...]
      }
    ]
    """

    lines: List[OCRLine] = []
    raw_texts: List[str] = []
    confidences: List[float] = []

    if not result:
        return {
            "text": "",
            "avg_confidence": 0.0,
            "lines": [],
            "success": False,
        }

    # Bazı sürümlerde result doğrudan dict olabilir, bazılarında list[dict]
    if isinstance(result, dict):
        result_items = [result]
    elif isinstance(result, list):
        result_items = result
    else:
        result_items = []

    for page in result_items:
        if not isinstance(page, dict):
            continue

        rec_texts = page.get("rec_texts") or page.get("texts") or []
        rec_scores = page.get("rec_scores") or page.get("scores") or []

        for idx, text in enumerate(rec_texts):
            text = str(text).strip()

            if not text:
                continue

            try:
                confidence = float(rec_scores[idx])
            except Exception:
                confidence = 0.0

            raw_texts.append(text)
            confidences.append(confidence)
            lines.append(OCRLine(text=text, confidence=confidence))

    full_text = "\n".join(raw_texts)
    cleaned_text = clean_ocr_text(full_text)
    avg_confidence = statistics.mean(confidences) if confidences else 0.0

    return {
        "text": cleaned_text,
        "avg_confidence": round(avg_confidence, 4),
        "lines": lines,
        "success": bool(cleaned_text),
    }


def _parse_paddle_result(result: Any) -> Dict[str, Any]:
    """
    Hem eski hem yeni PaddleOCR sonucunu destekler.
    """

    new_format = _parse_new_paddle_format(result)

    if new_format["success"]:
        return new_format

    old_format = _parse_old_paddle_format(result)

    if old_format["success"]:
        return old_format

    return {
        "text": "",
        "avg_confidence": 0.0,
        "lines": [],
        "success": False,
    }


def _score_ocr_candidate(parsed: Dict[str, Any]) -> float:
    """
    Orijinal ve ön işlemli görselden gelen OCR sonucunu karşılaştırmak için kalite puanı.
    """

    text = parsed.get("text", "")
    avg_confidence = float(parsed.get("avg_confidence", 0.0))
    line_count = len(parsed.get("lines", []))

    ingredient_bonus = 0

    lower_text = text.lower()

    important_words = [
        "içindekiler",
        "icindekiler",
        "ingredients",
        "ingredient",
        "şeker",
        "seker",
        "sugar",
        "kakao",
        "cocoa",
        "süt",
        "sut",
        "milk",
        "fındık",
        "findik",
        "hazelnut",
        "üzüm",
        "uzum",
        "raisin",
        "emülgatör",
        "emulgator",
        "emulsifier",
        "aroma",
        "flavouring",
        "flavoring",
        "enerji",
        "energy",
        "besin",
        "nutrition",
        "yağ",
        "yag",
        "fat",
        "tuz",
        "salt",
    ]

    for word in important_words:
        if word in lower_text:
            ingredient_bonus += 5

    return (
        (avg_confidence * 100)
        + min(len(text) / 10, 50)
        + min(line_count, 30)
        + ingredient_bonus
    )


def _run_single_ocr(image_path: str) -> Dict[str, Any]:
    try:
        result = ocr_model.ocr(image_path)
        parsed = _parse_paddle_result(result)

        return {
            "source": "paddleocr",
            "text": parsed["text"],
            "avg_confidence": parsed["avg_confidence"],
            "lines": parsed["lines"],
            "fallback_used": False,
            "success": parsed["success"],
        }

    except Exception as exc:
        return {
            "source": "paddleocr",
            "text": "",
            "avg_confidence": 0.0,
            "lines": [],
            "fallback_used": False,
            "success": False,
            "error": str(exc),
        }


def run_paddle_ocr(image_path: str, use_preprocess: bool = True) -> Dict[str, Any]:
    """
    Ana OCR fonksiyonu.

    Normal / küçük görsellerde:
    - Orijinal görseli dener.
    - Ön işlemli görseli dener.
    - Hangisi daha iyi sonuç verirse onu döndürür.

    Büyük mobil fotoğraflarda:
    - Timeout yaşamamak için önce görseli preprocess/küçültme yapar.
    - Sadece optimize edilmiş görselde OCR çalıştırır.

    OCR model ayarları değiştirilmemiştir.
    """

    force_fast_mode = os.getenv("OCR_FAST_MODE", "false").lower() == "true"
    is_large_image = _is_large_image(image_path)

    # Mobil büyük fotoğraflarda hızlı mod
    if use_preprocess and (force_fast_mode or is_large_image):
        try:
            preprocessed_path = preprocess_image_for_ocr(image_path)
            preprocessed_result = _run_single_ocr(preprocessed_path)

            # Preprocess başarısız veya boş OCR dönerse güvenlik için orijinali dener.
            if preprocessed_result.get("success"):
                return preprocessed_result

            original_result = _run_single_ocr(image_path)
            return original_result

        except Exception:
            original_result = _run_single_ocr(image_path)
            return original_result

    # Eski kaliteli çalışma mantığı: orijinal + preprocess karşılaştırması
    candidates = []

    original_result = _run_single_ocr(image_path)
    candidates.append(original_result)

    if use_preprocess:
        try:
            preprocessed_path = preprocess_image_for_ocr(image_path)
            preprocessed_result = _run_single_ocr(preprocessed_path)
            candidates.append(preprocessed_result)
        except Exception:
            pass

    best = max(candidates, key=_score_ocr_candidate)

    return best