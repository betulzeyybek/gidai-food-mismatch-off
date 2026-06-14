import re
import unicodedata


def normalize_turkish_text(text: str) -> str:
    if not text:
        return ""

    replacements = {
        "ICINDEKILER": "İÇİNDEKİLER",
        "IÇINDEKILER": "İÇİNDEKİLER",
        "İCİNDEKİLER": "İÇİNDEKİLER",
        "İÇİNDEKİLER": "İÇİNDEKİLER",
        "ICINDEKİLER": "İÇİNDEKİLER",
        "INGREDIENTS": "INGREDIENTS",
        "E- ": "E",
    }

    for wrong, correct in replacements.items():
        text = text.replace(wrong, correct)

    return text


def clean_ocr_text(text: str) -> str:
    if not text:
        return ""

    text = unicodedata.normalize("NFKC", text)
    text = normalize_turkish_text(text)

    text = text.replace("|", "I")
    text = text.replace("•", " ")
    text = text.replace("·", " ")
    text = text.replace("_", " ")

    allowed_pattern = r"[^a-zA-ZğüşöçıİĞÜŞÖÇ0-9\s%.,;:(){}\[\]\-/+]"
    text = re.sub(allowed_pattern, " ", text)

    text = re.sub(r"\s+", " ", text)
    text = re.sub(r"\s+([.,;:%)])", r"\1", text)
    text = re.sub(r"([(])\s+", r"\1", text)

    return text.strip()


def get_lower_text(text: str) -> str:
    return clean_ocr_text(text).lower()


def has_ingredient_keywords(text: str) -> bool:
    lower_text = get_lower_text(text)

    keywords = [
        "içindekiler",
        "icindekiler",
        "ingredients",
        "bileşenler",
        "bilesenler",
        "şeker",
        "seker",
        "glikoz",
        "fruktoz",
        "aroma",
        "kakao",
        "süt",
        "sut",
        "fındık",
        "findik",
        "emülgatör",
        "emulgator",
        "koruyucu",
        "renklendirici",
        "asitlik düzenleyici",
        "e322",
        "e330",
        "e471",
    ]

    return any(keyword in lower_text for keyword in keywords)


def extract_possible_product_name(text: str) -> str | None:
    cleaned = clean_ocr_text(text)

    if not cleaned:
        return None

    bad_phrases = [
        "daha önce",
        "katkısı bulunmayan",
        "eklenmiştir",
        "gıda dedektifi",
        "www.",
        "tüketim tarihi",
        "best before",
        "doğrudan güneş",
        "dogrudan gunes",
        "muhafaza ediniz",
        "saklayınız",
        "saklayiniz",
        "üretilmiştir",
        "uretilmistir",
    ]

    parts = re.split(r"[.;:\n]", cleaned)

    for part in parts:
        candidate = part.strip()

        if not (3 <= len(candidate) <= 80):
            continue

        lower = candidate.lower()

        if any(bad in lower for bad in bad_phrases):
            continue

        if any(key in lower for key in ["içindekiler", "icindekiler", "ingredients"]):
            candidate = re.split(r"içindekiler|icindekiler|ingredients", candidate, flags=re.IGNORECASE)[0].strip(" :;,.")
            if 3 <= len(candidate) <= 80:
                return candidate

        food_name_signals = [
            "çikolata", "cikolata", "kraker", "cracker",
            "bisküvi", "biskuvi", "gofret", "sütlü", "sutlu",
            "bitter", "kakaolu", "kakao", "fındıklı", "findikli",
            "üzümlü", "uzumlu",
        ]

        if any(signal in lower for signal in food_name_signals):
            return candidate

    return None