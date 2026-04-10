"""
Constantes e parâmetros de material do domínio técnico.
Rastreável a: docs/dominio/01_matriz_dominio_tecnico.md §2 e §3
"""

import math
from dataclasses import dataclass
from typing import Optional


# ---------------------------------------------------------------------------
# Coeficientes de ponderação (NBR 6118 Tab. 1)
# ---------------------------------------------------------------------------

GAMMA_C = 1.4   # Coef. ponderação do concreto (ELU)
GAMMA_S = 1.15  # Coef. ponderação do aço (ELU)
GAMMA_G = 1.4   # Coef. ponderação carga permanente (ELU, desfavorável)
GAMMA_Q = 1.4   # Coef. ponderação carga variável (ELU)
ALPHA_C = 0.85  # Redução de resistência do concreto (NBR 6118 §17.2.2)

# Coef. ψ2 por uso (NBR 6118 §11.7 + NBR 6120)
PSI2 = {
    "residencial_dormitorio": 0.3,
    "residencial_social":     0.3,
    "comercial_escritorio":   0.4,
    "comercial_loja":         0.4,
    "forro":                  0.2,
}

# Cargas variáveis características por uso (kN/m²) — NBR 6120:2019 Tab. 2
CARGA_ACIDENTAL = {
    "residencial_dormitorio": 1.5,
    "residencial_social":     2.0,
    "comercial_escritorio":   3.0,
    "comercial_loja":         4.0,
    "forro":                  0.5,
}


# ---------------------------------------------------------------------------
# Concreto
# ---------------------------------------------------------------------------

def modulo_elasticidade_secante(fck_mpa: float) -> float:
    """Ecs = 5600 × √fck  (NBR 6118 §8.2.8), resultado em MPa."""
    return 5600.0 * math.sqrt(fck_mpa)


def fcd(fck_mpa: float) -> float:
    """Resistência de cálculo à compressão: fcd = αc × fck / γc (MPa)."""
    return ALPHA_C * fck_mpa / GAMMA_C


def fctm(fck_mpa: float) -> float:
    """Resistência média à tração: fctm = 0,3 × fck^(2/3) (NBR 6118 §8.2.5)."""
    return 0.3 * (fck_mpa ** (2.0 / 3.0))


def fctk_inf(fck_mpa: float) -> float:
    """Resistência característica inferior à tração: fctk,inf = 0,7 × fctm."""
    return 0.7 * fctm(fck_mpa)


def fctd_val(fck_mpa: float) -> float:
    """Resistência de cálculo à tração: fctd = fctk,inf / γc."""
    return fctk_inf(fck_mpa) / GAMMA_C


# ---------------------------------------------------------------------------
# Aço
# ---------------------------------------------------------------------------

FYK = {"CA-50": 500.0, "CA-60": 600.0}  # MPa
ES_ACO = 210_000.0  # MPa


def fyd(classe_aco: str) -> float:
    """Resistência de cálculo do aço: fyd = fyk / γs (MPa)."""
    return FYK[classe_aco] / GAMMA_S


# ---------------------------------------------------------------------------
# Armadura mínima (NBR 6118 §17.3.5)
# ---------------------------------------------------------------------------

RHO_MIN = {  # CA-50
    20: 0.0015,
    25: 0.0015,
    30: 0.0020,
    35: 0.0025,
    40: 0.0028,
}


def rho_minimo(fck_mpa: float) -> float:
    """Retorna ρ_min para CA-50 conforme fck. Interpola por faixa."""
    fck_int = int(fck_mpa)
    chaves = sorted(RHO_MIN.keys())
    for k in chaves:
        if fck_int <= k:
            return RHO_MIN[k]
    return RHO_MIN[chaves[-1]]


# ---------------------------------------------------------------------------
# Vigota (dados do catálogo)
# ---------------------------------------------------------------------------

@dataclass
class DadosVigota:
    codigo: str
    h_vigota: float     # cm
    b_nerv: float       # cm — largura da nervura
    intereixo: float    # cm — intereixo padrão do catálogo
    As_base: float      # cm² — armadura da vigota
    fck_vigota: float   # MPa — fck do concreto da vigota (fabricante)
    vao_max: float      # m
    capa_min: float = 4.0  # cm


# Banco de vigotas (referência — TODO: validar com fabricante)
# Rastreável a: docs/dominio/02_catalogo_materiais.md §1.2
CATALOGO_VIGOTAS: dict[str, DadosVigota] = {
    "TR 8644":  DadosVigota("TR 8644",  h_vigota=8.0,  b_nerv=12.0, intereixo=42.0, As_base=0.95, fck_vigota=35.0, vao_max=6.0),
    "TR 10644": DadosVigota("TR 10644", h_vigota=10.0, b_nerv=12.0, intereixo=42.0, As_base=1.26, fck_vigota=35.0, vao_max=7.5),
    "TR 12644": DadosVigota("TR 12644", h_vigota=12.0, b_nerv=12.0, intereixo=42.0, As_base=1.58, fck_vigota=35.0, vao_max=9.0),
    "TR 8648":  DadosVigota("TR 8648",  h_vigota=8.0,  b_nerv=12.0, intereixo=48.0, As_base=0.95, fck_vigota=35.0, vao_max=5.5),
    "TR 10648": DadosVigota("TR 10648", h_vigota=10.0, b_nerv=12.0, intereixo=48.0, As_base=1.26, fck_vigota=35.0, vao_max=7.0),
}


def get_vigota(codigo: str) -> DadosVigota:
    if codigo not in CATALOGO_VIGOTAS:
        raise ValueError(f"Vigota '{codigo}' não encontrada no catálogo. "
                         f"Opções: {list(CATALOGO_VIGOTAS.keys())}")
    return CATALOGO_VIGOTAS[codigo]
