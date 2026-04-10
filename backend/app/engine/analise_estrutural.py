"""
Análise estrutural: Método da Rigidez Direta.
Rastreável a: docs/dominio/01_matriz_dominio_tecnico.md §5
"""

import math
from dataclasses import dataclass

import numpy as np


@dataclass
class EsforcosVigotas:
    msd_max: float   # kN·m — momento fletor máximo de cálculo
    vsd_max: float   # kN   — cortante máximo de cálculo
    reacoes: list[float]  # kN — reações de apoio [Ra, Rb, ...]


# ---------------------------------------------------------------------------
# Viga Biapoiada — fórmulas fechadas
# ---------------------------------------------------------------------------

def esforcos_biapoiada(w_sd: float, L: float) -> EsforcosVigotas:
    """
    Vão simplesmente apoiado com carga uniformemente distribuída.

    Args:
        w_sd: Carga linear de cálculo (kN/m)
        L: Vão livre (m)

    Returns:
        EsforcosVigotas com Msd e Vsd máximos
    """
    msd_max = w_sd * L ** 2 / 8.0
    vsd_max = w_sd * L / 2.0
    reacao  = vsd_max

    return EsforcosVigotas(
        msd_max=round(msd_max, 4),
        vsd_max=round(vsd_max, 4),
        reacoes=[round(reacao, 4), round(reacao, 4)],
    )


# ---------------------------------------------------------------------------
# Viga Contínua — Método da Rigidez Direta
# ---------------------------------------------------------------------------

def _matriz_rigidez_membro(EI: float, L: float) -> np.ndarray:
    """
    Matriz de rigidez local de viga de Euler-Bernoulli (4×4).
    GDLs: [v_i, θ_i, v_j, θ_j]
    """
    c = EI / (L ** 3)
    return c * np.array([
        [ 12,   6*L,  -12,   6*L],
        [ 6*L, 4*L**2, -6*L, 2*L**2],
        [-12,  -6*L,   12,  -6*L],
        [ 6*L, 2*L**2, -6*L, 4*L**2],
    ])


def _vetor_carga_equivalente(w: float, L: float) -> np.ndarray:
    """Vetor de forças nodais equivalentes para carga distribuída w."""
    return np.array([
        w * L / 2,
        w * L**2 / 12,
        w * L / 2,
        -w * L**2 / 12,
    ])


def esforcos_continua(
    w_sd_list: list[float],
    L_list: list[float],
    EI_list: list[float],
) -> EsforcosVigotas:
    """
    Análise de viga contínua com n vãos pelo Método da Rigidez Direta.

    Args:
        w_sd_list: Carga linear em cada vão (kN/m)
        L_list: Comprimento de cada vão (m)
        EI_list: Rigidez de flexão EI em cada vão (kN·m²)

    Returns:
        EsforcosVigotas com Msd e Vsd máximos no conjunto
    """
    n_vaos = len(L_list)
    n_nos  = n_vaos + 1
    # GDLs por nó: deslocamento vertical (v) e rotação (θ)
    # Total de GDLs = 2 × n_nos
    n_gdl  = 2 * n_nos

    K_global = np.zeros((n_gdl, n_gdl))
    F_global = np.zeros(n_gdl)

    for i, (w, L, EI) in enumerate(zip(w_sd_list, L_list, EI_list)):
        k_loc = _matriz_rigidez_membro(EI, L)
        f_loc = _vetor_carga_equivalente(w, L)

        # GDLs do elemento: [v_i, θ_i, v_j, θ_j]
        gdls = [2*i, 2*i+1, 2*i+2, 2*i+3]

        for a, ga in enumerate(gdls):
            F_global[ga] += f_loc[a]
            for b, gb in enumerate(gdls):
                K_global[ga, gb] += k_loc[a, b]

    # Condições de contorno: v = 0 em todos os apoios (nós)
    apoios_gdl = [2*i for i in range(n_nos)]
    gdls_livres = [g for g in range(n_gdl) if g not in apoios_gdl]

    K_red = K_global[np.ix_(gdls_livres, gdls_livres)]
    F_red = F_global[gdls_livres]

    u_red = np.linalg.solve(K_red, F_red)

    u = np.zeros(n_gdl)
    for idx, g in enumerate(gdls_livres):
        u[g] = u_red[idx]

    # Recuperar esforços e reações
    msd_max = 0.0
    vsd_max = 0.0
    reacoes = []

    for i, (w, L, EI) in enumerate(zip(w_sd_list, L_list, EI_list)):
        gdls = [2*i, 2*i+1, 2*i+2, 2*i+3]
        u_loc = u[gdls]
        k_loc = _matriz_rigidez_membro(EI, L)
        f_loc = _vetor_carga_equivalente(w, L)
        f_int = k_loc @ u_loc - f_loc

        # f_int = [V_i, M_i, V_j, M_j] (sinais da convenção adotada)
        V_i = abs(f_int[0])
        V_j = abs(f_int[2])
        M_i = abs(f_int[1])
        M_j = abs(f_int[3])

        vsd_max = max(vsd_max, V_i, V_j)

        # Momento máximo no vão (encontra a seção de cortante zero)
        x_zero = V_i / w if w > 0 else L / 2
        x_zero = min(max(x_zero, 0.0), L)
        M_vao  = abs(f_int[1] + V_i * x_zero - w * x_zero**2 / 2)
        msd_max = max(msd_max, M_i, M_j, M_vao)

        if i == 0:
            reacoes.append(round(float(V_i), 4))

    reacoes.append(round(float(V_j), 4))

    return EsforcosVigotas(
        msd_max=round(msd_max, 4),
        vsd_max=round(vsd_max, 4),
        reacoes=reacoes,
    )
