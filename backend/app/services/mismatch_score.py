from typing import Dict, List, Tuple


AROMA_HINTS = [
    "aroma",
    "aroması",
    "aromasi",
    "aroma verici",
    "flavour",
    "flavor",
    "flavouring",
    "flavoring",
    "natural flavour",
    "natural flavor",
    "doğal aroma",
    "dogal aroma",
]

WEAK_MATCH_HINTS = [
    "eser",
    "iz miktarda",
    "içerebilir",
    "icerebilir",
    "may contain",
    "traces of",
    "trace of",
    "aynı hatta",
    "ayni hatta",
    "üretim hattında",
    "uretim hattinda",
]


def _normalize_text(value: str) -> str:
    return (
        value.lower()
        .replace("ı", "i")
        .replace("İ", "i")
        .replace("ğ", "g")
        .replace("Ğ", "g")
        .replace("ü", "u")
        .replace("Ü", "u")
        .replace("ş", "s")
        .replace("Ş", "s")
        .replace("ö", "o")
        .replace("Ö", "o")
        .replace("ç", "c")
        .replace("Ç", "c")
        .strip()
    )


def _has_any(text: str, keywords: List[str]) -> bool:
    normalized_text = _normalize_text(text)

    return any(_normalize_text(keyword) in normalized_text for keyword in keywords)


def _is_aroma_match(matches: List[str]) -> bool:
    joined = " ".join(matches)

    return _has_any(joined, AROMA_HINTS)


def _is_weak_match(matches: List[str]) -> bool:
    joined = " ".join(matches)

    return _has_any(joined, WEAK_MATCH_HINTS)


def _build_mismatch_text(
    score: int,
    level: str,
    detected_visuals: List[str],
    matched_ingredients: List[str],
    weak_ingredients: List[str],
    aroma_only_ingredients: List[str],
    missing_ingredients: List[str],
) -> Tuple[str, str, str]:
    title = "Görsel-İçerik Uyumu"

    if not detected_visuals:
        summary = "Görsel tespit sonucu bulunmadığı için yanıltıcılık skoru hesaplanmadı."
        explanation = (
            "Ambalaj ön yüzünden güvenilir bir görsel tespit sonucu alınamadığı için "
            "görsel-içerik uyumu hesaplanmamıştır. Bu durumda yalnızca içerik listesi, "
            "besin değeri ve alerjen bilgileri değerlendirilmiştir."
        )
        return title, summary, explanation

    if level == "düşük":
        summary = "Ambalajdaki görsel vaatler içerik listesiyle genel olarak uyumlu görünmektedir."
        explanation = (
            "Ambalaj ön yüzünde tespit edilen gıda görsellerinin içerik listesinde karşılığı "
            "bulunmuştur. Bu nedenle görsel-içerik uyumsuzluğu düşük seviyede değerlendirilmiştir. "
            "Ancak ambalaj görselleri tüketicide ürün içeriğine dair güçlü bir algı oluşturabileceği "
            "için skor tamamen sıfır yerine düşük düzeyde hesaplanmıştır."
        )

    elif level == "orta":
        summary = "Ambalajdaki bazı görsel vaatler içerik listesiyle kısmen uyumlu görünmektedir."
        explanation = (
            "Ambalajda öne çıkan bazı gıda görselleri içerik listesinde gerçek bileşen olarak "
            "güçlü şekilde karşılık bulmamıştır. Bazı unsurlar yalnızca aroma, iz miktar veya "
            "'içerebilir' gibi zayıf ifadelerle ilişkilendirilmiştir. Bu nedenle sonuç orta düzey "
            "görsel-içerik dikkat skoru olarak değerlendirilmiştir."
        )

    else:
        summary = "Ambalajdaki bazı görsel vaatlerin içerik listesinde yeterli karşılığı bulunamamıştır."
        explanation = (
            "Ambalaj ön yüzünde tespit edilen gıda görsellerinden en az biri içerik listesinde "
            "belirgin bir gerçek bileşen olarak yer almamaktadır. Bu durum, tüketicide ürün içeriği "
            "hakkında olduğundan daha güçlü veya farklı bir algı oluşturabileceği için yüksek düzey "
            "görsel-içerik uyumsuzluğu olarak değerlendirilmiştir."
        )

    return title, summary, explanation


def calculate_mismatch_score(
    detected_visuals: List[str],
    visual_related_ingredients: Dict[str, List[str]],
    aroma_terms: List[str],
) -> Dict:
    """
    Görsel-içerik uyumsuzluk skorunu hesaplar.

    Yeni mantık:
    - Görsel unsur içerikte gerçek bileşen olarak varsa: düşük ama 0 olmayan skor.
    - Görsel unsur sadece aroma olarak geçiyorsa: orta skor.
    - Görsel unsur sadece 'içerebilir / eser miktar' gibi zayıf ifadelerle geçiyorsa: orta skor.
    - Görsel unsur içerikte hiç yoksa: yüksek skor.
    """

    if not detected_visuals:
        title, summary, explanation = _build_mismatch_text(
            score=0,
            level="hesaplanmadı",
            detected_visuals=[],
            matched_ingredients=[],
            weak_ingredients=[],
            aroma_only_ingredients=[],
            missing_ingredients=[],
        )

        return {
            "score": 0,
            "level": "hesaplanmadı",
            "title": title,
            "summary": summary,
            "explanation": explanation,
            "detected_visuals": [],
            "matched_ingredients": [],
            "missing_ingredients": [],
            "reasons": [
                "Ambalaj ön yüzünden güvenilir bir görsel tespit sonucu alınamadığı için yanıltıcılık skoru hesaplanmadı."
            ],
        }

    unique_visuals = []

    for visual in detected_visuals:
        normalized = visual.lower().strip()

        if normalized and normalized not in unique_visuals:
            unique_visuals.append(normalized)

    score = 0
    matched_ingredients = []
    weak_ingredients = []
    aroma_only_ingredients = []
    missing_ingredients = []
    reasons = []

    lower_aroma_text = " ".join(aroma_terms).lower()

    for visual in unique_visuals:
        ingredient_matches = visual_related_ingredients.get(visual, [])
        visual_in_aroma = visual in lower_aroma_text

        if ingredient_matches:
            if _is_aroma_match(ingredient_matches) or visual_in_aroma:
                score += 40
                aroma_only_ingredients.append(visual)
                missing_ingredients.append(visual)
                reasons.append(
                    f"{visual} görseli ambalajda öne çıkmaktadır; içerik listesinde bu unsur gerçek bileşen yerine aroma ifadesiyle ilişkilendirilmiştir."
                )

            elif _is_weak_match(ingredient_matches):
                score += 35
                weak_ingredients.append(visual)
                missing_ingredients.append(visual)
                reasons.append(
                    f"{visual} görseli ambalajda tespit edilmiştir; içerik listesinde yalnızca iz miktar veya 'içerebilir' türü zayıf bir ifade ile yer almaktadır."
                )

            else:
                score += 10
                matched_ingredients.append(visual)
                reasons.append(
                    f"{visual} görseli ambalajda tespit edilmiş ve içerik listesinde gerçek bileşen olarak karşılık bulmuştur: {', '.join(ingredient_matches)}."
                )

        elif visual_in_aroma:
            score += 45
            aroma_only_ingredients.append(visual)
            missing_ingredients.append(visual)
            reasons.append(
                f"{visual} görseli ambalajda tespit edilmiştir; içerikte gerçek bileşen bulunamamış, yalnızca aroma ifadesiyle ilişki kurulmuştur."
            )

        else:
            score += 65
            missing_ingredients.append(visual)
            reasons.append(
                f"{visual} görseli ambalajda tespit edilmiştir; ancak içerik listesinde bu görsele karşılık gelen belirgin bir bileşen bulunamamıştır."
            )

    score = min(score, 100)

    if score < 25:
        level = "düşük"
    elif score < 60:
        level = "orta"
    else:
        level = "yüksek"

    title, summary, explanation = _build_mismatch_text(
        score=score,
        level=level,
        detected_visuals=unique_visuals,
        matched_ingredients=matched_ingredients,
        weak_ingredients=weak_ingredients,
        aroma_only_ingredients=aroma_only_ingredients,
        missing_ingredients=missing_ingredients,
    )

    return {
        "score": score,
        "level": level,
        "title": title,
        "summary": summary,
        "explanation": explanation,
        "detected_visuals": unique_visuals,
        "matched_ingredients": sorted(list(set(matched_ingredients))),
        "missing_ingredients": sorted(list(set(missing_ingredients))),
        "reasons": reasons,
    }