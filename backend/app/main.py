"""
Aplicação FastAPI — ponto de entrada.
"""

import logging
import time

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from .api.routes import router

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
logger = logging.getLogger("prelaje")

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

@app.middleware("http")
async def log_requests(request: Request, call_next):
    body = b""
    if request.method == "POST":
        body = await request.body()
        logger.info(">>> %s %s body=%s", request.method, request.url.path, body.decode()[:500])
    else:
        logger.info(">>> %s %s", request.method, request.url.path)
    t0 = time.time()
    response = await call_next(request)
    dt = (time.time() - t0) * 1000
    logger.info("<<< %s %dms", response.status_code, dt)
    return response


app.include_router(router)
