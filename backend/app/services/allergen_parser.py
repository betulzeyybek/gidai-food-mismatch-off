import re
import unicodedata
from typing import Dict, List, Tuple

from app.utils.text_cleaner import clean_ocr_text


ALLERGEN_KEYWORDS: Dict[str, List[str]] = {
    "gluten içeren tahıllar": [
        "gluten", "buğday", "bugday", "wheat", "arpa", "barley",
        "çavdar", "cavdar", "rye", "yulaf", "oat", "oats",
        "spelt", "kamut", "durum wheat", "semolina",
    ],
    "süt": [
        "süt", "sut", "milk", "laktoz", "lactose", "whey",
        "peynir altı suyu", "peyniralti suyu", "casein", "kazein",
        "milk powder", "süt tozu", "sut tozu", "dairy", "dairy product",
    ],
    "soya": [
        "soya", "soy", "soybean", "soybeans", "soy lecithin",
        "soya lecithin", "soya lesitini", "soya fasulyesi",
    ],
    "yer fıstığı": [
        "yer fıstığı", "yer fistigi", "peanut", "peanuts",
        "groundnut", "groundnuts",
    ],
    "sert kabuklu meyveler": [
        "sert kabuklu", "sert kabuklu meyveler", "nuts", "tree nuts",
        "fındık", "findik", "hazelnut", "hazelnuts",
        "badem", "almond", "almonds",
        "ceviz", "walnut", "walnuts",
        "antep fıstığı", "antep fistigi", "pistachio", "pistachios",
        "kaju", "cashew", "cashews",
        "pecan", "pekan",
        "macadamia", "brazil nut",
    ],
    "yumurta": [
        "yumurta", "egg", "eggs", "albumin", "ovalbumin",
    ],
    "susam": [
        "susam", "sesame", "sesame seed", "sesame seeds",
    ],
    "hardal": [
        "hardal", "mustard",
    ],
    "kereviz": [
        "kereviz", "celery",
    ],
    "balık": [
        "balık", "balik", "fish",
    ],
    "kabuklu deniz ürünleri": [
        "kabuklu deniz", "crustacean", "crustaceans", "shrimp",
        "prawn", "crab", "lobster",
    ],
    "yumuşakçalar": [
        "yumuşakça", "yumusakca", "mollusc", "molluscs",
        "mussel", "oyster", "squid",
    ],
    "acı bakla": [
        "acı bakla", "aci bakla", "lupin", "lupine",
    ],
    "sülfit": [
        "sülfit", "sulfit", "sulfite", "sulphite",
        "sulfur dioxide", "kükürt dioksit", "kukurt dioksit",
    ],
}


MAY_CONTAIN_MARKERS = [
    "içerebilir",
    "icerebilir",
    "eser miktarda",
    "iz miktarda",
    "may contain",
    "may includes",
    "may include",
    "traces of",
    "trace of",
    "üretim hattında",
    "uretim hattinda",
    "aynı hatta",
    "ayni hatta",
]


CONTAINS_MARKERS = [
    "içerir",
    "icerir",
    "contains",
    "allergen",
    "alerjen",
]


def _normalize(text: str) -> str:
    text = clean_ocr_text(text or "")
    text = unicodedata.normalize("NFKD", text)

    replacements = {
        "ı": "i",
        "İ": "i",
        "ç": "c",
        "Ç": "c",
        "ğ": "g",
        "Ğ": "g",
        "ö": "o",
        "Ö": "o",
        "ş": "s",
        "Ş": "s",
        "ü": "u",
        "Ü": "u",
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    text = text.lower()
    text = re.sub(r"\s+", " ", text)

    return text.strip()


def _term_exists(normalized_text: str, term: str) -> bool:
    normalized_term = _normalize(term)

    if not normalized_term:
        return False

    pattern = r"(^|[^a-z0-9])" + re.escape(normalized_term) + r"([^a-z0-9]|$)"

    return re.search(pattern, normalized_text) is not None


def _near_marker(normalized_text: str, term: str, markers: List[str], window: int = 90) -> bool:
    normalized_term = _normalize(term)

    if not normalized_term:
        return False

    index = normalized_text.find(normalized_term)

    if index == -1:
        return False

    start = max(0, index - window)
    end = min(len(normalized_text), index + len(normalized_term) + window)

    context = normalized_text[start:end]

    return any(_normalize(marker) in context for marker in markers)


def _find_allergens(text: str) -> Tuple[List[str], List[str], List[str]]:
    normalized_text = _normalize(text)

    contains = []
    may_contain = []
    found_terms = []

    for allergen_name, terms in ALLERGEN_KEYWORDS.items():
        allergen_found = False
        allergen_may = False

        for term in terms:
            if _term_exists(normalized_text, term):
                allergen_found = True
                found_terms.append(term)

                if _near_marker(normalized_text, term, MAY_CONTAIN_MARKERS):
                    allergen_may = True

        if allergen_found:
            if allergen_may:
                may_contain.append(allergen_name)
            else:
                contains.append(allergen_name)

    return (
        sorted(list(set(contains))),
        sorted(list(set(may_contain))),
        sorted(list(set(found_terms))),
    )


def analyze_allergens(text: str) -> Dict:
    cleaned = clean_ocr_text(text or "")

    contains, may_contain, found_terms = _find_allergens(cleaned)

    all_allergens = sorted(list(set(contains + may_contain)))

    if not all_allergens:
        return {
            "allergens": [],
            "contains": [],
            "may_contain": [],
            "found_terms": [],
            "level": "düşük",
            "title": "Alerjen Bilgisi",
            "summary": "Belirgin bir alerjen ifadesi tespit edilmedi.",
            "explanation": (
                "OCR ile okunan içerik metninde yaygın alerjen ifadelerine rastlanmadı. "
                "Ancak alerjiniz varsa ürünü tüketmeden önce ambalaj etiketini mutlaka kontrol ediniz."
            ),
            "disclaimer": (
                "Bu sonuç yalnızca OCR ile okunan metne dayalı bilgilendirme amaçlıdır. "
                "Tıbbi öneri değildir."
            ),
        }

    if may_contain and not contains:
        level = "uyarı"
        summary = (
            "Bu üründe " + ", ".join(may_contain) +
            " içerebileceğine dair ifade tespit edildi."
        )
    elif contains and may_contain:
        level = "yüksek"
        summary = (
            "Bu üründe " + ", ".join(contains) +
            " alerjeni tespit edildi. Ayrıca " + ", ".join(may_contain) +
            " içerebileceğine dair uyarı bulundu."
        )
    else:
        level = "yüksek"
        summary = (
            "Bu üründe " + ", ".join(contains) +
            " alerjeni tespit edildi."
        )

    return {
        "allergens": all_allergens,
        "contains": contains,
        "may_contain": may_contain,
        "found_terms": sorted(list(set(found_terms))),
        "level": level,
        "title": "Alerjen Uyarısı",
        "summary": summary,
        "explanation": (
            "İçerik listesinde alerjen olabilecek ifadeler tespit edilmiştir. "
            "Alerjiniz veya hassasiyetiniz varsa ürün etiketini dikkatle inceleyiniz."
        ),
        "disclaimer": (
            "Bu bilgi OCR ile okunan etikete dayalıdır ve tıbbi öneri değildir. "
            "Ciddi alerjilerde ürün tüketmeden önce uzman görüşü ve resmi ürün etiketi dikkate alınmalıdır."
        ),
    }