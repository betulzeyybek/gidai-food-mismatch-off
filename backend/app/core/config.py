from functools import lru_cache
from pydantic import BaseModel
from dotenv import load_dotenv
import os

load_dotenv()

class Settings(BaseModel):
    xai_api_key: str = os.getenv("XAI_API_KEY", "")
    xai_model: str = os.getenv("XAI_MODEL", "grok-4.3")
    xai_base_url: str = os.getenv("XAI_BASE_URL", "https://api.x.ai/v1")
    allow_fake_grok: bool = os.getenv("ALLOW_FAKE_GROK", "false").lower() == "true"

@lru_cache
def get_settings() -> Settings:
    return Settings()
