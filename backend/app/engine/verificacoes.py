"""
Verificações de ELU e ELS.
Rastreável a: docs/dominio/01_matriz_dominio_tecnico.md §7 e §8
"""

import math
from dataclasses import dataclass
from .materiais import (
    fcd as calc_fcd,
    fyd as calc_fyd,
    fctk_inf,
    fctd_val,
    modulo_elasticidade_secante,
    rho_minimo,
    ALPHA_C,
    DadosVigota,
)


# ---------------------------------------------------------------------------
# Geometria da Seção T
# ---------------------------------------------------------------------------

@dataclass
class SecaoT:
    b_ef: float   # m — largura efetiva da mesa
    b_nerv: float # m — largura da nervura
    h_f: float    # m — espessura da capa (mesa)
    h_nerv: float # m — altura da nervura
    h_total: float# m — altura total
    d: float      # m — altura útil
    Ic: float     # m⁴ — inércia da seção não-fissurada


def calcular_secao_t(
    vigota: DadosVigota,
    h_capa_m: float,
    L: float,
    c_nom: float = 0.025,   # m — cobrimento nominal padrão
    phi_long: float = 0.010, # m — diâmetro longitudinal estimado
) -> SecaoT:
    """
    Calcula geometria efetiva da seção T.
    Rastreável a: §6 da Matriz de Domínio.
    """
    b_nerv  = vigota.b_nerv / 100.0   # cm → m
    h_nerv  = vigota.h_vigota / 100.0  # cm → m
    h_total = h_nerv + h_capa_m
    s_m     = vigota.intereixo / 100.0

    # Largura efetiva da mesa (NBR 6118 §14.6.2)
    b_ef = min(b_nerv + L / 10.0, s_m)

    # Centroide e inércia (seção T não-fissurada)
    A_mesa  = b_ef  * h_capa_m
    A_nerv  = b_nerv * h_nerv
    y_mesa  = h_capa_m / 2.0
    y_nerv  = h_capa_m + h_nerv / 2.0

    y_cg = (A_mesa * y_mesa + A_nerv * y_nerv) / (A_mesa + A_nerv)

    Ic_mesa = (b_ef * h_capa_m**3 / 12.0
               + A_mesa * (y_cg - y_mesa)**2)
    Ic_nerv = (b_nerv * h_nerv**3 / 12.0
               + A_nerv * (y_cg - y_nerv)**2)
    Ic = Ic_mesa + Ic_nerv

    # Altura útil
    d = h_total - c_nom - phi_long / 2.0

    return SecaoT(
        b_ef=b_ef, b_nerv=b_nerv,
        h_f=h_capa_m, h_nerv=h_nerv,
        h_total=h_total, d=d, Ic=Ic,
    )


# ---------------------------------------------------------------------------
# ELU — Flexão
# ---------------------------------------------------------------------------

@dataclass
class ResultadoFlexao:
    as_calculado_cm2: float
    as_minimo_cm2: float
    xd: float   # x/d — posição relativa da linha neutra
    aprovado: bool
    ln_na_mesa: bool
    alertas: list[str]


def verificar_flexao(
    msd: float,          # kN·m
    secao: SecaoT,
    fck_mpa: float,
    classe_aco: str,
) -> ResultadoFlexao:
    """
    Dimensionamento à flexão simples — Seção T.
    Rastreável a: §7.1 da Matriz de Domínio.
    """
    alertas = []
    fcd_v = calc_fcd(fck_mpa)  # MPa
    fyd_v = calc_fyd(classe_aco)  # MPa

    # Converter MPa→kN/m² e m→m já em SI (kN, m)
    fcd_kn  = fcd_v * 1000.0   # kN/m²
    fyd_kn  = fyd_v * 1000.0   # kN/m²

    d   = secao.d
    b   = secao.b_ef
    h_f = secao.h_f
    b_w = secao.b_nerv

    # Verificar se LN está na mesa
    MRd_mesa = ALPHA_C * fcd_kn * b * h_f * (d - h_f / 2.0)
    ln_na_mesa = msd <= MRd_mesa

    if ln_na_mesa:
        # Calcular como retangular b_ef
        delta = 1.0 - 2.0 * msd / (ALPHA_C * fcd_kn * b * d**2)
        if delta < 0:
            raise ValueError("Seção insuficiente — momento excede capacidade máxima com b_ef.")
        xd = 1.0 - math.sqrt(delta)
        x  = xd * d
        As_m2 = ALPHA_C * fcd_kn * b * x / fyd_kn  # m²
    else:
        alertas.append("LN fora da mesa — usar seção T completa ou aumentar seção.")
        # Contribuição da mesa
        Mf_mesa = ALPHA_C * fcd_kn * b * h_f * (d - h_f / 2.0)
        Mf_nerv = msd - Mf_mesa
        As_mesa = ALPHA_C * fcd_kn * b * h_f / fyd_kn
        delta = 1.0 - 2.0 * Mf_nerv / (ALPHA_C * fcd_kn * b_w * d**2)
        if delta < 0:
            raise ValueError("Seção da nervura insuficiente — viga não dimensionável no MVP.")
        xd    = 1.0 - math.sqrt(delta)
        x     = xd * d
        As_nerv = ALPHA_C * fcd_kn * b_w * x / fyd_kn
        As_m2   = As_mesa + As_nerv

    As_cm2 = As_m2 * 10_000.0  # m² → cm²

    # Armadura mínima
    rho_min = rho_minimo(fck_mpa)
    As_min  = rho_min * (b_w * d) * 10_000.0  # cm²

    # Limites x/d (NBR 6118 §14.6.4)
    xd_lim = 0.45 if classe_aco == "CA-50" else 0.35
    aprovado = (xd <= xd_lim) and (As_cm2 >= As_min)

    if xd > xd_lim:
        alertas.append(f"x/d = {xd:.3f} excede limite {xd_lim} — armadura dupla necessária (fora do MVP).")
    if As_cm2 < As_min:
        alertas.append(f"As = {As_cm2:.2f} cm² < As_min = {As_min:.2f} cm².")

    return ResultadoFlexao(
        as_calculado_cm2=round(As_cm2, 3),
        as_minimo_cm2=round(As_min, 3),
        xd=round(xd, 4),
        aprovado=aprovado,
        ln_na_mesa=ln_na_mesa,
        alertas=alertas,
    )


# ---------------------------------------------------------------------------
# ELU — Cisalhamento (NBR 6118 §17.4)
# ---------------------------------------------------------------------------

@dataclass
class ResultadoCisalhamento:
    vrd1: float    # kN — resistência sem armadura transversal
    aprovado: bool
    alerta: str


def verificar_cisalhamento(
    vsd: float,        # kN
    secao: SecaoT,
    fck_mpa: float,
    As_cm2: float,
) -> ResultadoCisalhamento:
    """
    Verificação de cisalhamento sem armadura transversal.
    Rastreável a: §7.3 da Matriz de Domínio.
    """
    tau_rd = 0.25 * fctd_val(fck_mpa) * 1000.0  # kN/m²
    d      = secao.d
    b_w    = secao.b_nerv
    k      = max(1.0, 1.6 - d)   # d em metros
    rho_l  = min(As_cm2 / 10_000.0 / (b_w * d), 0.02)

    VRd1 = (tau_rd * k * (1.2 + 40.0 * rho_l)) * b_w * d  # kN

    aprovado = vsd <= VRd1
    alerta = (
        "" if aprovado else
        f"Vsd={vsd:.2f} kN > VRd1={VRd1:.2f} kN — cisalhamento excede capacidade. "
        "Estribos necessários (fora do escopo do MVP). Consulte engenheiro."
    )

    return ResultadoCisalhamento(
        vrd1=round(VRd1, 3),
        aprovado=aprovado,
        alerta=alerta,
    )


# ---------------------------------------------------------------------------
# ELS — Flecha (Modelo de Branson)
# ---------------------------------------------------------------------------

@dataclass
class ResultadoFlecha:
    flecha_imediata_cm: float
    flecha_diferida_cm: float
    flecha_total_cm: float
    flecha_limite_cm: float
    aprovado: bool
    alerta: str


def _inertia_fissurada(secao: SecaoT, As_m2: float, fck_mpa: float) -> float:
    """
    Momento de inércia da seção fissurada (seção T com armadura de tração).
    Simplificação: apenas contribuição da armadura.
    """
    n  = 210_000.0 / modulo_elasticidade_secante(fck_mpa)  # relação modular
    b  = secao.b_ef
    b_w= secao.b_nerv
    h_f= secao.h_f
    d  = secao.d

    # Posição da LN fissurada (iteração ou fórmula quadrática)
    # Para seção T: b_ef × x²/2 - n × As × (d - x) = 0
    # Caso LN na mesa: b_ef × x²/2 = n × As × (d - x)
    a = b / 2.0
    bq = n * As_m2
    c_ = -n * As_m2 * d
    x_fiss = (-bq + math.sqrt(bq**2 - 4*a*c_)) / (2*a)
    x_fiss = max(0.0, min(x_fiss, d))

    Ics = b * x_fiss**3 / 3.0 + n * As_m2 * (d - x_fiss)**2
    return Ics


def verificar_flecha(
    w_ser: float,    # kN/m — carga de serviço por nervura
    L: float,        # m
    secao: SecaoT,
    fck_mpa: float,
    As_cm2: float,
) -> ResultadoFlecha:
    """
    Cálculo de flecha pelo modelo de Branson.
    Rastreável a: §8.1 da Matriz de Domínio.
    """
    Ecs  = modulo_elasticidade_secante(fck_mpa) * 1000.0  # kN/m²
    Ic   = secao.Ic
    As_m2= As_cm2 / 10_000.0

    # Momento de fissuração
    y_t  = secao.h_total - (secao.h_f / 2.0)  # fibra inferior (tração)
    Mcr  = fctk_inf(fck_mpa) * 1000.0 * Ic / y_t  # kN·m

    # Momento de serviço (biapoiada)
    Ma = w_ser * L**2 / 8.0  # kN·m

    if Ma <= 0:
        return ResultadoFlecha(0, 0, 0, L / 2.5, True, "")

    # Inércia de Branson
    Ics = _inertia_fissurada(secao, As_m2, fck_mpa)
    ratio = min(Mcr / Ma, 1.0)
    Ie   = min(Ic * ratio**3 + Ics * (1 - ratio**3), Ic)

    # Flecha imediata (viga biapoiada, carga distribuída)
    delta_i = 5.0 * w_ser * L**4 / (384.0 * Ecs * Ie)  # m

    # Flecha diferida (fluência, φ = 2,0)
    phi = 2.0
    # Carga permanente ≈ 60% da carga de serviço (simplificação)
    delta_d = phi * 0.6 * delta_i

    delta_total = delta_i + delta_d
    delta_lim   = L / 250.0

    delta_i_cm     = round(delta_i * 100, 3)
    delta_d_cm     = round(delta_d * 100, 3)
    delta_total_cm = round(delta_total * 100, 3)
    delta_lim_cm   = round(delta_lim * 100, 3)

    aprovado = delta_total <= delta_lim
    alerta   = (
        "" if aprovado else
        f"Flecha total = {delta_total_cm} cm excede limite de {delta_lim_cm} cm (L/250). "
        "Verificar continuidade ou aumentar seção."
    )

    return ResultadoFlecha(
        flecha_imediata_cm=delta_i_cm,
        flecha_diferida_cm=delta_d_cm,
        flecha_total_cm=delta_total_cm,
        flecha_limite_cm=delta_lim_cm,
        aprovado=aprovado,
        alerta=alerta,
    )
