"""
Composição de orçamento preliminar com base nos quantitativos do cálculo.
"""

from __future__ import annotations

import csv
import math
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Optional, TypeVar

from ..schemas import (
    ArmaduraReforco,
    DadosLaje,
    OrcamentoItem,
    OrcamentoResultado,
    OrcamentoResumo,
    Quantitativos,
    ResultadoDimensionamento,
    ResumoComercial,
    ResumoComercialItem,
)
from .materiais import DadosVigota


DB_DIR = Path(__file__).resolve().parents[2] / "db"
REGIAO_PADRAO = "AM"
TELA_PADRAO = "Q-92"
ESCORAMENTO_PADRAO = "ESC-MADEIRA"
ARAME_PADRAO = "ARAME-1.6"
ESPACADOR_PADRAO = "ESP-PLASTICO"
DENSIDADE_ACO_KG_M3 = 7850.0
CONSUMO_ARAME_KG_M2 = 0.3
CONSUMO_ESPACADOR_UN_M2 = 4.0
TIPOS_MATERIAIS_REFERENCIA = {
    "vigota",
    "eps",
    "tela_pop",
    "concreto",
    "escoramento",
    "arame_recozido",
    "espacadores",
}
T = TypeVar("T")


@dataclass(frozen=True)
class PrecoMaterial:
    item_tipo: str
    item_codigo: str
    descricao: str
    unidade: str
    preco_unitario: float
    fonte: str
    data_referencia: str
    regiao: str


@dataclass(frozen=True)
class RegraComercial:
    item_tipo: str
    item_codigo: str
    multiplo_compra: float
    unidade_compra: str
    perda_percentual: float


@dataclass(frozen=True)
class PrecoServico:
    servico_codigo: str
    descricao: str
    unidade: str
    preco_unitario: float
    fonte: str
    data_referencia: str
    regiao: str


@dataclass(frozen=True)
class CustoIndireto:
    codigo: str
    descricao: str
    tipo: str
    valor: float
    regiao: str


@lru_cache(maxsize=1)
def _carregar_precos_materiais() -> tuple[PrecoMaterial, ...]:
    path = DB_DIR / "custos_materiais.csv"
    with path.open(newline="", encoding="utf-8") as arquivo:
        return tuple(
            PrecoMaterial(
                item_tipo=row["item_tipo"],
                item_codigo=row["item_codigo"],
                descricao=row["descricao"],
                unidade=row["unidade"],
                preco_unitario=float(row["preco_unitario"]),
                fonte=row["fonte"],
                data_referencia=row["data_referencia"],
                regiao=row["regiao"],
            )
            for row in csv.DictReader(arquivo)
        )


@lru_cache(maxsize=1)
def _carregar_regras_comerciais() -> dict[tuple[str, str], RegraComercial]:
    path = DB_DIR / "regras_comerciais.csv"
    with path.open(newline="", encoding="utf-8") as arquivo:
        return {
            (row["item_tipo"], row["item_codigo"]): RegraComercial(
                item_tipo=row["item_tipo"],
                item_codigo=row["item_codigo"],
                multiplo_compra=float(row["multiplo_compra"]),
                unidade_compra=row["unidade_compra"],
                perda_percentual=float(row["perda_percentual"]),
            )
            for row in csv.DictReader(arquivo)
        }


@lru_cache(maxsize=1)
def _carregar_precos_servicos() -> dict[str, tuple[PrecoServico, ...]]:
    path = DB_DIR / "custos_mao_obra.csv"
    agrupado: dict[str, list[PrecoServico]] = {}
    with path.open(newline="", encoding="utf-8") as arquivo:
        for row in csv.DictReader(arquivo):
            agrupado.setdefault(row["servico_codigo"], []).append(
                PrecoServico(
                    servico_codigo=row["servico_codigo"],
                    descricao=row["descricao"],
                    unidade=row["unidade"],
                    preco_unitario=float(row["preco_unitario"]),
                    fonte=row["fonte"],
                    data_referencia=row["data_referencia"],
                    regiao=row["regiao"],
                )
            )
    return {codigo: tuple(valores) for codigo, valores in agrupado.items()}


@lru_cache(maxsize=1)
def _carregar_custos_indiretos() -> dict[str, tuple[CustoIndireto, ...]]:
    path = DB_DIR / "custos_indiretos.csv"
    agrupado: dict[str, list[CustoIndireto]] = {}
    with path.open(newline="", encoding="utf-8") as arquivo:
        for row in csv.DictReader(arquivo):
            agrupado.setdefault(row["codigo"], []).append(
                CustoIndireto(
                    codigo=row["codigo"],
                    descricao=row["descricao"],
                    tipo=row["tipo"],
                    valor=float(row["valor"]),
                    regiao=row["regiao"],
                )
            )
    return {codigo: tuple(valores) for codigo, valores in agrupado.items()}


def _selecionar_por_regiao(itens: tuple[T, ...], regiao: str) -> T:
    for item in itens:
        if getattr(item, "regiao", None) == regiao:
            return item
    return itens[0]


def _buscar_material(item_tipo: str, item_codigo: str, regiao: str) -> Optional[PrecoMaterial]:
    candidatos = [
        item for item in _carregar_precos_materiais()
        if item.item_tipo == item_tipo and item.item_codigo == item_codigo and item.regiao == regiao
    ]
    if not candidatos:
        return None
    return candidatos[0]


def _buscar_regra(item_tipo: str, item_codigo: str) -> Optional[RegraComercial]:
    return _carregar_regras_comerciais().get((item_tipo, item_codigo))


def _buscar_servico(servico_codigo: str, regiao: str) -> Optional[PrecoServico]:
    candidatos = _carregar_precos_servicos().get(servico_codigo)
    if not candidatos:
        return None
    for item in candidatos:
        if item.regiao == regiao:
            return item
    return None


def _buscar_indireto(codigo: str, regiao: str) -> Optional[CustoIndireto]:
    candidatos = _carregar_custos_indiretos().get(codigo)
    if not candidatos:
        return None
    for item in candidatos:
        if item.regiao == regiao:
            return item
    return None


def _regiao_tem_cobertura_minima(regiao: str) -> bool:
    materiais = _carregar_precos_materiais()
    tipos_disponiveis = {item.item_tipo for item in materiais if item.regiao == regiao}
    if not TIPOS_MATERIAIS_REFERENCIA.issubset(tipos_disponiveis):
        return False
    servicos = _carregar_precos_servicos()
    if not servicos or any(not any(item.regiao == regiao for item in itens) for itens in servicos.values()):
        return False
    indiretos = _carregar_custos_indiretos()
    if not indiretos or any(not any(item.regiao == regiao for item in itens) for itens in indiretos.values()):
        return False
    return True


def _resolver_regiao_referencia(regiao: str) -> tuple[str, list[str]]:
    materiais = _carregar_precos_materiais()
    if not materiais:
        return regiao, [f"Nenhum preco de material carregado para a referencia de custos."]
    if _regiao_tem_cobertura_minima(regiao):
        return regiao, []

    regioes = sorted({item.regiao for item in materiais})
    for candidata in regioes:
        if _regiao_tem_cobertura_minima(candidata):
            return candidata, [
                f"Regiao {regiao} sem cobertura comercial completa; usada regiao {candidata}."
            ]

    regiao_fallback = materiais[0].regiao
    return regiao_fallback, [
        f"Regiao {regiao} sem cobertura comercial completa; usada regiao {regiao_fallback}."
    ]


def _arredondar_compra(quantidade: float, multiplo: float) -> float:
    if multiplo <= 0:
        return quantidade
    return math.ceil(quantidade / multiplo) * multiplo


def _peso_linear_aco_kg_m(diametro_mm: float) -> float:
    diametro_m = diametro_mm / 1000.0
    area_m2 = math.pi * diametro_m ** 2 / 4.0
    return area_m2 * DENSIDADE_ACO_KG_M3


def _item_material(
    *,
    codigo: str,
    item_tipo: str,
    quantidade_base: float,
    regiao: str,
    categoria: str,
    observacoes: str | None = None,
) -> tuple[Optional[OrcamentoItem], Optional[str]]:
    preco = _buscar_material(item_tipo, codigo, regiao)
    if preco is None:
        return None, f"Preco nao encontrado para {item_tipo}:{codigo} em {regiao}."

    regra = _buscar_regra(item_tipo, codigo)
    perda_percentual = regra.perda_percentual if regra else 0.0
    quantidade_com_perda = quantidade_base * (1.0 + perda_percentual / 100.0)
    quantidade_compra = _arredondar_compra(
        quantidade_com_perda,
        regra.multiplo_compra if regra else 0.0,
    )
    unidade_compra = regra.unidade_compra if regra else preco.unidade

    return OrcamentoItem(
        categoria=categoria,
        codigo=codigo,
        descricao=preco.descricao,
        unidade=preco.unidade,
        quantidade=round(quantidade_base, 3),
        quantidade_compra=round(quantidade_compra, 3),
        unidade_compra=unidade_compra,
        perda_percentual=perda_percentual,
        preco_unitario=preco.preco_unitario,
        custo_total=round(quantidade_compra * preco.preco_unitario, 2),
        observacoes=observacoes,
    ), None


def _item_servico(
    *,
    servico_codigo: str,
    quantidade: float,
    regiao: str,
) -> tuple[Optional[OrcamentoItem], Optional[str]]:
    servico = _buscar_servico(servico_codigo, regiao)
    if servico is None:
        return None, f"Servico nao encontrado para {servico_codigo} em {regiao}."

    return OrcamentoItem(
        categoria="mao_de_obra",
        codigo=servico.servico_codigo,
        descricao=servico.descricao,
        unidade=servico.unidade,
        quantidade=round(quantidade, 3),
        quantidade_compra=round(quantidade, 3),
        unidade_compra=servico.unidade,
        perda_percentual=0.0,
        preco_unitario=servico.preco_unitario,
        custo_total=round(quantidade * servico.preco_unitario, 2),
        observacoes=None,
    ), None


def _codigo_eps(dados: DadosLaje) -> str:
    altura_cm = int(round(dados.h_enchimento * 100.0))
    intereixo_cm = int(round(dados.intereixo * 100.0))
    return f"EPS-{altura_cm}-{intereixo_cm}"


def _codigo_concreto(fck: float, regiao: str) -> tuple[Optional[str], Optional[str]]:
    concretos = sorted(
        (
            int(item.item_codigo.replace("CONC", "")),
            item.item_codigo,
        )
        for item in _carregar_precos_materiais()
        if item.item_tipo == "concreto" and item.regiao == regiao and item.item_codigo.startswith("CONC")
    )
    if not concretos:
        return None, f"Nenhum preco de concreto encontrado em {regiao}."

    fck_int = int(math.ceil(fck))
    for fck_disponivel, codigo in concretos:
        if fck_int <= fck_disponivel:
            alerta = None
            if fck_int != fck_disponivel:
                alerta = (
                    f"fck={fck:.1f} MPa sem preco exato; usada referencia comercial {codigo} em {regiao}."
                )
            return codigo, alerta

    fck_disponivel, codigo = concretos[-1]
    return (
        codigo,
        f"fck={fck:.1f} MPa acima da maior referencia comercial; usado {codigo} em {regiao}.",
    )


def _estimativa_reforco_analitico(
    resultado: ResultadoDimensionamento,
    vigota: DadosVigota,
) -> Optional[ArmaduraReforco]:
    if resultado.elu is None:
        return None

    as_requerido = max(resultado.elu.as_calculado, resultado.elu.as_minimo)
    as_adicional = max(0.0, as_requerido - vigota.As_base)
    if as_adicional <= 0.01:
        return None

    bitolas = [4.2, 5.0, 6.3, 8.0]
    melhor: tuple[int, float] | None = None
    for diametro in bitolas:
        as_barra = math.pi * diametro ** 2 / 4.0 / 100.0
        quantidade = max(1, math.ceil(as_adicional / as_barra))
        excesso = quantidade * as_barra - as_adicional
        candidato = (quantidade, excesso)
        if melhor is None or candidato < melhor:
            melhor = candidato
            diametro_escolhido = diametro
            quantidade_escolhida = quantidade

    return ArmaduraReforco(
        diametro_mm=diametro_escolhido,
        quantidade=quantidade_escolhida,
        as_total_cm2=round(
            quantidade_escolhida * math.pi * diametro_escolhido ** 2 / 4.0 / 100.0,
            3,
        ),
    )


def _selecionar_tela(resultado: ResultadoDimensionamento) -> tuple[str, str]:
    """
    Heuristica comercial do MVP para tela soldada.
    Q-92 segue como default; cargas/armaduras mais altas elevam a tela de referencia.
    """
    if resultado.q_k >= 5.0:
        return (
            "Q-165",
            "Tela de distribuicao elevada para caso mais exigente por sobrecarga (heuristica MVP).",
        )
    if resultado.q_k >= 3.0:
        return (
            "Q-131",
            "Tela de distribuicao intermediaria para sobrecarga acima do padrao residencial (heuristica MVP).",
        )
    return "Q-92", "Tela de distribuicao padrao Q-92."


def _nervuras_com_reforco_adicional(dados: DadosLaje, quant: Quantitativos) -> int:
    if dados.tipo_apoio == "biapoiada":
        return quant.n_vigotas
    # Heuristica MVP: em lajes continuas, o reforco adicional e precificado
    # apenas nas faixas de apoio mais criticas, nao em todas as nervuras.
    return min(2, quant.n_vigotas)


def _itens_materiais(
    dados: DadosLaje,
    resultado: ResultadoDimensionamento,
    quant: Quantitativos,
    vigota: DadosVigota,
    regiao: str,
) -> tuple[list[OrcamentoItem], list[str]]:
    itens: list[OrcamentoItem] = []
    alertas: list[str] = []

    area_laje = dados.largura_total * dados.vao
    comprimento_vigotas_m = quant.n_vigotas * dados.vao

    codigo_concreto, alerta_concreto = _codigo_concreto(dados.fck, regiao)
    if alerta_concreto is not None:
        alertas.append(alerta_concreto)
    codigo_tela, observacao_tela = _selecionar_tela(resultado)

    specs = [
        ("vigota", vigota.codigo, comprimento_vigotas_m, "materiais", "Metros lineares de vigotas."),
        ("eps", _codigo_eps(dados), float(quant.n_enchimento), "materiais", "Pecas de enchimento EPS."),
        ("tela_pop", codigo_tela, area_laje, "materiais", observacao_tela),
        ("escoramento", ESCORAMENTO_PADRAO, area_laje, "materiais", "Escoramento preliminar por area."),
        ("arame_recozido", ARAME_PADRAO, area_laje * CONSUMO_ARAME_KG_M2, "materiais", "Consumo estimado de arame recozido para amarracao."),
        ("espacadores", ESPACADOR_PADRAO, area_laje * CONSUMO_ESPACADOR_UN_M2, "materiais", "Consumo estimado de espacadores plasticos."),
    ]
    if codigo_concreto is not None:
        specs.append(
            ("concreto", codigo_concreto, quant.volume_capa_m3, "materiais", "Concreto da capa.")
        )
    for item_tipo, codigo, quantidade, categoria, observacoes in specs:
        item, alerta = _item_material(
            codigo=codigo,
            item_tipo=item_tipo,
            quantidade_base=quantidade,
            regiao=regiao,
            categoria=categoria,
            observacoes=observacoes,
        )
        if item is not None:
            itens.append(item)
        if alerta is not None:
            alertas.append(alerta)

    reforco = resultado.catalogo.reforco if resultado.catalogo is not None else _estimativa_reforco_analitico(resultado, vigota)
    if reforco is not None:
        codigo_aco = f"{dados.classe_aco.value.replace('-', '')}-{reforco.diametro_mm:.1f}"
        nervuras_com_reforco = (
            quant.n_vigotas
            if resultado.catalogo is not None
            else _nervuras_com_reforco_adicional(dados, quant)
        )
        comprimento_total_m = nervuras_com_reforco * dados.vao * reforco.quantidade
        peso_total_kg = comprimento_total_m * _peso_linear_aco_kg_m(reforco.diametro_mm)
        item, alerta = _item_material(
            codigo=codigo_aco,
            item_tipo="aco_reforco",
            quantidade_base=peso_total_kg,
            regiao=regiao,
            categoria="materiais",
            observacoes=(
                "Aco adicional preliminar para reforco longitudinal."
                if resultado.catalogo is None
                else "Aco adicional conforme reforco do catalogo."
            ),
        )
        if item is not None:
            itens.append(item)
        if alerta is not None:
            alertas.append(alerta)

    return itens, alertas


def _itens_mao_de_obra(
    dados: DadosLaje,
    quant: Quantitativos,
    vigota: DadosVigota,
    regiao: str,
) -> tuple[list[OrcamentoItem], list[str]]:
    area_laje = dados.largura_total * dados.vao
    comprimento_vigotas_m = quant.n_vigotas * dados.vao
    largura_enchimento_m = max(dados.intereixo - vigota.b_nerv / 100.0, 0.0)
    area_enchimento = max(quant.n_vigotas - 1, 0) * dados.vao * largura_enchimento_m
    specs = [
        ("montagem_laje_m2", area_laje),
        ("lancamento_concreto_m3", quant.volume_capa_m3),
        ("adensamento_concreto_m3", quant.volume_capa_m3),
        ("escoramento_m2", area_laje),
        ("desforma_m2", area_laje),
        ("aplicacao_tela_m2", area_laje),
        ("assentamento_vigota_m", comprimento_vigotas_m),
        ("preenchimento_enchimento_m2", area_enchimento),
        ("acabamento_capa_m2", area_laje),
    ]

    itens: list[OrcamentoItem] = []
    alertas: list[str] = []
    for servico_codigo, quantidade in specs:
        item, alerta = _item_servico(
            servico_codigo=servico_codigo,
            quantidade=quantidade,
            regiao=regiao,
        )
        if item is not None:
            itens.append(item)
        if alerta is not None:
            alertas.append(alerta)
    return itens, alertas


def _itens_indiretos(
    subtotal_direto: float,
    regiao: str,
) -> tuple[list[OrcamentoItem], list[str]]:
    itens: list[OrcamentoItem] = []
    alertas: list[str] = []
    bdi_item = _buscar_indireto("bdi_simples", regiao)
    if bdi_item is None:
        alertas.append(f"Custo indireto nao encontrado para bdi_simples em {regiao}.")
        return itens, alertas

    custo_total = round(subtotal_direto * bdi_item.valor / 100.0, 2)
    itens.append(
        OrcamentoItem(
            categoria="indiretos",
            codigo=bdi_item.codigo,
            descricao=bdi_item.descricao,
            unidade=bdi_item.tipo,
            quantidade=round(subtotal_direto, 2),
            quantidade_compra=round(subtotal_direto, 2),
            unidade_compra=bdi_item.tipo,
            perda_percentual=0.0,
            preco_unitario=round(bdi_item.valor, 2),
            custo_total=custo_total,
            observacoes="MVP aplica apenas BDI simplificado para evitar sobreposicao de percentuais.",
        )
    )
    return itens, alertas


def calcular_orcamento_preliminar(
    dados: DadosLaje,
    resultado: ResultadoDimensionamento,
    quant: Quantitativos,
    vigota: DadosVigota,
    *,
    regiao: str = REGIAO_PADRAO,
) -> OrcamentoResultado:
    regiao_efetiva, alertas_regiao = _resolver_regiao_referencia(regiao)
    itens_materiais, alertas_materiais = _itens_materiais(dados, resultado, quant, vigota, regiao_efetiva)
    itens_mao_obra, alertas_mao_obra = _itens_mao_de_obra(dados, quant, vigota, regiao_efetiva)

    subtotal_materiais = round(sum(item.custo_total for item in itens_materiais), 2)
    subtotal_mao_obra = round(sum(item.custo_total for item in itens_mao_obra), 2)
    subtotal_direto = round(subtotal_materiais + subtotal_mao_obra, 2)

    itens_indiretos, alertas_indiretos = _itens_indiretos(subtotal_direto, regiao_efetiva)
    subtotal_indiretos = round(sum(item.custo_total for item in itens_indiretos), 2)

    area_laje = dados.largura_total * dados.vao
    total_geral = round(subtotal_direto + subtotal_indiretos, 2)
    custo_unitario_m2 = round(total_geral / area_laje, 2) if area_laje > 0 else 0.0
    itens_ordenados = sorted(
        [*itens_materiais, *itens_mao_obra, *itens_indiretos],
        key=lambda item: item.custo_total,
        reverse=True,
    )
    resumo_comercial = ResumoComercial(
        top_insumos=[
            ResumoComercialItem(
                codigo=item.codigo,
                descricao=item.descricao[:40],
                valor=item.custo_total,
            )
            for item in itens_ordenados[:5]
        ],
        total_geral=total_geral,
        custo_unitario_m2=custo_unitario_m2,
        area_laje_m2=round(area_laje, 3),
        regiao=regiao_efetiva,
    )

    return OrcamentoResultado(
        regiao=regiao_efetiva,
        materiais={item.codigo: item for item in itens_materiais},
        mao_obra={item.codigo: item for item in itens_mao_obra},
        indiretos={item.codigo: item for item in itens_indiretos},
        itens=itens_ordenados,
        resumo=OrcamentoResumo(
            area_laje_m2=round(area_laje, 3),
            subtotal_materiais=subtotal_materiais,
            subtotal_mao_obra=subtotal_mao_obra,
            subtotal_direto=subtotal_direto,
            subtotal_indiretos=subtotal_indiretos,
            total_geral=total_geral,
            custo_unitario_m2=custo_unitario_m2,
        ),
        resumo_comercial=resumo_comercial,
        alertas=[*alertas_regiao, *alertas_materiais, *alertas_mao_obra, *alertas_indiretos],
    )


def obter_referencias_custos(regiao: str = REGIAO_PADRAO) -> dict:
    regiao_material, alertas = _resolver_regiao_referencia(regiao)
    materiais = [
        {
            "tipo": item.item_tipo,
            "codigo": item.item_codigo,
            "descricao": item.descricao,
            "unidade": item.unidade,
            "preco_unitario": item.preco_unitario,
            "fonte": item.fonte,
            "regiao": item.regiao,
        }
        for item in _carregar_precos_materiais()
        if item.regiao == regiao_material
    ]

    mao_obra = []
    for servicos in _carregar_precos_servicos().values():
        servico = _selecionar_por_regiao(servicos, regiao_material)
        mao_obra.append(
            {
                "codigo": servico.servico_codigo,
                "descricao": servico.descricao,
                "unidade": servico.unidade,
                "preco_unitario": servico.preco_unitario,
                "fonte": servico.fonte,
                "regiao": servico.regiao,
            }
        )

    indiretos = []
    for itens in _carregar_custos_indiretos().values():
        indireto = _selecionar_por_regiao(itens, regiao_material)
        indiretos.append(
            {
                "codigo": indireto.codigo,
                "descricao": indireto.descricao,
                "tipo": indireto.tipo,
                "valor": indireto.valor,
                "regiao": indireto.regiao,
            }
        )

    regras_comerciais = [
        {
            "tipo": regra.item_tipo,
            "codigo": regra.item_codigo,
            "multiplo_compra": regra.multiplo_compra,
            "unidade_compra": regra.unidade_compra,
            "perda_percentual": regra.perda_percentual,
        }
        for regra in _carregar_regras_comerciais().values()
    ]

    return {
        "regiao": regiao_material,
        "data_referencia": next(
            (item.data_referencia for item in _carregar_precos_materiais() if item.regiao == regiao_material),
            None,
        ),
        "materiais": materiais,
        "mao_obra": sorted(mao_obra, key=lambda item: item["codigo"]),
        "indiretos": sorted(indiretos, key=lambda item: item["codigo"]),
        "regras_comerciais": sorted(regras_comerciais, key=lambda item: (item["tipo"], item["codigo"])),
        "alertas": alertas,
    }
