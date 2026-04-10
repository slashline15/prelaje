"""
Modo catálogo: busca de soluções pré-dimensionadas por vão e carga total.
Rastreável a: docs/dominio/02_catalogo_materiais.md §4
"""

import csv
from collections import defaultdict
from dataclasses import dataclass
from functools import lru_cache
from math import pi
from pathlib import Path
from typing import Optional

from .materiais import normalizar_codigo_vigota


KGF_M2_POR_KN_M2 = 101.971621
CATALOGO_VERSION = "matriz_catalogo_csv_v1"
MATRIZ_CATALOGO_CSV = Path(__file__).resolve().parents[2] / "db" / "matriz_catalogo.csv"


@dataclass(frozen=True)
class ReforcoCatalogo:
    diametro_mm: float
    quantidade: int

    @property
    def as_total_cm2(self) -> float:
        area_uma_barra_mm2 = pi * (self.diametro_mm ** 2) / 4.0
        return round(self.quantidade * area_uma_barra_mm2 / 100.0, 3)


@dataclass(frozen=True)
class FaixaCargaCatalogo:
    carga_max_kgf_m2: float
    reforco: Optional[ReforcoCatalogo]
    escoramento_max_m: float


@dataclass(frozen=True)
class LinhaCatalogo:
    vao_m: float
    cargas: tuple[FaixaCargaCatalogo, ...]


@dataclass(frozen=True)
class SolucaoCatalogo:
    vao_tabelado: float
    carga_total_kgf_m2: float
    reforco: Optional[ReforcoCatalogo]
    escoramento_max_m: float
    dentro_do_catalogo: bool = True


class CatalogoLookupError(ValueError):
    def __init__(
        self,
        code: str,
        message: str,
        *,
        value: float | None = None,
        limit: float | None = None,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.value = value
        self.limit = limit


def _parse_optional_float(valor: str | None) -> Optional[float]:
    if valor is None or valor == "":
        return None
    return float(valor)


@lru_cache(maxsize=1)
def carregar_catalogo_solucoes() -> dict[tuple[str, int, int, int], tuple[LinhaCatalogo, ...]]:
    if not MATRIZ_CATALOGO_CSV.exists():
        raise FileNotFoundError(f"Matriz de catálogo não encontrada em {MATRIZ_CATALOGO_CSV}")

    agrupado: dict[tuple[str, int, int, int], dict[float, list[FaixaCargaCatalogo]]] = defaultdict(
        lambda: defaultdict(list)
    )

    with MATRIZ_CATALOGO_CSV.open(newline="", encoding="utf-8") as arquivo:
        for row in csv.DictReader(arquivo):
            codigo_vigota = normalizar_codigo_vigota(row["vigota_codigo"])
            fck_capa_mpa = int(round(float(row["fck_capa_mpa"])))
            intereixo_cm = int(round(float(row["intereixo_cm"])))
            capa_cm = int(round(float(row["capa_cm"])))
            vao_m = float(row["vao_m"])
            carga_max_kgf_m2 = float(row["carga_max_kgf_m2"])
            escoramento_max_m = float(row["escoramento_max_m"])

            diametro = _parse_optional_float(row.get("reforco_diam_mm"))
            quantidade = _parse_optional_float(row.get("reforco_qtd"))
            reforco = None
            if diametro is not None and quantidade is not None:
                reforco = ReforcoCatalogo(diametro, int(round(quantidade)))

            chave = (codigo_vigota, fck_capa_mpa, intereixo_cm, capa_cm)
            agrupado[chave][vao_m].append(
                FaixaCargaCatalogo(
                    carga_max_kgf_m2=carga_max_kgf_m2,
                    reforco=reforco,
                    escoramento_max_m=escoramento_max_m,
                )
            )

    resultado: dict[tuple[str, int, int, int], tuple[LinhaCatalogo, ...]] = {}
    for chave, por_vao in agrupado.items():
        linhas: list[LinhaCatalogo] = []
        for vao_m, cargas in sorted(por_vao.items()):
            linhas.append(
                LinhaCatalogo(
                    vao_m=vao_m,
                    cargas=tuple(sorted(cargas, key=lambda item: item.carga_max_kgf_m2)),
                )
            )
        resultado[chave] = tuple(linhas)
    return resultado


def codigos_catalogo_disponiveis() -> dict[str, dict[str, list[int]]]:
    resumo: dict[str, dict[str, set[int]]] = defaultdict(
        lambda: {"fck_mpa": set(), "intereixo_cm": set(), "capa_cm": set()}
    )
    for codigo, fck, intereixo_cm, capa_cm in carregar_catalogo_solucoes():
        resumo[codigo]["fck_mpa"].add(fck)
        resumo[codigo]["intereixo_cm"].add(intereixo_cm)
        resumo[codigo]["capa_cm"].add(capa_cm)
    return {
        codigo: {
            campo: sorted(valores)
            for campo, valores in dados.items()
        }
        for codigo, dados in sorted(resumo.items())
    }


def carga_total_catalogo_kgf_m2(g_k: float, q_k: float) -> float:
    return round((g_k + q_k) * KGF_M2_POR_KN_M2, 1)


def buscar_solucao_catalogo(
    codigo_vigota: str,
    fck_capa_mpa: float,
    intereixo_cm: float,
    capa_cm: float,
    vao_solicitado_m: float,
    carga_total_kgf_m2: float,
) -> SolucaoCatalogo:
    codigo_vigota = normalizar_codigo_vigota(codigo_vigota)
    fck_capa_mpa_int = int(round(fck_capa_mpa))
    intereixo_cm_int = int(round(intereixo_cm))
    capa_cm_int = int(round(capa_cm))
    solucoes = carregar_catalogo_solucoes()
    tabela = solucoes.get((codigo_vigota, fck_capa_mpa_int, intereixo_cm_int, capa_cm_int))
    if tabela is None:
        tem_codigo_fck = any(
            chave[0] == codigo_vigota and chave[1] == fck_capa_mpa_int
            for chave in solucoes
        )
        if tem_codigo_fck:
            raise CatalogoLookupError(
                "CATALOGO_COMBINACAO_INDISPONIVEL",
                f"Não há matriz homologada para {codigo_vigota} com "
                f"fck={fck_capa_mpa_int} MPa, intereixo={intereixo_cm_int} cm "
                f"e capa={capa_cm_int} cm.",
                value=capa_cm,
            )
        raise CatalogoLookupError(
            "CATALOGO_FCK_INDISPONIVEL",
            f"Não há matriz de catálogo homologada para a vigota {codigo_vigota} "
            f"com fck={fck_capa_mpa_int} MPa.",
            value=fck_capa_mpa,
        )

    linha = next((item for item in tabela if item.vao_m >= vao_solicitado_m), None)
    if linha is None:
        raise CatalogoLookupError(
            "L_MAX_CATALOGO",
            f"Vão {vao_solicitado_m} m excede o maior valor tabelado para {codigo_vigota}.",
            value=vao_solicitado_m,
            limit=tabela[-1].vao_m,
        )

    faixa = next(
        (item for item in linha.cargas if item.carga_max_kgf_m2 >= carga_total_kgf_m2),
        None,
    )
    if faixa is None:
        maior_carga = linha.cargas[-1].carga_max_kgf_m2
        raise CatalogoLookupError(
            "CARGA_FORA_CATALOGO",
            f"Carga total {carga_total_kgf_m2:.1f} kgf/m² excede a faixa do catálogo "
            f"para vão {linha.vao_m:.2f} m da vigota {codigo_vigota}.",
            value=carga_total_kgf_m2,
            limit=maior_carga,
        )

    return SolucaoCatalogo(
        vao_tabelado=linha.vao_m,
        carga_total_kgf_m2=carga_total_kgf_m2,
        reforco=faixa.reforco,
        escoramento_max_m=faixa.escoramento_max_m,
    )
