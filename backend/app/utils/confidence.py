from typing import List, Any, Optional

from app.utils.text_cleaner import clean_ocr_text, has_ingredient_keywords


def meaningless_char_ratio(text: str) -> float:
    if not text:
        return 1.0

    allowed = set(
        " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "ğüşöçıİĞÜŞÖÇ0123456789.,;:%()-/+"
    )

    bad_count = sum(1 for ch in text if ch not in allowed)

    return bad_count / max(len(text), 1)


def _get_line_confidence(line: Any) -> Optional[float]:
    """
    OCRLine Pydantic objesi veya dict gelebilir.
    """

    try:
        if isinstance(line, dict):
            return float(line.get("confidence", 0.0))

        return float(line.confidence)

    except Exception:
        return None


def low_confidence_line_ratio(lines: List[Any], threshold: float = 0.75) -> float:
    if not lines:
        return 1.0

    confidences = []

    for line in lines:
        conf = _get_line_confidence(line)
        if conf is not None:
            confidences.append(conf)

    if not confidences:
        return 1.0

    low_count = sum(1 for conf in confidences if conf < threshold)

    return low_count / len(confidences)


def has_clear_ingredient_section(text: str) -> bool:
    """
    İçindekiler / Ingredients bölümünün gerçekten yakalanıp yakalanmadığını kontrol eder.
    """

    cleaned = clean_ocr_text(text).lower()

    section_markers = [
        "içindekiler",
        "icindekiler",
        "ingredients",
        "ingredient",
        "bileşenler",
        "bilesenler",
    ]

    return any(marker in cleaned for marker in section_markers)


def food_content_signal_count(text: str) -> int:
    """
    OCR metninde gıda içerik listesine ait güvenilir sinyal sayısı.
    """

    cleaned = clean_ocr_text(text).lower()

    signals = [
        "şeker",
        "seker",
        "kakao",
        "süt",
        "sut",
        "fındık",
        "findik",
        "aroma",
        "emülgatör",
        "emulgator",
        "soya",
        "lesitin",
        "palm",
        "glikoz",
        "fruktoz",
        "koruyucu",
        "renklendirici",
        "tatlandırıcı",
        "tatlandirici",
        "yağ",
        "yag",
        "un",
        "tuz",
    ]

    return sum(1 for signal in signals if signal in cleaned)


def looks_garbled(text: str) -> bool:
    """
    OCR metni teknik olarak harflerden oluşsa bile anlamsızsa yakalamaya çalışır.
    """

    cleaned = clean_ocr_text(text)
    lower = cleaned.lower()

    suspicious_fragments = [
        "ingeden",
        "chocolae",
        "emgrer",
        "aoma",
        "venci",
        "enej",
        "besi ögele",
        "poyglycerol",
        "glutem",
        "peanats",
        "muts",
        "sakdayinz",
        "belora",
    ]

    suspicious_count = sum(1 for frag in suspicious_fragments if frag in lower)

    words = cleaned.split()
    if not words:
        return True

    very_short_or_weird = 0

    for word in words:
        alpha_count = sum(1 for ch in word if ch.isalpha())
        digit_count = sum(1 for ch in word if ch.isdigit())

        if len(word) >= 5 and alpha_count >= 4:
            vowel_count = sum(1 for ch in word.lower() if ch in "aeıioöuü")
            if vowel_count == 0:
                very_short_or_weird += 1

        if alpha_count > 0 and digit_count > 0 and len(word) > 5:
            very_short_or_weird += 1

    weird_ratio = very_short_or_weird / max(len(words), 1)

    return suspicious_count >= 2 or weird_ratio > 0.18


def should_use_grok_ocr(
    text: str,
    avg_confidence: float,
    lines: Optional[List[Any]] = None,
) -> bool:
    """
    OCR sonucu zayıfsa Grok fallback çalıştırılır.

    Sadece avg_confidence yeterli değildir.
    Çünkü bazı görsellerde toplam ortalama iyi görünür ama içerik satırları bozuk olabilir.
    """

    cleaned = clean_ocr_text(text)

    if not cleaned or len(cleaned.strip()) < 40:
        return True

    if avg_confidence < 0.70:
        return True

    if meaningless_char_ratio(cleaned) > 0.20:
        return True

    if looks_garbled(cleaned):
        return True

    signal_count = food_content_signal_count(cleaned)

    if signal_count < 3:
        return True

    if not has_clear_ingredient_section(cleaned) and avg_confidence < 0.90:
        return True

    if lines:
        low_ratio = low_confidence_line_ratio(lines, threshold=0.75)

        if low_ratio > 0.25 and avg_confidence < 0.88:
            return True

    if not has_ingredient_keywords(cleaned) and avg_confidence < 0.90:
        return True

    return False


def ocr_quality_label(
    text: str,
    avg_confidence: float,
    lines: Optional[List[Any]] = None,
) -> str:
    if should_use_grok_ocr(text, avg_confidence, lines):
        return "low"

    if avg_confidence >= 0.88 and len(text) >= 80:
        return "high"

    return "medium"