from contextlib import asynccontextmanager
from pathlib import Path

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field

MODEL_PATH = "ml_model/diabetes_gaussian_process.joblib"
FEATURE_COLUMNS = ["혈당", "BMI", "나이"]


class PredictionInput(BaseModel):
    glucose_mg_dl: float = Field(gt=0, allow_inf_nan=False, description="혈당 (mg/dL)")
    height_cm: float = Field(ge=1, le=300, description="키 (cm)")
    weight_kg: float = Field(gt=0, le=1000, description="몸무게 (kg)")
    age_years: int = Field(gt=0, le=130, description="만 나이 (년)")


class PredictionResult(BaseModel):
    bmi: float
    predicted_class: int
    model_score: float
    # notice: str = "실험용 모델 추정치입니다. 당뇨 진단은 의료기관의 검사를 통해 확인하세요."


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.model = None
    if MODEL_PATH:
        model_path = Path(__file__).resolve().parent / MODEL_PATH
        app.state.model = joblib.load(model_path)
    yield


app = FastAPI(title="당뇨 예측 API", lifespan=lifespan)


@app.get("/")
async def read_root():
    return {"message": "Hello Diabetes!"}

@app.post("/predict", response_model=PredictionResult)
def predict(payload: PredictionInput, request: Request):
    model = request.app.state.model
    if model is None:
        raise HTTPException(status_code=503, detail="당뇨 예측 모델 경로가 설정되지 않았습니다.")

    bmi = payload.weight_kg / (payload.height_cm / 100) ** 2
    features = pd.DataFrame(
        [[payload.glucose_mg_dl, bmi, payload.age_years]], columns=FEATURE_COLUMNS
    )
    return PredictionResult(
        bmi=round(bmi, 2),
        predicted_class=int(model.predict(features)[0]),
        model_score=float(model.predict_proba(features)[0, 1]),
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8000)
