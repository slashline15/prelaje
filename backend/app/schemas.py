"""
Contratos de dados (JSON schemas) entre Frontend e Motor de Cálculo.
Rastreável a: docs/dominio/01_matriz_dominio_tecnico.md §3
"""

from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, field_validator


# ---------------------------------------------------------------------------
# Enumerações de domínio
# ---------------------------------------------------------------------------

class UsoLaje(str, Enum):
    RESIDENCIAL_DORMITORIO = "residencial_dormitorio"  # qk = 1,5 kN/m²
    RESIDENCIAL_SOCIAL     = "residencial_social"      # qk = 2,0 kN/m²
    COMERCIAL_ESCRITORIO   = "comercial_escritorio"    # qk = 3,0 kN/m²
    COMERCIAL_LOJA         = "comercial_loja"          # qk = 4,0 kN/m²
    FORRO                  = "forro"                   # qk = 0,5 kN/m²


class ClasseAco(str, Enum):
    CA50 = "CA-50"
    CA60 = "CA-60"


class TipoApoio(str, Enum):
    BIAPOIADA  = "biapoiada"
    CONTINUA_2 = "continua_2_vaos"
    CONTINUA_3 = "continua_3_vaos"


class ModoCalculo(str, Enum):
    CATALOGO  = "catalogo"
    ANALITICO = "analitico"


# ---------------------------------------------------------------------------
# Input: DadosLaje
# ---------------------------------------------------------------------------

class DadosLaje(BaseModel):
    """
    Entrada para o motor de cálculo.
    Todos os valores lineares em metros, áreas em m², forças em kN.
    """
    # Geometria
    vao: float = Field(..., gt=0, le=10.0, description="Vão livre entre apoios (m)")
    intereixo: float = Field(..., gt=0, description="Intereixo entre nervuras (m)")
    h_enchimento: float = Field(..., ge=0, description="Altura do enchimento EPS/cerâmica (m)")
    h_capa: float = Field(..., ge=0.04, description="Espessura da capa de concreto (m) — mínimo 4 cm")
    largura_total: float = Field(..., gt=0, description="Largura total da laje (m)")

    # Materiais
    fck: float = Field(20.0, ge=20.0, le=50.0, description="Resistência do concreto da capa (MPa)")
    classe_aco: ClasseAco = Field(ClasseAco.CA50, description="Classe do aço da armadura")
    codigo_vigota: str = Field(..., description="Código da vigota (ex: TR 8644)")

    # Carregamento
    uso: UsoLaje = Field(..., description="Uso da laje para definição de carga acidental")
    g_revestimento: float = Field(0.0, ge=0, description="Carga permanente de revestimento (kN/m²)")

    # Análise
    tipo_apoio: TipoApoio = Field(TipoApoio.BIAPOIADA, description="Condição de apoio da viga")
    modo: ModoCalculo = Field(ModoCalculo.ANALITICO, description="Modo do motor de cálculo")

    @field_validator("h_capa")
    @classmethod
    def capa_minima(cls, v):
        if v < 0.04:
            raise ValueError("Espessura de capa abaixo do mínimo normativo de 4 cm (NBR 6118)")
        return v

    @field_validator("vao")
    @classmethod
    def vao_maximo(cls, v):
        if v > 10.0:
            raise ValueError("Vão excede 10 m — fora do escopo do MVP. Consulte engenheiro estrutural.")
        return v


# ---------------------------------------------------------------------------
# Output: ResultadoDimensionamento
# ---------------------------------------------------------------------------

class VerificacaoELU(BaseModel):
    msd: float = Field(..., description="Momento solicitante de cálculo (kN·m)")
    vsd: float = Field(..., description="Cortante solicitante de cálculo (kN)")
    as_calculado: float = Field(..., description="Armadura de flexão calculada (cm²)")
    as_minimo: float = Field(..., description="Armadura mínima normativa (cm²)")
    xd: float = Field(..., description="Posição relativa da linha neutra (x/d)")
    aprovado_flexao: bool
    aprovado_cisalhamento: bool
    aprovado_armadura_minima: bool


class VerificacaoELS(BaseModel):
    flecha_imediata: float = Field(..., description="Flecha imediata (cm)")
    flecha_diferida: float = Field(..., description="Flecha diferida (cm)")
    flecha_total: float = Field(..., description="Flecha total (cm)")
    flecha_limite: float = Field(..., description="Limite normativo vão/250 (cm)")
    aprovado: bool


class Quantitativos(BaseModel):
    n_vigotas: int = Field(..., description="Número de vigotas")
    n_enchimento: int = Field(..., description="Número de peças de enchimento")
    volume_capa_m3: float = Field(..., description="Volume de concreto da capa (m³)")
    peso_tela_kg: float = Field(..., description="Peso de tela soldada (kg)")


class ArmaduraReforco(BaseModel):
    diametro_mm: float
    quantidade: int
    as_total_cm2: float


class ResultadoCatalogo(BaseModel):
    vao_tabelado: float
    carga_total_kgf_m2: float
    reforco: Optional[ArmaduraReforco]
    escoramento_max_m: float
    dentro_do_catalogo: bool


class ResultadoDimensionamento(BaseModel):
    """
    Saída completa do motor de cálculo.
    """
    # Identificação
    modo: ModoCalculo
    codigo_vigota: str

    # Cargas calculadas
    g_k: float = Field(..., description="Carga permanente característica (kN/m²)")
    q_k: float = Field(..., description="Carga variável característica (kN/m²)")
    q_sd: float = Field(..., description="Carga total de cálculo ELU (kN/m²)")
    q_ser: float = Field(..., description="Carga de serviço ELS (kN/m²)")

    # Resultados por modo
    elu: Optional[VerificacaoELU] = None
    els: Optional[VerificacaoELS] = None
    catalogo: Optional[ResultadoCatalogo] = None

    # Quantitativos
    quantitativos: Quantitativos

    # Status geral
    aprovado: bool
    alertas: list[str] = Field(default_factory=list)
    erros: list[str] = Field(default_factory=list)

    # Metadados para o disclaimer
    normas_utilizadas: list[str] = Field(
        default=["NBR 6118:2026", "NBR 6120:2019", "NBR 7481:2023"]
    )
    parametros_validade: dict = Field(default_factory=dict)
