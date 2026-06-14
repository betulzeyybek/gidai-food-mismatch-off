from pydantic import BaseModel, Field
from typing import List, Dict, Optional


class OCRLine(BaseModel):
    text: str
    confidence: float


class OCRResult(BaseModel):
    source: str
    text: str
    avg_confidence: float
    lines: List[OCRLine] = []
    fallback_used: bool = False
    success: bool = True


class IngredientAnalysis(BaseModel):
    cleaned_text: str
    e_codes: List[str] = []
    risk_keywords: List[str] = []
    aroma_terms: List[str] = []
    visual_related_ingredients: Dict[str, List[str]] = {}


class HealthScoreResult(BaseModel):
    score: int = Field(..., ge=0, le=100)
    risk_level: str
    title: str
    summary: str
    explanation: str
    reasons: List[str] = []
    disclaimer: str
    nutrition_values: Dict[str, Optional[float]] = {}
    nutrition_score: int = 0
    nutrition_reasons: List[str] = []


class MismatchScoreResult(BaseModel):
    score: int = Field(..., ge=0, le=100)
    level: str
    title: str
    summary: str
    explanation: str
    detected_visuals: List[str] = []
    matched_ingredients: List[str] = []
    missing_ingredients: List[str] = []
    reasons: List[str] = []


class AllergenAnalysis(BaseModel):
    allergens: List[str] = []
    contains: List[str] = []
    may_contain: List[str] = []
    found_terms: List[str] = []
    level: str
    title: str
    summary: str
    explanation: str
    disclaimer: str


class AnalyzeResponse(BaseModel):
    product_name: Optional[str] = None
    ocr: OCRResult
    ingredient_analysis: IngredientAnalysis
    health_score: HealthScoreResult
    mismatch_score: MismatchScoreResult
    allergen_analysis: AllergenAnalysis
    final_comment: str
    image_url: Optional[str] = None
    front_image_url: Optional[str] = None