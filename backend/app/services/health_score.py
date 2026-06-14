from typing import Dict, List, Tuple, Optional, Any


"""
Bu modül, paketli gıda ürünlerinin içerik listesi ve besin değerlerinden
bilgilendirici bir sağlık dikkat skoru üretir.

Önemli:
- Bu skor tıbbi teşhis değildir.
- Ürünün kesin olarak zararlı olduğunu iddia etmez.
- WHO/FAO JECFA ve EFSA yaklaşımına uygun olarak katkı maddeleri, ADI,
  düzenleyici değerlendirme, içerik farkındalığı ve besin değeri sinyalleri
  birlikte değerlendirilir.
- Amaç kullanıcıya etiketi daha anlaşılır sunmaktır.
"""


E_CODE_RISK_MAP: Dict[str, Dict[str, str]] = {
    "E102": {"level": "high", "reason": "Renklendirici katkı maddesi"},
    "E104": {"level": "medium", "reason": "Renklendirici katkı maddesi"},
    "E110": {"level": "high", "reason": "Renklendirici katkı maddesi"},
    "E122": {"level": "high", "reason": "Renklendirici katkı maddesi"},
    "E124": {"level": "high", "reason": "Renklendirici katkı maddesi"},
    "E129": {"level": "medium", "reason": "Renklendirici katkı maddesi"},

    "E200": {"level": "low", "reason": "Koruyucu katkı maddesi"},
    "E202": {"level": "low", "reason": "Koruyucu katkı maddesi"},
    "E211": {"level": "medium", "reason": "Koruyucu katkı maddesi"},
    "E220": {"level": "medium", "reason": "Sülfit grubu koruyucu"},
    "E223": {"level": "medium", "reason": "Sülfit grubu koruyucu"},
    "E250": {"level": "high", "reason": "Nitrit grubu koruyucu"},
    "E251": {"level": "medium", "reason": "Nitrat grubu koruyucu"},

    "E300": {"level": "low", "reason": "Antioksidan katkı maddesi"},
    "E320": {"level": "medium", "reason": "Antioksidan katkı maddesi"},
    "E321": {"level": "medium", "reason": "Antioksidan katkı maddesi"},

    "E330": {"level": "low", "reason": "Asitlik düzenleyici"},
    "E331": {"level": "low", "reason": "Asitlik düzenleyici"},
    "E407": {"level": "medium", "reason": "Kıvam artırıcı / stabilizatör"},

    "E322": {"level": "low", "reason": "Emülgatör"},
    "E471": {"level": "low", "reason": "Emülgatör"},
    "E476": {"level": "medium", "reason": "Emülgatör"},

    "E621": {"level": "medium", "reason": "Lezzet artırıcı"},

    "E950": {"level": "medium", "reason": "Tatlandırıcı"},
    "E951": {"level": "medium", "reason": "Tatlandırıcı"},
    "E955": {"level": "medium", "reason": "Tatlandırıcı"},
}


INGREDIENT_ATTENTION_POINTS: Dict[str, int] = {
    "şeker": 4,
    "seker": 4,
    "glikoz şurubu": 8,
    "glikoz surubu": 8,
    "fruktoz şurubu": 10,
    "fruktoz surubu": 10,
    "yüksek fruktozlu": 12,
    "yuksek fruktozlu": 12,

    "palm": 7,
    "palm yağı": 7,
    "palm yagi": 7,
    "bitkisel yağlar": 4,
    "bitkisel yaglar": 4,
    "hidrojene": 12,

    "emülgatör": 3,
    "emulgator": 3,
    "renklendirici": 8,
    "koruyucu": 6,
    "tatlandırıcı": 6,
    "tatlandirici": 6,

    "aroma verici": 2,
    "aroma vericiler": 2,

    "aspartam": 8,
    "asesülfam": 8,
    "asesulfam": 8,
    "sodyum nitrit": 12,
    "monosodyum glutamat": 8,
    "poligliserol polirisinoleat": 5,
    "soya lesitini": 2,
    "amonyum fosfatitler": 4,
    "bitkisel yağ": 4,
    "lesitin": 2,
    "sodyum hidroksit": 4,
    "asitlik düzenleyici": 4,
    "kabartıcı": 3,
    "mono and diglycerides": 4,
    "mono and diacetyl tartaric acid esters": 5,
    "yüksek tuz oranı": 8,
}


def _points_for_e_code(code: str) -> Tuple[int, str]:
    normalized = code.upper().strip()
    info = E_CODE_RISK_MAP.get(normalized)

    if not info:
        return (
            3,
            f"{normalized} tespit edildi. Bu katkı maddesi için sistemde ayrıntılı sınıflandırma bulunmadığından düşük genel dikkat puanı verilmiştir."
        )

    level = info["level"]
    reason = info["reason"]

    if level == "high":
        return 15, f"{normalized}: {reason}. Bu katkı grubu daha yüksek dikkat gerektiren katkılar arasında değerlendirilmiştir."
    if level == "medium":
        return 8, f"{normalized}: {reason}. Bu katkı grubu orta düzey dikkat gerektiren içerikler arasında değerlendirilmiştir."

    return 3, f"{normalized}: {reason}. Bu katkı grubu düşük düzey dikkat gerektiren içerikler arasında değerlendirilmiştir."


def _deduplicate_attention_terms(risk_keywords: List[str]) -> List[str]:
    normalize_map = {
        "aroma vericiler": "aroma verici",
        "emülgatörler": "emülgatör",
        "emulgatorler": "emulgator",
        "palm yağı": "palm",
        "palm yagi": "palm",
    }

    normalized_terms = []

    for keyword in risk_keywords:
        clean_keyword = keyword.lower().strip()
        clean_keyword = normalize_map.get(clean_keyword, clean_keyword)

        if clean_keyword not in normalized_terms:
            normalized_terms.append(clean_keyword)

    return normalized_terms


def _level_text(score: int) -> str:
    if score < 25:
        return "düşük"
    if score < 60:
        return "orta"
    return "yüksek"


def _build_health_summary(
    score: int,
    level: str,
    reasons: List[str],
    nutrition_score: int = 0,
) -> Tuple[str, str, str]:
    title = "Sağlık Dikkat Skoru"

    nutrition_note = ""
    if nutrition_score > 0:
        nutrition_note = (
            " Ayrıca besin değerleri tablosunda şeker, doymuş yağ, toplam yağ veya tuz gibi "
            "alanlardan ek dikkat puanı oluşmuştur."
        )

    if level == "düşük":
        summary = "Bu ürünün içerik listesinde sınırlı sayıda dikkat gerektiren ifade tespit edildi."
        explanation = (
            "Skor düşük seviyededir. Bu durum, OCR ile okunan içerik ve besin değeri bilgilerinde "
            "yüksek dikkat gerektiren unsur yoğunluğunun düşük olduğunu gösterir."
            f"{nutrition_note} Bu sonuç tıbbi bir değerlendirme değildir; yalnızca etiket bilgisini daha anlaşılır hale getirir."
        )
    elif level == "orta":
        summary = "Bu üründe bazı dikkat gerektiren içerik veya besin değeri sinyalleri tespit edildi."
        explanation = (
            "Skor orta seviyededir. İçerikte şeker, palm/bitkisel yağ, emülgatör, aroma verici veya belirli katkı adları "
            "gibi kullanıcı tarafından dikkatle incelenmesi önerilen ifadeler bulunmuş olabilir."
            f"{nutrition_note} Bu sonuç ürünün doğrudan zararlı olduğu anlamına gelmez; tüketicinin içerik konusunda bilinçlenmesini amaçlayan "
            "bilgilendirici bir değerlendirmedir."
        )
    else:
        summary = "Bu üründe daha yüksek dikkat gerektiren birden fazla içerik veya besin değeri sinyali tespit edildi."
        explanation = (
            "Skor yüksek seviyededir. İçerikte yüksek dikkat puanı verilen katkı maddeleri, tatlandırıcılar, renklendiriciler, "
            "koruyucular, nitrit grubu bileşenler veya besin tablosunda yüksek şeker/doymuş yağ gibi değerler bulunmuş olabilir."
            f"{nutrition_note} Bu değerlendirme kesin sağlık riski veya tıbbi teşhis anlamına gelmez; ürün etiketinin daha dikkatli incelenmesi "
            "gerektiğini gösteren bilgilendirici bir uyarıdır."
        )

    return title, summary, explanation


def calculate_health_score(
    e_codes: List[str],
    risk_keywords: List[str],
    nutrition_score: int = 0,
    nutrition_reasons: Optional[List[str]] = None,
    nutrition_values: Optional[Dict[str, Any]] = None,
) -> Dict:
    score = 0
    reasons = []

    if nutrition_reasons is None:
        nutrition_reasons = []

    if nutrition_values is None:
        nutrition_values = {}

    unique_e_codes = sorted(list(set([code.upper().strip() for code in e_codes])))

    for code in unique_e_codes:
        point, reason = _points_for_e_code(code)
        score += point
        reasons.append(reason)

    unique_attention_terms = _deduplicate_attention_terms(risk_keywords)

    for keyword in unique_attention_terms:
        point = INGREDIENT_ATTENTION_POINTS.get(keyword, 3)
        score += point
        reasons.append(f"Dikkat gerektiren içerik ifadesi: {keyword}")

    nutrition_score = min(int(nutrition_score), 40)
    score += nutrition_score

    for reason in nutrition_reasons:
        reasons.append(reason)

    score = min(score, 100)
    risk_level = _level_text(score)

    if not reasons:
        reasons.append(
            "İçerik listesinde ve besin değerlerinde belirgin dikkat gerektiren ifade tespit edilmedi."
        )

    title, summary, explanation = _build_health_summary(
        score=score,
        level=risk_level,
        reasons=reasons,
        nutrition_score=nutrition_score,
    )

    disclaimer = (
        "Bu skor, içerik listesindeki katkı maddeleri, dikkat gerektiren içerik ifadeleri ve OCR ile okunan "
        "besin değerleri üzerinden bilgilendirme amacıyla hesaplanmıştır. Kesin bir tıbbi değerlendirme değildir."
    )

    return {
        "score": score,
        "risk_level": risk_level,
        "title": title,
        "summary": summary,
        "explanation": explanation,
        "reasons": reasons,
        "disclaimer": disclaimer,
        "nutrition_values": nutrition_values,
        "nutrition_score": nutrition_score,
        "nutrition_reasons": nutrition_reasons,
    }