import re
from typing import Dict, Optional, List

from app.utils.text_cleaner import clean_ocr_text


def _to_float(value: str) -> Optional[float]:
    try:
        return float(value.replace(",", "."))
    except Exception:
        return None


def _valid_value(key: str, value: Optional[float]) -> Optional[float]:
    if value is None:
        return None

    limits = {
        "energy_kcal": (50, 900),
        "fat_g": (0, 100),
        "saturated_fat_g": (0, 100),
        "carbohydrate_g": (0, 100),
        "sugars_g": (0, 100),
        "protein_g": (0, 100),
        "salt_g": (0, 10),
    }

    low, high = limits[key]

    if low <= value <= high:
        return value

    return None


def _has_nutrition_table(text: str) -> bool:
    cleaned = clean_ocr_text(text).lower()

    markers = [
        "nutrition",
        "besin",
        "enerji",
        "energy",
        "per 100 g",
        "100 g için",
        "100 g icin",
        "yağ/fat",
        "yag/fat",
        "tuz/salt",
    ]

    return sum(1 for marker in markers if marker in cleaned) >= 2


def _numbers_near_label(text: str, labels: List[str], max_chars: int = 100) -> List[float]:
    lowered = text.lower()

    for label in labels:
        idx = lowered.find(label)

        if idx == -1:
            continue

        segment = text[idx: idx + max_chars]
        raw_numbers = re.findall(r"\d{1,4}(?:[.,]\d+)?", segment)

        values = []

        for raw in raw_numbers:
            parsed = _to_float(raw)
            if parsed is not None:
                values.append(parsed)

        return values

    return []


def _pick_last_valid(key: str, numbers: List[float]) -> Optional[float]:
    valid = []

    for number in numbers:
        checked = _valid_value(key, number)

        if checked is not None:
            valid.append(checked)

    if not valid:
        return None

    return valid[-1]


def _fix_compound_carbohydrate_and_sugar(text: str, values: Dict[str, Optional[float]]) -> None:
    """
    OCR bazen '56 55' değerini '5655' şeklinde okuyabiliyor.
    Bu durumda karbonhidrat=56, şeker=55 şeklinde ayrıştırıyoruz.
    """

    cleaned = clean_ocr_text(text).lower()

    match = re.search(
        r"karbonhidrat[^0-9]{0,40}(\d{1,2})\s*(\d{4})",
        cleaned,
    )

    if not match:
        match = re.search(
            r"carbohydrate[^0-9]{0,40}(\d{1,2})\s*(\d{4})",
            cleaned,
        )

    if match:
        compound = match.group(2)

        if len(compound) == 4:
            carb = _to_float(compound[:2])
            sugar = _to_float(compound[2:])

            if carb is not None and 0 <= carb <= 100:
                values["carbohydrate_g"] = carb

            if sugar is not None and 0 <= sugar <= 100:
                values["sugars_g"] = sugar


def _parse_structured_eight_value_table(text: str, values: Dict[str, Optional[float]]) -> None:
    """
    Bazı paketlerde tablo şu şekilde OCR'a düşüyor:
    36,8 16,8 0,0 42,8 41,8 6,0 7,9 0,2 100 g için 2271 541
    Bu 8 değer sırasıyla:
    yağ, doymuş yağ, trans yağ, karbonhidrat, şeker, lif, protein, tuz
    """

    cleaned = clean_ocr_text(text)

    pattern = (
        r"(\d{1,2}[,.]\d)\s+"
        r"(\d{1,2}[,.]\d)\s+"
        r"(\d{1,2}[,.]\d)\s+"
        r"(\d{1,2}[,.]\d)\s+"
        r"(\d{1,2}[,.]\d)\s+"
        r"(\d{1,2}[,.]\d)\s+"
        r"(\d{1,2}[,.]\d)\s+"
        r"(\d{1,2}[,.]\d)"
    )

    match = re.search(pattern, cleaned)

    if not match:
        return

    nums = [_to_float(x) for x in match.groups()]

    if any(x is None for x in nums):
        return

    values["fat_g"] = _valid_value("fat_g", nums[0])
    values["saturated_fat_g"] = _valid_value("saturated_fat_g", nums[1])
    values["carbohydrate_g"] = _valid_value("carbohydrate_g", nums[3])
    values["sugars_g"] = _valid_value("sugars_g", nums[4])
    values["protein_g"] = _valid_value("protein_g", nums[6])
    values["salt_g"] = _valid_value("salt_g", nums[7])

    energy_match = re.search(r"100\s*g[^0-9]{0,20}(\d{3,4})\s+(\d{2,3})", cleaned.lower())

    if energy_match:
        kcal = _to_float(energy_match.group(2))
        values["energy_kcal"] = _valid_value("energy_kcal", kcal)


def extract_nutrition_values(text: str) -> Dict[str, Optional[float]]:
    cleaned = clean_ocr_text(text)

    values = {
        "energy_kcal": None,
        "fat_g": None,
        "saturated_fat_g": None,
        "carbohydrate_g": None,
        "sugars_g": None,
        "protein_g": None,
        "salt_g": None,
    }

    if not _has_nutrition_table(cleaned):
        return values

    _parse_structured_eight_value_table(cleaned, values)

    if values["energy_kcal"] is None:
        energy_numbers = _numbers_near_label(
            cleaned,
            ["enerji/energy", "enerji / energy", "energy", "enerji"],
        )
        values["energy_kcal"] = _pick_last_valid("energy_kcal", energy_numbers)

    if values["fat_g"] is None:
        fat_numbers = _numbers_near_label(
            cleaned,
            ["yağ/fat", "yağ / fat", "yag/fat", "fat", "yağ", "yag"],
        )
        values["fat_g"] = _pick_last_valid("fat_g", fat_numbers)

    if values["saturated_fat_g"] is None:
        sat_numbers = _numbers_near_label(
            cleaned,
            ["doymuş yağ", "doymus yag", "of which saturates", "saturates", "saturated"],
        )
        values["saturated_fat_g"] = _pick_last_valid("saturated_fat_g", sat_numbers)

    if values["carbohydrate_g"] is None:
        carb_numbers = _numbers_near_label(
            cleaned,
            ["karbonhidrat/carbohydrate", "karbonhidrat / carbohydrate", "carbohydrate", "karbonhidrat"],
        )
        values["carbohydrate_g"] = _pick_last_valid("carbohydrate_g", carb_numbers)

    if values["sugars_g"] is None:
        sugar_numbers = _numbers_near_label(
            cleaned,
            ["şekerler/of which sugars", "sekerler/of which sugars", "of which sugars", "sugars", "şekerler", "sekerler"],
        )
        values["sugars_g"] = _pick_last_valid("sugars_g", sugar_numbers)

    if values["protein_g"] is None:
        protein_numbers = _numbers_near_label(cleaned, ["protein"])
        values["protein_g"] = _pick_last_valid("protein_g", protein_numbers)

    if values["salt_g"] is None:
        salt_numbers = _numbers_near_label(cleaned, ["tuz/salt", "tuz / salt", "salt", "tuz"])
        values["salt_g"] = _pick_last_valid("salt_g", salt_numbers)

    _fix_compound_carbohydrate_and_sugar(cleaned, values)

    return values


def calculate_nutrition_attention(nutrition: Dict[str, Optional[float]]) -> Dict:
    score = 0
    reasons = []

    sugars = nutrition.get("sugars_g")
    saturated_fat = nutrition.get("saturated_fat_g")
    fat = nutrition.get("fat_g")
    salt = nutrition.get("salt_g")

    if sugars is not None:
        if sugars >= 40:
            score += 18
            reasons.append(f"Besin tablosunda yüksek şeker değeri tespit edildi: {sugars} g.")
        elif sugars >= 20:
            score += 10
            reasons.append(f"Besin tablosunda orta-yüksek şeker değeri tespit edildi: {sugars} g.")

    if saturated_fat is not None:
        if saturated_fat >= 10:
            score += 18
            reasons.append(f"Besin tablosunda yüksek doymuş yağ değeri tespit edildi: {saturated_fat} g.")
        elif saturated_fat >= 5:
            score += 10
            reasons.append(f"Besin tablosunda orta-yüksek doymuş yağ değeri tespit edildi: {saturated_fat} g.")

    if fat is not None:
        if fat >= 25:
            score += 8
            reasons.append(f"Besin tablosunda yüksek toplam yağ değeri tespit edildi: {fat} g.")

    if salt is not None:
        if salt >= 1.5:
            score += 10
            reasons.append(f"Besin tablosunda yüksek tuz değeri tespit edildi: {salt} g.")
        elif salt >= 0.7:
            score += 5
            reasons.append(f"Besin tablosunda orta düzey tuz değeri tespit edildi: {salt} g.")

    return {
        "nutrition_values": nutrition,
        "nutrition_score": min(score, 40),
        "nutrition_reasons": reasons,
    }