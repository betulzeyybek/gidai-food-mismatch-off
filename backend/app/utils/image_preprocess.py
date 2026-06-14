import os
import tempfile
from typing import Optional

import cv2
import numpy as np


def preprocess_image_for_ocr(image_path: str, max_width: int = 1200) -> str:
    """
    OCR için görseli optimize eder.

    Amaç:
    - Büyük iPhone fotoğraflarını küçültmek
    - Kontrastı artırmak
    - Yazıları biraz keskinleştirmek
    - PaddleOCR'nin daha hızlı çalışmasını sağlamak

    Not:
    OCR model ayarlarına dokunmaz.
    Sadece görseli OCR öncesi daha uygun hale getirir.
    """

    image = cv2.imread(image_path)

    if image is None:
        return image_path

    height, width = image.shape[:2]

    # Büyük mobil fotoğrafları küçült
    if width > max_width:
        scale = max_width / width
        image = cv2.resize(
            image,
            None,
            fx=scale,
            fy=scale,
            interpolation=cv2.INTER_AREA,
        )

    # Çok küçük görsel varsa biraz büyüt
    elif width < 900:
        scale = 900 / width
        image = cv2.resize(
            image,
            None,
            fx=scale,
            fy=scale,
            interpolation=cv2.INTER_CUBIC,
        )

    # Griye çevir
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Kontrast artırma
    clahe = cv2.createCLAHE(
        clipLimit=2.0,
        tileGridSize=(8, 8),
    )
    enhanced = clahe.apply(gray)

    # Hafif gürültü azaltma
    denoised = cv2.bilateralFilter(
        enhanced,
        d=5,
        sigmaColor=50,
        sigmaSpace=50,
    )

    # Hafif keskinleştirme
    kernel = np.array(
        [
            [0, -1, 0],
            [-1, 5, -1],
            [0, -1, 0],
        ]
    )

    sharpened = cv2.filter2D(denoised, -1, kernel)

    # PaddleOCR renkli/gri görseli okuyabilir ama kaydederken jpg yapıyoruz
    temp_dir = tempfile.mkdtemp()
    output_path = os.path.join(temp_dir, "preprocessed_ocr_image.jpg")

    cv2.imwrite(output_path, sharpened)

    return output_path