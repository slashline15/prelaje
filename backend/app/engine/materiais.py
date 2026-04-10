"""
Constantes e parâmetros de material do domínio técnico.
Rastreável a: docs/dominio/01_matriz_dominio_tecnico.md §2 e §3
"""

import csv
import math
import re
from dataclasses import dataclass
from pathlib import Path


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
    "residencial_dormitorios_salas_cozinha": 0.3,
    "residencial_banheiros": 0.3,
    "residencial_despensa_lavanderia": 0.3,
    "residencial_corredores_uso_comum": 0.3,
    "comercial_escritorios_salas_gerais": 0.4,
    "comercial_sanitarios": 0.4,
    "comercial_corredores_acesso_publico": 0.4,
    "comercial_arquivos_deslizantes": 0.4,
    "servico_forros_sem_acesso_pessoas": 0.3,
    "servico_garagens_veiculos_leves": 0.4,
    "educacao_salas_de_aula": 0.4,
    "biblioteca_sala_de_leitura": 0.4,
    "biblioteca_sala_de_estantes": 0.4,
}

PSI0 = {
    "residencial_dormitorios_salas_cozinha": 0.5,
    "residencial_banheiros": 0.5,
    "residencial_despensa_lavanderia": 0.5,
    "residencial_corredores_uso_comum": 0.5,
    "comercial_escritorios_salas_gerais": 0.7,
    "comercial_sanitarios": 0.7,
    "comercial_corredores_acesso_publico": 0.7,
    "comercial_arquivos_deslizantes": 0.7,
    "servico_forros_sem_acesso_pessoas": 0.5,
    "servico_garagens_veiculos_leves": 0.7,
    "educacao_salas_de_aula": 0.7,
    "biblioteca_sala_de_leitura": 0.7,
    "biblioteca_sala_de_estantes": 0.7,
}

PSI1 = {
    "residencial_dormitorios_salas_cozinha": 0.4,
    "residencial_banheiros": 0.4,
    "residencial_despensa_lavanderia": 0.4,
    "residencial_corredores_uso_comum": 0.4,
    "comercial_escritorios_salas_gerais": 0.6,
    "comercial_sanitarios": 0.6,
    "comercial_corredores_acesso_publico": 0.6,
    "comercial_arquivos_deslizantes": 0.6,
    "servico_forros_sem_acesso_pessoas": 0.4,
    "servico_garagens_veiculos_leves": 0.6,
    "educacao_salas_de_aula": 0.6,
    "biblioteca_sala_de_leitura": 0.6,
    "biblioteca_sala_de_estantes": 0.6,
}

# Cargas variáveis características por uso (kN/m²) — NBR 6120:2019 Tab. 2
CARGA_ACIDENTAL = {
    "residencial_dormitorio": 1.5,
    "residencial_social":     2.0,
    "comercial_escritorio":   3.0,
    "comercial_loja":         4.0,
    "forro":                  0.5,
    "residencial_dormitorios_salas_cozinha": 1.5,
    "residencial_banheiros": 1.5,
    "residencial_despensa_lavanderia": 2.0,
    "residencial_corredores_uso_comum": 3.0,
    "comercial_escritorios_salas_gerais": 2.5,
    "comercial_sanitarios": 2.5,
    "comercial_corredores_acesso_publico": 3.0,
    "comercial_arquivos_deslizantes": 5.0,
    "servico_forros_sem_acesso_pessoas": 0.5,
    "servico_garagens_veiculos_leves": 3.0,
    "educacao_salas_de_aula": 3.0,
    "biblioteca_sala_de_leitura": 2.0,
    "biblioteca_sala_de_estantes": 6.0,
}


@dataclass(frozen=True)
class ReferenciaUso:
    uso_id: str
    uso_categoria: str
    subcategoria: str
    carga_kn_m2: float
    psi_0: float
    psi_1: float
    psi_2: float
    depreciado: bool = False
    alias_de: str | None = None


@dataclass(frozen=True)
class ReferenciaRevestimento:
    id: int
    descricao: str
    g_rev_kn_m2: float


DB_DIR = Path(__file__).resolve().parents[2] / "db"


def _parse_bool_csv(valor: str | None) -> bool:
    if valor is None:
        return False
    return valor.strip().lower() in {"1", "true", "sim", "yes"}


def _carregar_usos_csv() -> tuple[
    dict[str, float],
    dict[str, float],
    dict[str, float],
    dict[str, float],
    dict[str, ReferenciaUso],
] | None:
    csv_path = DB_DIR / "classes_uso.csv"
    if not csv_path.exists():
        return None

    carga_acidental: dict[str, float] = {}
    psi0: dict[str, float] = {}
    psi1: dict[str, float] = {}
    psi2: dict[str, float] = {}
    referencias: dict[str, ReferenciaUso] = {}

    with csv_path.open(newline="", encoding="utf-8") as arquivo:
        for row in csv.DictReader(arquivo):
            uso_id = row["uso_id"].strip()
            referencia = ReferenciaUso(
                uso_id=uso_id,
                uso_categoria=row["uso_categoria"].strip(),
                subcategoria=row["subcategoria"].strip(),
                carga_kn_m2=float(row["carga_kn_m2"]),
                psi_0=float(row["psi_0"]),
                psi_1=float(row["psi_1"]),
                psi_2=float(row["psi_2"]),
                depreciado=_parse_bool_csv(row.get("depreciado")),
                alias_de=(row.get("alias_de") or "").strip() or None,
            )
            referencias[uso_id] = referencia
            carga_acidental[uso_id] = referencia.carga_kn_m2
            psi0[uso_id] = referencia.psi_0
            psi1[uso_id] = referencia.psi_1
            psi2[uso_id] = referencia.psi_2

    return carga_acidental, psi0, psi1, psi2, referencias


USOS_REFERENCIA: dict[str, ReferenciaUso] = {}
_usos_csv = _carregar_usos_csv()
if _usos_csv is not None:
    CARGA_ACIDENTAL, PSI0, PSI1, PSI2, USOS_REFERENCIA = _usos_csv
else:
    for uso_id, carga in CARGA_ACIDENTAL.items():
        USOS_REFERENCIA[uso_id] = ReferenciaUso(
            uso_id=uso_id,
            uso_categoria=uso_id.split("_", 1)[0],
            subcategoria=uso_id,
            carga_kn_m2=carga,
            psi_0=PSI0.get(uso_id),
            psi_1=PSI1.get(uso_id),
            psi_2=PSI2[uso_id],
            depreciado=uso_id in {
                "residencial_dormitorio",
                "residencial_social",
                "comercial_escritorio",
                "comercial_loja",
                "forro",
            },
            alias_de=None,
        )

USOS_DEPRECIADOS = {
    uso_id for uso_id, referencia in USOS_REFERENCIA.items() if referencia.depreciado
}


def carregar_revestimentos_csv() -> tuple[ReferenciaRevestimento, ...]:
    csv_path = DB_DIR / "preset_revestimentos.csv"
    if not csv_path.exists():
        return tuple()

    with csv_path.open(newline="", encoding="utf-8") as arquivo:
        return tuple(
            ReferenciaRevestimento(
                id=int(row["id"]),
                descricao=row["descricao"].strip(),
                g_rev_kn_m2=float(row["g_rev_kN_m2"]),
            )
            for row in csv.DictReader(arquivo)
        )


REVESTIMENTOS_REFERENCIA = carregar_revestimentos_csv()


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
    homologada_analitico: bool = True


@dataclass(frozen=True)
class ReferenciaTrelica:
    modelo: str
    designacao: str
    altura_mm: int
    diametro_superior_mm: float
    diametro_diagonal_mm: float
    diametro_inferior_mm: float
    peso_linear_kg_m: float


@dataclass(frozen=True)
class CompatibilidadeAltura:
    h_enchimento_cm: float
    h_total_cm: float


# Banco de vigotas (referência — TODO: validar com fabricante)
# Rastreável a: docs/dominio/02_catalogo_materiais.md §1.2
CATALOGO_VIGOTAS: dict[str, DadosVigota] = {
    "TR 8644":  DadosVigota("TR 8644",  h_vigota=8.0,  b_nerv=12.0, intereixo=42.0, As_base=0.95, fck_vigota=35.0, vao_max=6.0),
    "TR 10644": DadosVigota("TR 10644", h_vigota=10.0, b_nerv=12.0, intereixo=42.0, As_base=1.26, fck_vigota=35.0, vao_max=7.5),
    "TR 12644": DadosVigota("TR 12644", h_vigota=12.0, b_nerv=12.0, intereixo=42.0, As_base=1.58, fck_vigota=35.0, vao_max=9.0),
    "TR 8648":  DadosVigota("TR 8648",  h_vigota=8.0,  b_nerv=12.0, intereixo=48.0, As_base=0.95, fck_vigota=35.0, vao_max=5.5),
    "TR 10648": DadosVigota("TR 10648", h_vigota=10.0, b_nerv=12.0, intereixo=48.0, As_base=1.26, fck_vigota=35.0, vao_max=7.0),
}


VIGOTAS_REFERENCIA: dict[str, DadosVigota] = {
    **CATALOGO_VIGOTAS,
    "TB 12L": DadosVigota(
        "TB 12L",
        h_vigota=12.0,
        b_nerv=12.5,
        intereixo=42.0,
        As_base=0.0,
        fck_vigota=35.0,
        vao_max=6.0,
        capa_min=5.0,
        homologada_analitico=False,
    ),
    "TP-8-42": DadosVigota(
        "TP-8-42",
        h_vigota=8.0,
        b_nerv=12.5,
        intereixo=42.0,
        As_base=0.0,
        fck_vigota=35.0,
        vao_max=4.5,
        homologada_analitico=False,
    ),
    "TP-10-42": DadosVigota(
        "TP-10-42",
        h_vigota=10.0,
        b_nerv=12.5,
        intereixo=42.0,
        As_base=0.0,
        fck_vigota=35.0,
        vao_max=6.0,
        capa_min=5.0,
        homologada_analitico=False,
    ),
    "TT-08-42": DadosVigota(
        "TT-08-42",
        h_vigota=8.0,
        b_nerv=12.5,
        intereixo=42.0,
        As_base=0.0,
        fck_vigota=35.0,
        vao_max=4.5,
        homologada_analitico=False,
    ),
    "AT-8-42": DadosVigota(
        "AT-8-42",
        h_vigota=8.0,
        b_nerv=12.5,
        intereixo=42.0,
        As_base=0.0,
        fck_vigota=35.0,
        vao_max=4.5,
        homologada_analitico=False,
    ),
}


TRELICAS_REFERENCIA: tuple[ReferenciaTrelica, ...] = (
    ReferenciaTrelica("TB 8L", "TR 8644", 80, 6.0, 4.2, 4.2, 0.735),
    ReferenciaTrelica("TB 8M", "TR 8645", 80, 6.0, 4.2, 5.0, 0.825),
    ReferenciaTrelica("TB 12M", "TR 12645", 120, 6.0, 4.2, 5.0, 0.886),
    ReferenciaTrelica("TB 12R", "TR 12646", 120, 6.0, 4.2, 6.0, 1.016),
    ReferenciaTrelica("TB 16L", "TR 16745", 160, 7.0, 4.2, 5.0, 1.032),
    ReferenciaTrelica("TB 16R", "TR 16746", 160, 7.0, 4.2, 6.0, 1.168),
    ReferenciaTrelica("TB 20 L", "TR 20745", 200, 7.0, 4.2, 5.0, 1.111),
    ReferenciaTrelica("TB 20R", "TR 20756", 200, 7.0, 5.0, 6.0, 1.446),
    ReferenciaTrelica("TB 25M", "TR 25856", 250, 8.0, 5.0, 6.0, 1.686),
    ReferenciaTrelica("TB 25R", "TR 25858", 250, 8.0, 5.0, 8.0, 2.024),
    ReferenciaTrelica("TB 30M", "TR 30856", 300, 8.0, 5.0, 6.0, 1.823),
    ReferenciaTrelica("TR 30R", "TR 30858", 300, 8.0, 5.0, 8.0, 2.168),
)


COMPATIBILIDADE_ALTURAS_EPS: tuple[CompatibilidadeAltura, ...] = (
    CompatibilidadeAltura(7.0, 10.0),
    CompatibilidadeAltura(7.0, 11.0),
    CompatibilidadeAltura(7.0, 12.0),
    CompatibilidadeAltura(8.0, 11.0),
    CompatibilidadeAltura(8.0, 12.0),
    CompatibilidadeAltura(8.0, 13.0),
    CompatibilidadeAltura(10.0, 14.0),
    CompatibilidadeAltura(10.0, 15.0),
    CompatibilidadeAltura(12.0, 16.0),
    CompatibilidadeAltura(12.0, 17.0),
    CompatibilidadeAltura(16.0, 20.0),
    CompatibilidadeAltura(16.0, 21.0),
    CompatibilidadeAltura(20.0, 24.0),
    CompatibilidadeAltura(20.0, 25.0),
    CompatibilidadeAltura(24.0, 29.0),
    CompatibilidadeAltura(24.0, 30.0),
    CompatibilidadeAltura(29.0, 34.0),
    CompatibilidadeAltura(29.0, 35.0),
)


def _normalizar_chave_vigota(codigo: str) -> str:
    return re.sub(r"[^A-Z0-9]", "", codigo.upper())


VIGOTA_ALIAS_EXPLICITO: tuple[tuple[str, str], ...] = (
    ("TB 8L", "TR 8644"),
    ("TB 8M", "TR 8645"),
    ("TB 12M", "TR 12645"),
    ("TB 12R", "TR 12646"),
    ("TB 16L", "TR 16745"),
    ("TB 16R", "TR 16746"),
    ("TB 20L", "TR 20745"),
    ("TB 20 L", "TR 20745"),
    ("TB 20R", "TR 20756"),
    ("TB 25M", "TR 25856"),
    ("TB 25R", "TR 25858"),
    ("TB 30M", "TR 30856"),
    ("TB 30R", "TR 30858"),
    ("TR 30R", "TR 30858"),
)


VIGOTA_ALIASES: dict[str, str] = {
    _normalizar_chave_vigota(alias): canonico
    for alias, canonico in VIGOTA_ALIAS_EXPLICITO
}
for codigo in VIGOTAS_REFERENCIA:
    VIGOTA_ALIASES[_normalizar_chave_vigota(codigo)] = codigo


def normalizar_codigo_vigota(codigo: str) -> str:
    codigo_normalizado = VIGOTA_ALIASES.get(_normalizar_chave_vigota(codigo))
    if codigo_normalizado is None:
        raise ValueError(
            f"Vigota '{codigo}' não encontrada. "
            f"Opções canônicas: {list(VIGOTAS_REFERENCIA.keys())}"
        )
    return codigo_normalizado


def aliases_por_codigo() -> dict[str, list[str]]:
    aliases: dict[str, list[str]] = {codigo: [] for codigo in VIGOTAS_REFERENCIA}
    for alias, canonico in VIGOTA_ALIAS_EXPLICITO:
        if canonico in aliases:
            aliases[canonico].append(alias)
    return {
        codigo: sorted(set(lista))
        for codigo, lista in aliases.items()
    }


def get_vigota(codigo: str, *, modo: str = "analitico") -> DadosVigota:
    codigo_canonico = normalizar_codigo_vigota(codigo)
    vigota = VIGOTAS_REFERENCIA[codigo_canonico]
    if modo == "analitico" and not vigota.homologada_analitico:
        raise ValueError(
            f"Vigota '{codigo}' resolve para '{codigo_canonico}', "
            "mas esta seção só está homologada para modo catálogo."
        )
    return vigota
