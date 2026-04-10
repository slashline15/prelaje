"""
Módulo de cálculo de carregamentos.
Rastreável a: docs/dominio/01_matriz_dominio_tecnico.md §3 e §4
"""

from dataclasses import dataclass
from .materiais import (
    CARGA_ACIDENTAL, PSI2, GAMMA_G, GAMMA_Q,
    DadosVigota,
)

PESO_CONCRETO = 25.0   # kN/m³
PESO_EPS      = 0.15   # kN/m³


@dataclass
class ResultadoCargas:
    g_pp: float    # kN/m² — peso próprio da laje
    g_rev: float   # kN/m² — revestimento (input do usuário)
    g_k: float     # kN/m² — carga permanente total característica
    q_k: float     # kN/m² — carga variável característica
    q_sd: float    # kN/m² — combinação ELU
    q_ser: float   # kN/m² — combinação ELS (quasi-permanente)
    w_sd: float    # kN/m  — carga linear ELU por nervura
    w_ser: float   # kN/m  — carga linear ELS por nervura


def calcular_cargas(
    uso: str,
    vigota: DadosVigota,
    h_capa_m: float,
    h_enc_m: float,
    g_revestimento: float,
) -> ResultadoCargas:
    """
    Calcula carregamentos da laje.

    Args:
        uso: Identificador de uso conforme UsoLaje enum
        vigota: Dados da vigota selecionada
        h_capa_m: Espessura da capa em metros
        h_enc_m: Altura do enchimento em metros
        g_revestimento: Carga de revestimento adicional (kN/m²)

    Returns:
        ResultadoCargas com todas as combinações calculadas
    """
    b_nerv_m = vigota.b_nerv / 100.0   # cm → m
    s_m      = vigota.intereixo / 100.0  # cm → m

    # Peso próprio da capa de concreto
    g_capa = PESO_CONCRETO * h_capa_m

    # Peso do enchimento EPS (desconta nervura)
    frac_enc = 1.0 - b_nerv_m / s_m
    g_enc = PESO_EPS * h_enc_m * frac_enc

    g_pp = g_capa + g_enc
    g_k  = g_pp + g_revestimento
    q_k  = CARGA_ACIDENTAL[uso]
    psi2 = PSI2[uso]

    # Combinações NBR 6118 §11.7
    q_sd  = GAMMA_G * g_k + GAMMA_Q * q_k
    q_ser = g_k + psi2 * q_k

    # Carga linear por nervura (kN/m)
    w_sd  = q_sd  * s_m
    w_ser = q_ser * s_m

    return ResultadoCargas(
        g_pp=round(g_pp, 4),
        g_rev=g_revestimento,
        g_k=round(g_k, 4),
        q_k=q_k,
        q_sd=round(q_sd, 4),
        q_ser=round(q_ser, 4),
        w_sd=round(w_sd, 4),
        w_ser=round(w_ser, 4),
    )
