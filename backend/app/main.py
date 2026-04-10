"""
Aplicação FastAPI — ponto de entrada.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .api.routes import router

app = FastAPI(
    title="Prelaje — Dimensionamento de Lajes Treliçadas",
    description=(
        "Motor de cálculo para pré-dimensionamento de lajes nervuradas "
        "com vigotas treliçadas unidirecionais passivas. "
        "NBR 6118:2026 | NBR 6120:2019 | NBR 7481:2023. "
        "FERRAMENTA PARA ESTUDOS PRELIMINARES — NÃO substitui projeto "
        "estrutural assinado por Engenheiro Civil habilitado com ART."
    ),
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # restringir em produção
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)
