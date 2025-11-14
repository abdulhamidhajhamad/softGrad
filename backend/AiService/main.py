from fastapi import FastAPI
from pydantic import BaseModel
from model.recommender import recommend_packages

app = FastAPI(title="Wedding AI Packager Service")

class WeddingRequest(BaseModel):
    services: list
    budget: float
    date: str

@app.post("/recommend")
def recommend(data: WeddingRequest):
    result = recommend_packages(data.services, data.budget, data.date)
    return {"packages": result}
