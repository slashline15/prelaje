"""
Endpoints da API FastAPI.
Contrato JSON: DadosLaje → ResultadoDimensionamento
"""

from fastapi import APIRouter, HTTPException
from ..schemas import DadosLaje, ResultadoDimensionamento
from ..engine.motor import calcular

router = APIRouter(prefix="/api/v1", tags=["dimensionamento"])


@router.post("/dimensionar", response_model=ResultadoDimensionamento)
async def dimensionar(dados: DadosLaje) -> ResultadoDimensionamento:
    """
    Endpoint principal de dimensionamento.

    Recebe DadosLaje e retorna ResultadoDimensionamento.
    Em caso de entrada inválida (travas de segurança), retorna 422.
    """
    try:
        resultado = calcular(dados)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))

    return resultado


@router.get("/vigotas")
async def listar_vigotas():
    """Lista os modelos de vigota disponíveis no catálogo."""
    from ..engine.materiais import CATALOGO_VIGOTAS
    return [
        {
            "codigo": v.codigo,
            "h_vigota_cm": v.h_vigota,
            "intereixo_cm": v.intereixo,
            "vao_max_m": v.vao_max,
        }
        for v in CATALOGO_VIGOTAS.values()
    ]


@router.get("/health")
async def health():
    return {"status": "ok"}
