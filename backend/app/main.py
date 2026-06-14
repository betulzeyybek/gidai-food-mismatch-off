import os
import shutil
import tempfile
import time
import requests
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError
from typing import Optional, List

from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.models.schemas import (
    AnalyzeResponse,
    OCRResult,
    IngredientAnalysis,
    HealthScoreResult,
    MismatchScoreResult,
    AllergenAnalysis,
)

from app.services.ocr_service import run_paddle_ocr
from app.services.grok_service import (
    run_grok_vision_ocr,
    detect_visual_claims_with_grok,
)
from app.services.allergen_parser import analyze_allergens
from app.services.ingredient_parser import analyze_ingredients
from app.services.health_score import calculate_health_score
from app.services.mismatch_score import calculate_mismatch_score
from app.services.nutrition_parser import (
    extract_nutrition_values,
    calculate_nutrition_attention,
)
from app.services.openfoodfacts_service import fetch_product_by_barcode
from app.utils.confidence import should_use_grok_ocr
from app.utils.text_cleaner import clean_ocr_text, extract_possible_product_name


load_dotenv()

app = FastAPI(
    title="GıdAI Backend",
    description=(
        "Gıda ambalajlarında OCR, içerik analizi, sağlık dikkat skoru, "
        "besin değeri analizi, alerjen analizi ve görsel-içerik uyumu API sistemi"
    ),
    version="1.4.1",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

GROK_EXECUTOR = ThreadPoolExecutor(max_workers=2)


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "message": "GıdAI backend çalışıyor.",
        "version": "1.4.1",
    }


def _log_step(start_time: float, message: str) -> None:
    elapsed = time.perf_counter() - start_time
    print(f"[ANALYZE] {elapsed:.2f}s - {message}")


def _save_upload_file(upload_file: UploadFile) -> str:
    suffix = os.path.splitext(upload_file.filename or "")[-1]

    if suffix.lower() not in [".jpg", ".jpeg", ".png"]:
        suffix = ".jpg"

    temp_dir = tempfile.mkdtemp()
    file_path = os.path.join(temp_dir, f"uploaded_image{suffix}")

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)

    return file_path
def _download_image_from_url(image_url: Optional[str]) -> Optional[str]:
    if not image_url:
        return None

    try:
        response = requests.get(
            image_url,
            timeout=12,
            headers={"User-Agent": "GidAI-Graduation-Project/1.0"},
        )

        if response.status_code != 200:
            return None

        temp_dir = tempfile.mkdtemp()
        file_path = os.path.join(temp_dir, "openfoodfacts_front.jpg")

        with open(file_path, "wb") as file:
            file.write(response.content)

        return file_path

    except Exception as exc:
        print(f"[BARCODE IMAGE] OpenFoodFacts görseli indirilemedi: {exc}")
        return None


def _parse_detected_visuals(detected_visuals: Optional[str]) -> List[str]:
    if not detected_visuals:
        return []

    unique_visuals = []

    for item in detected_visuals.split(","):
        normalized = item.strip().lower()

        if normalized and normalized not in unique_visuals:
            unique_visuals.append(normalized)

    return unique_visuals


def _run_grok_ocr_with_timeout(
    image_path: str,
    timeout_seconds: int = 8,
) -> Optional[str]:
    future = GROK_EXECUTOR.submit(run_grok_vision_ocr, image_path)

    try:
        return future.result(timeout=timeout_seconds)

    except FutureTimeoutError:
        print(
            f"[GROK OCR] {timeout_seconds} saniyede cevap gelmedi. "
            "PaddleOCR sonucu kullanılacak."
        )
        return None

    except Exception as exc:
        print(f"[GROK OCR] Hata: {exc}")
        return None


def _detect_visuals_with_grok_timeout(
    front_image_path: Optional[str],
    timeout_seconds: int = 5,
) -> List[str]:
    if not front_image_path:
        return []

    future = GROK_EXECUTOR.submit(detect_visual_claims_with_grok, front_image_path)

    try:
        result = future.result(timeout=timeout_seconds)
        visuals = result.get("detected_visuals", [])

        if not isinstance(visuals, list):
            return []

        unique_visuals = []

        for visual in visuals:
            normalized = str(visual).strip().lower()

            if normalized and normalized not in unique_visuals:
                unique_visuals.append(normalized)

        return unique_visuals

    except FutureTimeoutError:
        print(f"[GROK VISUAL] {timeout_seconds} saniyede cevap gelmedi. Analiz devam ediyor.")
        return []

    except Exception as exc:
        print(f"[GROK VISUAL] Hata: {exc}")
        return []


def build_final_comment(
    health_level: str,
    mismatch_level: str,
    nutrition_score: int = 0,
) -> str:
    nutrition_note = ""

    if nutrition_score >= 25:
        nutrition_note = (
            " Besin değerleri tarafında da yüksek dikkat gerektiren değerler "
            "tespit edilmiştir."
        )
    elif nutrition_score > 0:
        nutrition_note = (
            " Besin değerleri tarafında ek dikkat gerektiren bazı değerler "
            "tespit edilmiştir."
        )

    if mismatch_level == "hesaplanmadı":
        if health_level == "düşük":
            return (
                "Ürün içerik listesi analiz edildi. İçerik ve besin değeri "
                "tarafında düşük düzeyde dikkat gerektiren ifadeler tespit edildi. "
                "Görsel tespit sonucu bulunmadığı için görsel-içerik uyumu henüz "
                "hesaplanmadı."
                + nutrition_note
            )

        if health_level == "orta":
            return (
                "Ürün içerik listesi analiz edildi. İçerikte veya besin değerlerinde "
                "bazı dikkat gerektiren sinyaller tespit edildi. Görsel tespit sonucu "
                "bulunmadığı için görsel-içerik uyumu henüz hesaplanmadı."
                + nutrition_note
            )

        return (
            "Ürün içerik listesi analiz edildi. İçerikte veya besin değerlerinde "
            "yüksek dikkat gerektiren sinyaller tespit edildi. Görsel tespit sonucu "
            "bulunmadığı için görsel-içerik uyumu henüz hesaplanmadı."
            + nutrition_note
        )

    if health_level == "düşük" and mismatch_level == "düşük":
        return (
            "Genel değerlendirmeye göre ürünün sağlık dikkat skoru düşük ve ambalaj "
            "görselleri içerik listesiyle uyumlu görünmektedir."
            + nutrition_note
        )

    if health_level == "orta" and mismatch_level == "düşük":
        return (
            "Ürünün ambalaj görselleri içerik listesiyle uyumlu görünmektedir; ancak "
            "içerikte veya besin değerlerinde bazı dikkat gerektiren sinyaller tespit "
            "edilmiştir."
            + nutrition_note
        )

    if health_level == "yüksek" and mismatch_level == "düşük":
        return (
            "Ambalaj görselleri içerik listesiyle uyumlu görünse de ürünün içerik veya "
            "besin değeri bilgilerinde yüksek dikkat gerektiren sinyaller tespit edilmiştir."
            + nutrition_note
        )

    if health_level == "düşük" and mismatch_level == "orta":
        return (
            "Sağlık dikkat skoru düşük seviyededir; ancak ambalajdaki bazı görsel vaatler "
            "içerik listesiyle kısmen uyumlu görünmektedir."
            + nutrition_note
        )

    if health_level == "orta" and mismatch_level == "orta":
        return (
            "Üründe hem bazı dikkat gerektiren içerik/besin değeri sinyalleri hem de "
            "kısmi görsel-içerik uyumsuzluğu tespit edilmiştir. Ürün etiketi ve ambalaj "
            "görselleri birlikte değerlendirilmelidir."
            + nutrition_note
        )

    if health_level == "yüksek" and mismatch_level == "orta":
        return (
            "Ürünün içerik veya besin değeri bilgilerinde yüksek dikkat gerektiren "
            "sinyaller tespit edilmiştir. Ayrıca bazı görsel vaatler içerikle kısmen "
            "uyumludur. Bu nedenle ürün etiketi dikkatle incelenmelidir."
            + nutrition_note
        )

    if health_level == "düşük" and mismatch_level == "yüksek":
        return (
            "Sağlık dikkat skoru düşük seviyededir; ancak ambalaj görselleri ile içerik "
            "listesi arasında belirgin uyumsuzluk tespit edilmiştir. Bu durum tüketicide "
            "ürün içeriği hakkında yanıltıcı bir algı oluşturabilir."
            + nutrition_note
        )

    if health_level == "orta" and mismatch_level == "yüksek":
        return (
            "Üründe bazı dikkat gerektiren içerik veya besin değeri sinyalleri tespit "
            "edilmiştir. Ayrıca ambalaj görselleri ile içerik listesi arasında belirgin "
            "uyumsuzluk bulunmaktadır. Bu nedenle ürün hem içerik hem de görsel vaat "
            "açısından dikkatle değerlendirilmelidir."
            + nutrition_note
        )

    if health_level == "yüksek" and mismatch_level == "yüksek":
        return (
            "Ürün içerik/besin değeri tarafında yüksek dikkat gerektiren sinyaller ve "
            "ambalaj görselleriyle içerik arasında belirgin uyumsuzluk tespit edilmiştir. "
            "Bu sonuç, ürün etiketinin ve ambalaj vaatlerinin dikkatle incelenmesi "
            "gerektiğini göstermektedir."
            + nutrition_note
        )

    return (
        "Ürün içerik listesi, besin değerleri ve ambalaj görselleri analiz edilmiştir. "
        "Sonuçlar bilgilendirme amacıyla sunulmaktadır."
    )


@app.post("/ocr")
async def ocr_only(file: UploadFile = File(...)):
    image_path = _save_upload_file(file)

    try:
        result = run_paddle_ocr(image_path)

        return {
            "source": result.get("source"),
            "text": result.get("text", ""),
            "avg_confidence": result.get("avg_confidence", 0.0),
            "fallback_used": False,
            "success": result.get("success", False),
            "lines": result.get("lines", []),
            "error": result.get("error"),
        }

    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/ocr-debug")
async def ocr_debug(file: UploadFile = File(...)):
    image_path = _save_upload_file(file)

    try:
        result = run_paddle_ocr(image_path)

        return {
            "source": result.get("source"),
            "success": result.get("success"),
            "avg_confidence": result.get("avg_confidence"),
            "line_count": len(result.get("lines", [])),
            "text_length": len(result.get("text", "")),
            "text": result.get("text", ""),
            "lines": result.get("lines", []),
            "error": result.get("error"),
        }

    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/product/barcode/{barcode}")
async def get_product_by_barcode(barcode: str):
    """
    Barkod ile OpenFoodFacts ürün bilgisini getirir.
    Bu endpoint sadece ürün kartı göstermek için kullanılır.
    """

    product = fetch_product_by_barcode(barcode)

    if not product.get("found"):
        raise HTTPException(
            status_code=404,
            detail=product.get("message", "Ürün bulunamadı."),
        )

    return product


@app.get("/analyze-barcode/{barcode}", response_model=AnalyzeResponse)
async def analyze_barcode(barcode: str):
    """
    Barkod ile OpenFoodFacts verisini alır.
    Eğer OpenFoodFacts ürün fotoğrafı varsa bu fotoğraf üzerinden Grok görsel tespiti yapar.
    OCR yerine OpenFoodFacts içerik metni kullanılır.
    """

    start_time = time.perf_counter()
    _log_step(start_time, "Barkod analizi isteği geldi.")

    product = fetch_product_by_barcode(barcode)

    if not product.get("found"):
        raise HTTPException(
            status_code=404,
            detail=product.get("message", "Ürün bulunamadı."),
        )

    analysis_text = product.get("analysis_text") or product.get("ingredients_text") or ""

    if not analysis_text.strip():
        raise HTTPException(
            status_code=422,
            detail=(
                "Bu ürün OpenFoodFacts veritabanında bulundu ancak içerik bilgisi "
                "bulunamadığı için analiz yapılamadı."
            ),
        )

    final_ocr = OCRResult(
        source="openfoodfacts_barcode",
        text=clean_ocr_text(analysis_text),
        avg_confidence=1.0,
        lines=[],
        fallback_used=False,
        success=True,
    )

    ingredient_dict = analyze_ingredients(final_ocr.text)
    ingredient_analysis = IngredientAnalysis(**ingredient_dict)
    _log_step(start_time, "Barkod içerik analizi tamamlandı.")

    allergen_dict = analyze_allergens(
        final_ocr.text + " " + ingredient_analysis.cleaned_text
    )
    allergen_analysis = AllergenAnalysis(**allergen_dict)
    _log_step(start_time, "Barkod alerjen analizi tamamlandı.")

    nutrition_values = extract_nutrition_values(final_ocr.text)
    nutrition_attention = calculate_nutrition_attention(nutrition_values)
    _log_step(start_time, "Barkod besin değeri analizi tamamlandı.")

    health_dict = calculate_health_score(
        e_codes=ingredient_analysis.e_codes,
        risk_keywords=ingredient_analysis.risk_keywords,
        nutrition_score=nutrition_attention["nutrition_score"],
        nutrition_reasons=nutrition_attention["nutrition_reasons"],
        nutrition_values=nutrition_attention["nutrition_values"],
    )
    health_score = HealthScoreResult(**health_dict)
    _log_step(start_time, "Barkod sağlık skoru tamamlandı.")

    image_url = product.get("image_url") or product.get("front_image_url")
    front_image_path = _download_image_from_url(image_url)

    visual_list = []

    use_grok_visual_detection = (
        os.getenv("USE_GROK_VISUAL_DETECTION", "true").lower() == "true"
    )

    if front_image_path and use_grok_visual_detection:
        _log_step(start_time, "OpenFoodFacts ürün fotoğrafı ile Grok görsel tespiti başladı.")

        grok_timeout_seconds = int(os.getenv("GROK_VISUAL_TIMEOUT_SECONDS", "20"))

        visual_list = _detect_visuals_with_grok_timeout(
            front_image_path=front_image_path,
            timeout_seconds=grok_timeout_seconds,
        )

        _log_step(
            start_time,
            f"OpenFoodFacts fotoğrafından görsel tespit tamamlandı. Sonuç: {visual_list}",
        )
    else:
        _log_step(
            start_time,
            "OpenFoodFacts ürün fotoğrafı bulunamadı veya görsel tespit kapalı.",
        )

    mismatch_dict = calculate_mismatch_score(
        detected_visuals=visual_list,
        visual_related_ingredients=ingredient_analysis.visual_related_ingredients,
        aroma_terms=ingredient_analysis.aroma_terms,
    )
    mismatch_score = MismatchScoreResult(**mismatch_dict)
    _log_step(start_time, "Barkod görsel-içerik skoru tamamlandı.")

    final_comment = build_final_comment(
        health_level=health_score.risk_level,
        mismatch_level=mismatch_score.level,
        nutrition_score=health_score.nutrition_score,
    )

    response = AnalyzeResponse(
        product_name=product.get("product_name"),
        ocr=final_ocr,
        ingredient_analysis=ingredient_analysis,
        health_score=health_score,
        mismatch_score=mismatch_score,
        allergen_analysis=allergen_analysis,
        final_comment=final_comment,
        image_url=image_url,
        front_image_url=image_url,
    )

    _log_step(start_time, "Barkod analizi başarıyla tamamlandı.")
    return response

@app.post("/analyze-product", response_model=AnalyzeResponse)
async def analyze_product(
    file: Optional[UploadFile] = File(default=None),
    front_image: Optional[UploadFile] = File(default=None),
    ingredients_image: Optional[UploadFile] = File(default=None),
    detected_visuals: Optional[str] = Form(default=None),
    barcode: Optional[str] = Form(default=None),
    product_name: Optional[str] = Form(default=None),
    ingredients_text_from_barcode: Optional[str] = Form(default=None),
):
    start_time = time.perf_counter()
    _log_step(start_time, "Analiz isteği geldi.")

    selected_file = ingredients_image or file or front_image

    if selected_file is None:
        raise HTTPException(
            status_code=422,
            detail=(
                "Analiz için fotoğraf gönderilmedi. "
                "Backend 'file', 'ingredients_image' veya 'front_image' "
                "alanlarından en az birini bekler."
            ),
        )

    try:
        front_image_path = None

        if front_image is not None:
            front_image_path = _save_upload_file(front_image)
            _log_step(start_time, "Ön yüz fotoğrafı kaydedildi.")

        if selected_file is front_image and front_image_path:
            image_path = front_image_path
        else:
            image_path = _save_upload_file(selected_file)

        _log_step(start_time, "OCR fotoğrafı kaydedildi.")

        use_grok_fallback = os.getenv("USE_GROK_FALLBACK", "true").lower() == "true"

        if ingredients_text_from_barcode and ingredients_text_from_barcode.strip():
            cleaned_barcode_text = clean_ocr_text(ingredients_text_from_barcode)

            final_ocr = OCRResult(
                source="barcode_text",
                text=cleaned_barcode_text,
                avg_confidence=1.0,
                lines=[],
                fallback_used=False,
                success=bool(cleaned_barcode_text),
            )

            _log_step(start_time, "Barkoddan gelen içerik metni kullanıldı.")

        else:
            _log_step(start_time, "PaddleOCR başladı.")
            paddle_result = run_paddle_ocr(image_path)
            _log_step(start_time, "PaddleOCR bitti.")

            ocr_text = clean_ocr_text(paddle_result.get("text", ""))
            avg_confidence = float(paddle_result.get("avg_confidence", 0.0))
            paddle_lines = paddle_result.get("lines", [])

            fallback_needed = should_use_grok_ocr(
                text=ocr_text,
                avg_confidence=avg_confidence,
                lines=paddle_lines,
            )

            if fallback_needed and use_grok_fallback:
                _log_step(start_time, "Grok OCR fallback gerekli görüldü.")

                grok_ocr_timeout = int(os.getenv("GROK_OCR_TIMEOUT_SECONDS", "8"))
                grok_text = _run_grok_ocr_with_timeout(
                    image_path=image_path,
                    timeout_seconds=grok_ocr_timeout,
                )

                if grok_text and grok_text.strip():
                    final_ocr = OCRResult(
                        source="grok_fallback",
                        text=clean_ocr_text(grok_text),
                        avg_confidence=avg_confidence,
                        lines=paddle_lines,
                        fallback_used=True,
                        success=True,
                    )
                    _log_step(start_time, "Grok OCR fallback sonucu kullanıldı.")

                else:
                    final_ocr = OCRResult(
                        source="paddleocr",
                        text=ocr_text,
                        avg_confidence=avg_confidence,
                        lines=paddle_lines,
                        fallback_used=False,
                        success=bool(ocr_text),
                    )
                    _log_step(
                        start_time,
                        "Grok OCR yetişmedi/başarısız. PaddleOCR sonucu kullanıldı.",
                    )

            else:
                final_ocr = OCRResult(
                    source="paddleocr",
                    text=ocr_text,
                    avg_confidence=avg_confidence,
                    lines=paddle_lines,
                    fallback_used=False,
                    success=bool(ocr_text),
                )

        if not final_ocr.success or not final_ocr.text:
            raise HTTPException(
                status_code=422,
                detail=(
                    "OCR işlemi sonucunda okunabilir metin elde edilemedi. "
                    "Lütfen daha net, daha yakın ve ışığı yeterli bir içerik fotoğrafı yükleyin."
                ),
            )

        ingredient_dict = analyze_ingredients(final_ocr.text)
        ingredient_analysis = IngredientAnalysis(**ingredient_dict)
        _log_step(start_time, "İçerik analizi tamamlandı.")

        allergen_dict = analyze_allergens(
            final_ocr.text + " " + ingredient_analysis.cleaned_text
        )
        allergen_analysis = AllergenAnalysis(**allergen_dict)
        _log_step(start_time, "Alerjen analizi tamamlandı.")

        nutrition_values = extract_nutrition_values(final_ocr.text)
        nutrition_attention = calculate_nutrition_attention(nutrition_values)
        _log_step(start_time, "Besin değeri analizi tamamlandı.")

        health_dict = calculate_health_score(
            e_codes=ingredient_analysis.e_codes,
            risk_keywords=ingredient_analysis.risk_keywords,
            nutrition_score=nutrition_attention["nutrition_score"],
            nutrition_reasons=nutrition_attention["nutrition_reasons"],
            nutrition_values=nutrition_attention["nutrition_values"],
        )
        health_score = HealthScoreResult(**health_dict)
        _log_step(start_time, "Sağlık skoru tamamlandı.")

        manual_visuals = _parse_detected_visuals(detected_visuals)
        grok_visuals = []

        use_grok_visual_detection = (
            os.getenv("USE_GROK_VISUAL_DETECTION", "true").lower() == "true"
        )

        if front_image_path and use_grok_visual_detection:
            _log_step(start_time, "Grok ön yüz görsel tespiti başladı.")
            grok_timeout_seconds = int(os.getenv("GROK_VISUAL_TIMEOUT_SECONDS", "5"))

            grok_visuals = _detect_visuals_with_grok_timeout(
                front_image_path=front_image_path,
                timeout_seconds=grok_timeout_seconds,
            )

            _log_step(
                start_time,
                f"Grok ön yüz görsel tespiti tamamlandı. Sonuç: {grok_visuals}",
            )

        visual_list = []

        for visual in manual_visuals + grok_visuals:
            normalized = str(visual).strip().lower()

            if normalized and normalized not in visual_list:
                visual_list.append(normalized)

        mismatch_dict = calculate_mismatch_score(
            detected_visuals=visual_list,
            visual_related_ingredients=ingredient_analysis.visual_related_ingredients,
            aroma_terms=ingredient_analysis.aroma_terms,
        )
        mismatch_score = MismatchScoreResult(**mismatch_dict)
        _log_step(start_time, "Görsel-içerik skoru tamamlandı.")

        detected_product_name = extract_possible_product_name(final_ocr.text)

        final_product_name = (
            product_name.strip()
            if product_name and product_name.strip()
            else detected_product_name
        )

        final_comment = build_final_comment(
            health_level=health_score.risk_level,
            mismatch_level=mismatch_score.level,
            nutrition_score=health_score.nutrition_score,
        )

        response = AnalyzeResponse(
            product_name=final_product_name,
            ocr=final_ocr,
            ingredient_analysis=ingredient_analysis,
            health_score=health_score,
            mismatch_score=mismatch_score,
            allergen_analysis=allergen_analysis,
            final_comment=final_comment,
        )

        _log_step(start_time, "Analiz başarıyla tamamlandı.")
        return response

    except HTTPException:
        raise

    except Exception as exc:
        print(f"[ANALYZE ERROR] {exc}")
        raise HTTPException(status_code=500, detail=str(exc))