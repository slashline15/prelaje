"""
Endpoints da API FastAPI.
Contrato JSON: DadosLaje → ResultadoDimensionamento
"""

from fastapi import APIRouter, HTTPException, Response
from ..schemas import DadosLaje, ResultadoDimensionamento
from ..engine.motor import calcular
from ..reporting.pdf import gerar_relatorio_pdf

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


@router.post("/relatorio-pdf")
async def gerar_pdf(dados: DadosLaje) -> Response:
    """
    Gera PDF preliminar com memorial resumido, disclaimers e quantitativos.
    """
    try:
        resultado = calcular(dados)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))

    pdf_bytes = gerar_relatorio_pdf(dados, resultado)
    filename = f"prelaje-{dados.modo.value}-{dados.codigo_vigota.replace(' ', '_')}.pdf"
    headers = {"Content-Disposition": f'attachment; filename="{filename}"'}
    return Response(pdf_bytes, media_type="application/pdf", headers=headers)


@router.get("/vigotas")
async def listar_vigotas():
    """Lista os modelos de vigota disponíveis no catálogo."""
    from ..engine.catalogo import codigos_catalogo_disponiveis
    from ..engine.materiais import VIGOTAS_REFERENCIA, aliases_por_codigo

    catalogo = codigos_catalogo_disponiveis()
    aliases = aliases_por_codigo()
    return [
        {
            "codigo": v.codigo,
            "codigo_canonico": v.codigo,
            "aliases": aliases.get(v.codigo, []),
            "h_vigota_cm": v.h_vigota,
            "largura_nervura_cm": v.b_nerv,
            "intereixo_cm": v.intereixo,
            "capa_min_cm": v.capa_min,
            "vao_max_m": v.vao_max,
            "disponivel_analitico": v.homologada_analitico,
            "disponivel_catalogo": v.codigo in catalogo,
            "fck_catalogo_mpa": catalogo.get(v.codigo, {}).get("fck_mpa", []),
            "intereixos_catalogo_cm": catalogo.get(v.codigo, {}).get("intereixo_cm", []),
            "capas_catalogo_cm": catalogo.get(v.codigo, {}).get("capa_cm", []),
        }
        for v in VIGOTAS_REFERENCIA.values()
    ]


@router.get("/referencias/trelicas")
async def listar_trelicas():
    """Lista as treliças de referência informadas pelo domínio/comercial."""
    from ..engine.materiais import TRELICAS_REFERENCIA

    return [
        {
            "modelo": t.modelo,
            "designacao": t.designacao,
            "altura_mm": t.altura_mm,
            "diametro_superior_mm": t.diametro_superior_mm,
            "diametro_diagonal_mm": t.diametro_diagonal_mm,
            "diametro_inferior_mm": t.diametro_inferior_mm,
            "peso_linear_kg_m": t.peso_linear_kg_m,
        }
        for t in TRELICAS_REFERENCIA
    ]


@router.get("/referencias/alturas-eps")
async def listar_alturas_eps():
    """Lista combinações de altura de enchimento EPS e altura total de laje."""
    from ..engine.materiais import COMPATIBILIDADE_ALTURAS_EPS

    return [
        {
            "h_enchimento_cm": item.h_enchimento_cm,
            "h_total_cm": item.h_total_cm,
        }
        for item in COMPATIBILIDADE_ALTURAS_EPS
    ]


@router.get("/referencias/revestimentos")
async def listar_revestimentos():
    """Lista presets de revestimento/carga permanente para o formulario."""
    from ..engine.materiais import REVESTIMENTOS_REFERENCIA

    return [
        {
            "id": item.id,
            "descricao": item.descricao,
            "g_rev_kn_m2": item.g_rev_kn_m2,
        }
        for item in REVESTIMENTOS_REFERENCIA
    ]


@router.get("/referencias/cargas-uso")
async def listar_cargas_uso():
    """Lista categorias de uso, carga acidental e coeficientes psi."""
    from ..engine.materiais import USOS_REFERENCIA

    return [
        {
            "uso": referencia.uso_id,
            "uso_categoria": referencia.uso_categoria,
            "subcategoria": referencia.subcategoria,
            "carga_kn_m2": referencia.carga_kn_m2,
            "psi_0": referencia.psi_0,
            "psi_1": referencia.psi_1,
            "psi_2": referencia.psi_2,
            "depreciado": referencia.depreciado,
            "alias_de": referencia.alias_de,
        }
        for referencia in sorted(USOS_REFERENCIA.values(), key=lambda item: item.uso_id)
    ]


@router.get("/referencias/custos")
async def listar_custos(regiao: str = "AM"):
    """Lista referencias de custos para o frontend de orcamento."""
    from ..engine.orcamento import obter_referencias_custos

    return obter_referencias_custos(regiao)


@router.get("/health")
async def health():
    return {"status": "ok"}
