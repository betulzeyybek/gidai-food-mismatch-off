import re
import unicodedata
from typing import Dict, List, Optional

from app.utils.text_cleaner import clean_ocr_text


VISUAL_INGREDIENT_KEYWORDS: Dict[str, List[str]] = {
    "çilek": [
        "çilek", "cilek", "çilek püresi", "cilek puresi",
        "çilek suyu", "cilek suyu", "çilek aroması",
        "cilek aroması", "cilek aromasi", "strawberry",
    ],
    "fındık": [
        "fındık", "findik", "fındık ezmesi", "findik ezmesi",
        "fındık püresi", "findik püresi", "findik puresi",
        "fındık aroması", "findik aroması", "findik aromasi",
        "hazelnut", "hazelnuts",
    ],
    "üzüm": [
        "üzüm", "uzum", "kuru üzüm", "kuru uzum",
        "raisin", "raisins",
    ],
    "süt": [
        "süt", "sut", "süt tozu", "sut tozu", "süttozu", "suttozu",
        "yağlı süt tozu", "yagli sut tozu", "whole milk powder",
        "milk powder", "lactose", "laktoz", "dairy product",
        "peynir altı suyu", "peyniralti suyu", "peyniraltı suyu",
    ],
    "kakao": [
        "kakao", "kakao yağı", "kakao yagi", "kakao kitlesi",
        "kakao kütlesi", "kakao tozu", "cocoa", "cocoa mass",
        "cocoa butter", "cocoa powder",
    ],
    "portakal": [
        "portakal", "portakal suyu", "portakal aroması",
        "portakal aromasi", "orange",
    ],
    "limon": [
        "limon", "limon suyu", "limon aroması", "limon aromasi", "lemon",
    ],
    "bal": [
        "bal", "bal aroması", "bal aromasi", "honey",
    ],
    "vanilya": [
        "vanilya", "vanilin", "vanilya özütü", "vanilya ozutu",
        "vanilya aroması", "vanilya aromasi", "vanilla",
    ],
    "muz": [
        "muz", "muz aroması", "muz aromasi", "muz püresi", "muz puresi", "banana",
    ],
    "hindistan cevizi": [
        "hindistan cevizi", "hindistan cevizi aroması",
        "hindistan cevizi aromasi", "coconut",
    ],
}


RISK_KEYWORDS = [
    # Türkçe
    "şeker", "seker",
    "glikoz şurubu", "glikoz surubu",
    "fruktoz şurubu", "fruktoz surubu",
    "yüksek fruktozlu", "yuksek fruktozlu",
    "palm", "palm yağı", "palm yagi",
    "bitkisel yağ", "bitkisel yag",
    "bitkisel yağlar", "bitkisel yaglar",
    "hidrojene",
    "emülgatör", "emulgator",
    "emülgatörler", "emulgatorler",
    "renklendirici", "koruyucu",
    "tatlandırıcı", "tatlandirici",
    "aroma verici", "aroma vericiler",
    "aspartam", "asesülfam", "asesulfam",
    "sodyum nitrit", "monosodyum glutamat",
    "poligliserol polirisinoleat",
    "soya lesitini", "amonyum fosfatitler",
    "sodyum hidroksit",
    "disodyum difosfat",
    "kabartıcı", "kabartici",
    "asitlik düzenleyici", "asitlik duzenleyici",

    # İngilizce
    "sugar",
    "glucose syrup",
    "fructose syrup",
    "vegetable fat",
    "vegetable oil",
    "palm oil",
    "emulsifier",
    "emulsifiers",
    "emulsifer",
    "emulsifers",
    "soy lecithin",
    "soya lecithin",
    "sunflower lecithin",
    "lecithin",
    "flavouring",
    "flavoring",
    "flavour",
    "flavor",
    "polyglycerol polyricinoleate",
    "mono and diglycerides",
    "mono and diacetyl tartaric acid esters",
    "sodium hydroxide",
    "acidity regulator",
    "raising agent",
]


RISK_NORMALIZE_MAP = {
    "seker": "şeker",
    "sugar": "şeker",
    "palm yağı": "palm",
    "palm yagi": "palm",
    "palm oil": "palm",
    "bitkisel yag": "bitkisel yağ",
    "bitkisel yağlar": "bitkisel yağ",
    "bitkisel yaglar": "bitkisel yağ",
    "vegetable fat": "bitkisel yağ",
    "vegetable oil": "bitkisel yağ",
    "emülgatörler": "emülgatör",
    "emulgator": "emülgatör",
    "emulgatorler": "emülgatör",
    "emulsifier": "emülgatör",
    "emulsifiers": "emülgatör",
    "emulsifer": "emülgatör",
    "emulsifers": "emülgatör",
    "soy lecithin": "soya lesitini",
    "soya lecithin": "soya lesitini",
    "sunflower lecithin": "lesitin",
    "lecithin": "lesitin",
    "flavouring": "aroma verici",
    "flavoring": "aroma verici",
    "flavour": "aroma verici",
    "flavor": "aroma verici",
    "aroma vericiler": "aroma verici",
    "polyglycerol polyricinoleate": "poligliserol polirisinoleat",
    "sodium hydroxide": "sodyum hidroksit",
    "acidity regulator": "asitlik düzenleyici",
    "raising agent": "kabartıcı",
}


def normalize_for_search(text: str) -> str:
    if not text:
        return ""

    text = clean_ocr_text(text)
    text = unicodedata.normalize("NFKD", text)

    replacements = {
        "ı": "i", "İ": "i", "i̇": "i",
        "ç": "c", "Ç": "c",
        "ğ": "g", "Ğ": "g",
        "ö": "o", "Ö": "o",
        "ş": "s", "Ş": "s",
        "ü": "u", "Ü": "u",
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    text = text.lower()
    text = re.sub(r"\s+", " ", text)

    return text.strip()


def _cleanup_ingredient_section(section: str) -> str:
    section = clean_ocr_text(section)

    if not section:
        return ""

    section = re.sub(r"\s+", " ", section).strip()
    section = section.strip(" :;,.|-")

    cut_patterns = [
        r"\bkakao\s+enerji\b",
        r"\bkakao\s+kuru\s+maddesi\b",
        r"\bcocoa\s+solids\b",
        r"\btotal\s+dry\s+cocoa\s+solids\b",
        r"\benerji\s+ve\s+besin\b",
        r"\benerji\s+besin\b",
        r"\benerji\s*/\s*energy\b",
        r"\bnutrition\s+information\b",
        r"\bnutrition\s+facts\b",
        r"\bper\s+portion\b",
        r"\bper\s+100\s*g\b",
        r"\b1\s+porsiyon\b",
        r"\b100\s*g\s+için\b",
        r"\b100\s*g\s+icin\b",
        r"\bmay\s+contain\b",
        r"\beser\s+miktarda\b",
        r"\bmade\s+in\b",
        r"\btürkiye\b",
        r"\bturkiye\b",
        r"\büretici\b",
        r"\bmanufacturer\b",
        r"\bbest\s+before\b",
        r"\btavsiye\s+edilen\b",
        r"\bişletme\s+kayıt\b",
        r"\bisletme\s+kayit\b",
    ]

    for pattern in cut_patterns:
        match = re.search(pattern, section, flags=re.IGNORECASE)
        if match:
            section = section[:match.start()]
            break

    section = re.sub(r"\s+[BbEeNn]\s*$", "", section)
    section = re.sub(r"\s+(besin|enerji|nutrition)\s*$", "", section, flags=re.IGNORECASE)

    section = re.sub(
        r"^(ülker|ulker|kakao çekirdeğinden kalplere|kakao cekirdeginden kalplere|kalitesi)\s+",
        "",
        section,
        flags=re.IGNORECASE,
    )

    section = section.strip(" :;,.|-")

    return section


def _extract_candidate_sections(text: str) -> List[str]:
    cleaned = clean_ocr_text(text)
    candidates = []

    start_patterns = [
        r"içindekiler\s*/\s*ingredients\s*:",
        r"içindekiler\s*:",
        r"icindekiler\s*:",
        r"ingredients\s*:",
        r"ingredient\s*:",
        r"bileşenler\s*:",
        r"bilesenler\s*:",
        r"ingreden\s*:",
        r"ingeden\s*:",
    ]

    end_patterns = [
        r"kakao\s+enerji\s+ve\s+besin",
        r"kakao\s+enerji",
        r"kakao\s+kuru\s+maddesi",
        r"cocoa\s+solids",
        r"total\s+dry\s+cocoa\s+solids",
        r"enerji\s+ve\s+besin",
        r"enerji\s+besin",
        r"besin\s+öğeleri",
        r"besin\s+ogeleri",
        r"besin\s+değerleri",
        r"besin\s+degerleri",
        r"nutrition\s+information",
        r"nutrition\s+facts",
        r"per\s+portion",
        r"per\s+100\s*g",
        r"enerji\s*/\s*energy",
        r"energy\s*/\s*enerji",
        r"may\s+contain",
        r"eser\s+miktarda",
        r"made\s+in",
        r"türkiye",
        r"turkiye",
        r"üretici",
        r"manufacturer",
        r"best\s+before",
        r"tavsiye\s+edilen",
        r"işletme\s+kayıt",
        r"isletme\s+kayit",
    ]

    for start_pattern in start_patterns:
        for match in re.finditer(start_pattern, cleaned, flags=re.IGNORECASE):
            start = match.end()
            sliced = cleaned[start:]
            end = len(sliced)

            for end_pattern in end_patterns:
                end_match = re.search(end_pattern, sliced, flags=re.IGNORECASE)
                if end_match:
                    end = min(end, end_match.start())

            candidate = _cleanup_ingredient_section(sliced[:end])
            if candidate and len(candidate) >= 20:
                candidates.append(candidate)

    if not candidates:
        fallback = _cleanup_ingredient_section(cleaned[:800])
        if fallback:
            candidates.append(fallback)

    return candidates


def _score_candidate_section(section: str) -> int:
    lower = section.lower()
    normalized = normalize_for_search(section)

    score = 0

    useful_terms = [
        "şeker", "seker", "sugar",
        "kakao", "cocoa",
        "süt", "sut", "milk",
        "fındık", "findik", "hazelnut",
        "üzüm", "uzum", "raisin",
        "emülgatör", "emulgator", "emulsifier", "emulsifer",
        "soya lesitini", "soy lecithin", "lecithin",
        "aroma", "flavouring", "flavoring",
        "palm", "vegetable",
        "tuz", "salt",
        "lactose",
        "dairy product",
    ]

    for term in useful_terms:
        if term in lower or term in normalized:
            score += 4

    bad_terms = [
        "nutrition", "enerji", "besin", "manufacturer", "üretici",
        "made in", "best before", "tavsiye", "işletme", "isletme",
        "barcode", "consumer service", "www", "net weight", "net ağırlık",
    ]

    for term in bad_terms:
        if term in lower or term in normalized:
            score -= 8

    if len(section) < 40:
        score -= 10

    if len(section) > 700:
        score -= 15

    return score


def extract_ingredients_section(text: str) -> str:
    candidates = _extract_candidate_sections(text)

    if not candidates:
        return ""

    best = max(candidates, key=_score_candidate_section)

    return _cleanup_ingredient_section(best)


def extract_e_codes(text: str) -> List[str]:
    cleaned = clean_ocr_text(text)

    patterns = [
        r"\bE[\s\-]?\d{3,4}[a-zA-Z]?\b",
        r"\be[\s\-]?\d{3,4}[a-zA-Z]?\b",
    ]

    found = []

    for pattern in patterns:
        matches = re.findall(pattern, cleaned)
        for match in matches:
            normalized = match.upper().replace(" ", "").replace("-", "")
            found.append(normalized)

    return sorted(list(set(found)))


def extract_salt_percentage_attention(text: str) -> Optional[str]:
    """
    salt (3,5%) / tuz (%3,5) gibi ifadeleri besin tablosu değil,
    içerik dikkat sinyali olarak yakalar.
    """

    cleaned = clean_ocr_text(text).lower()

    patterns = [
        r"salt\s*\(?\s*(\d{1,2}(?:[.,]\d+)?)\s*%\s*\)?",
        r"tuz\s*\(?\s*%?\s*(\d{1,2}(?:[.,]\d+)?)\s*\)?",
    ]

    for pattern in patterns:
        match = re.search(pattern, cleaned)

        if match:
            value = float(match.group(1).replace(",", "."))
            if value >= 3:
                return "yüksek tuz oranı"

    return None


def extract_aroma_terms(text: str) -> List[str]:
    cleaned = clean_ocr_text(text).lower()

    aroma_terms = []

    aroma_patterns = [
        r"\b[a-zA-ZğüşöçıİĞÜŞÖÇ]{2,25}\s+aroması\b",
        r"\b[a-zA-ZğüşöçıİĞÜŞÖÇ]{2,25}\s+aromasi\b",
        r"\bdoğal aroma\b",
        r"\bdogal aroma\b",
        r"\baroma vericiler\b",
        r"\baroma verici\b",
        r"\bflavouring\b",
        r"\bflavoring\b",
        r"\baroma\b",
    ]

    for pattern in aroma_patterns:
        matches = re.findall(pattern, cleaned)

        for match in matches:
            term = match.strip()

            if term in ["aroma vericiler", "flavouring", "flavoring"]:
                term = "aroma verici"

            if term and term not in aroma_terms:
                aroma_terms.append(term)

    if "aroma verici" in aroma_terms and "aroma" in aroma_terms:
        aroma_terms.remove("aroma")

    return sorted(aroma_terms)


def extract_risk_keywords(text: str) -> List[str]:
    cleaned = clean_ocr_text(text).lower()

    found = []

    for keyword in RISK_KEYWORDS:
        if keyword in cleaned:
            normalized_keyword = RISK_NORMALIZE_MAP.get(keyword, keyword)
            found.append(normalized_keyword)

    salt_attention = extract_salt_percentage_attention(cleaned)

    if salt_attention:
        found.append(salt_attention)

    return sorted(list(set(found)))


def extract_visual_related_ingredients(text: str) -> Dict[str, List[str]]:
    cleaned = clean_ocr_text(text).lower()

    result: Dict[str, List[str]] = {}

    for main_name, variants in VISUAL_INGREDIENT_KEYWORDS.items():
        found_variants = []

        for variant in variants:
            if variant in cleaned:
                found_variants.append(variant)

        result[main_name] = sorted(list(set(found_variants))) if found_variants else []

    return result


def analyze_ingredients(text: str) -> Dict:
    cleaned = clean_ocr_text(text)
    ingredients_section = extract_ingredients_section(cleaned)

    return {
        "cleaned_text": ingredients_section,
        "e_codes": extract_e_codes(ingredients_section),
        "risk_keywords": extract_risk_keywords(ingredients_section),
        "aroma_terms": extract_aroma_terms(ingredients_section),
        "visual_related_ingredients": extract_visual_related_ingredients(ingredients_section),
    }