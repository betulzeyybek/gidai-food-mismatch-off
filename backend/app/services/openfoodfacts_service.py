import requests
from typing import Dict, List, Optional


OFF_API_URL = "https://world.openfoodfacts.org/api/v2/product/{barcode}.json"


def _safe_list(value) -> List[str]:
    if isinstance(value, list):
        return [str(x).strip() for x in value if str(x).strip()]

    if isinstance(value, str) and value.strip():
        return [value.strip()]

    return []


def _join_text_parts(parts: List[Optional[str]]) -> str:
    cleaned = []

    for part in parts:
        if part and str(part).strip():
            cleaned.append(str(part).strip())

    return " ".join(cleaned).strip()


def fetch_product_by_barcode(barcode: str) -> Dict:
    """
    OpenFoodFacts üzerinden barkodla ürün bilgisi getirir.
    """

    clean_barcode = str(barcode).strip()

    if not clean_barcode:
        return {
            "found": False,
            "barcode": barcode,
            "message": "Barkod boş olamaz.",
        }

    url = OFF_API_URL.format(barcode=clean_barcode)

    try:
        response = requests.get(
            url,
            timeout=12,
            headers={
                "User-Agent": "GidAI-Graduation-Project/1.0",
            },
        )
    except Exception as exc:
        return {
            "found": False,
            "barcode": clean_barcode,
            "message": f"OpenFoodFacts bağlantı hatası: {exc}",
        }

    if response.status_code != 200:
        return {
            "found": False,
            "barcode": clean_barcode,
            "message": f"OpenFoodFacts servis hatası: {response.status_code}",
        }

    data = response.json()

    if data.get("status") != 1:
        return {
            "found": False,
            "barcode": clean_barcode,
            "message": "Bu barkod OpenFoodFacts veritabanında bulunamadı.",
        }

    product = data.get("product", {}) or {}

    product_name = (
        product.get("product_name_tr")
        or product.get("product_name")
        or product.get("generic_name_tr")
        or product.get("generic_name")
        or "Barkod ile Bulunan Ürün"
    )

    ingredients_text = (
        product.get("ingredients_text_tr")
        or product.get("ingredients_text")
        or product.get("ingredients_text_en")
        or ""
    )

    allergens_tags = _safe_list(product.get("allergens_tags"))
    traces_tags = _safe_list(product.get("traces_tags"))
    additives_tags = _safe_list(product.get("additives_tags"))

    nutriments = product.get("nutriments", {}) or {}

    nutrition_text = _join_text_parts(
        [
            f"Enerji: {nutriments.get('energy-kcal_100g')} kcal"
            if nutriments.get("energy-kcal_100g") is not None
            else None,
            f"Yağ: {nutriments.get('fat_100g')} g"
            if nutriments.get("fat_100g") is not None
            else None,
            f"Doymuş yağ: {nutriments.get('saturated-fat_100g')} g"
            if nutriments.get("saturated-fat_100g") is not None
            else None,
            f"Karbonhidrat: {nutriments.get('carbohydrates_100g')} g"
            if nutriments.get("carbohydrates_100g") is not None
            else None,
            f"Şeker: {nutriments.get('sugars_100g')} g"
            if nutriments.get("sugars_100g") is not None
            else None,
            f"Protein: {nutriments.get('proteins_100g')} g"
            if nutriments.get("proteins_100g") is not None
            else None,
            f"Tuz: {nutriments.get('salt_100g')} g"
            if nutriments.get("salt_100g") is not None
            else None,
        ]
    )

    allergen_text = _join_text_parts(
        [
            "Alerjen etiketleri: " + ", ".join(allergens_tags)
            if allergens_tags
            else None,
            "İz/eser alerjen etiketleri: " + ", ".join(traces_tags)
            if traces_tags
            else None,
        ]
    )

    analysis_text = _join_text_parts(
        [
            f"Ürün adı: {product_name}",
            f"İçindekiler: {ingredients_text}" if ingredients_text else None,
            allergen_text if allergen_text else None,
            nutrition_text if nutrition_text else None,
        ]
    )

    image_url = (
        product.get("image_front_url")
        or product.get("image_url")
        or product.get("image_small_url")
    )

    return {
        "found": True,
        "barcode": clean_barcode,
        "product_name": product_name,
        "brands": product.get("brands", ""),
        "quantity": product.get("quantity", ""),
        "categories": product.get("categories", ""),
        "ingredients_text": ingredients_text,
        "analysis_text": analysis_text,
        "image_url": image_url,
        "front_image_url": image_url,
        "allergens_tags": allergens_tags,
        "traces_tags": traces_tags,
        "additives_tags": additives_tags,
        "nutriments": nutriments,
        "source": "openfoodfacts",
    }