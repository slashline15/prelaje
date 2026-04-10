"""
Modelos SQLAlchemy — esquema PostgreSQL.
Rastreável a: docs/dominio/02_catalogo_materiais.md §1 e §2
TODO: integrar com Alembic para migrações
"""

from datetime import datetime
from sqlalchemy import (
    Column, Integer, Float, String, Boolean,
    ForeignKey, DateTime, JSON, Enum as SAEnum,
)
from sqlalchemy.orm import DeclarativeBase, relationship


class Base(DeclarativeBase):
    pass


class Vigota(Base):
    """Catálogo de modelos de vigota treliçada."""
    __tablename__ = "vigotas"

    id           = Column(Integer, primary_key=True)
    codigo       = Column(String(20), unique=True, nullable=False, index=True)
    h_vigota_cm  = Column(Float, nullable=False)
    b_nerv_cm    = Column(Float, nullable=False)
    intereixo_cm = Column(Float, nullable=False)
    as_base_cm2  = Column(Float, nullable=False)
    fck_vigota   = Column(Float, nullable=False, default=35.0)
    vao_max_m    = Column(Float, nullable=False)
    capa_min_cm  = Column(Float, nullable=False, default=4.0)
    ativo        = Column(Boolean, default=True)

    tabela_catalogo = relationship("TabelaCatalogo", back_populates="vigota")


class TabelaCatalogo(Base):
    """
    Matriz de pré-dimensionamento (Modo Catálogo).
    Cada linha = (vigota, vão, carga_max) → armadura de reforço.
    """
    __tablename__ = "tabela_catalogo"

    id              = Column(Integer, primary_key=True)
    vigota_id       = Column(Integer, ForeignKey("vigotas.id"), nullable=False)
    fck_capa        = Column(Float, nullable=False, default=20.0)
    intereixo_cm    = Column(Float, nullable=False)
    capa_cm         = Column(Float, nullable=False, default=4.0)
    vao_m           = Column(Float, nullable=False)
    carga_max_kgf   = Column(Float, nullable=False)  # kgf/m²
    reforco_diam_mm = Column(Float, nullable=True)   # None = sem reforço
    reforco_qtd     = Column(Integer, nullable=True)
    escoramento_max = Column(Float, nullable=True)   # m

    vigota = relationship("Vigota", back_populates="tabela_catalogo")


class ResultadoCalculo(Base):
    """Histórico de cálculos realizados (opcional no MVP sem auth)."""
    __tablename__ = "resultados_calculo"

    id             = Column(Integer, primary_key=True)
    criado_em      = Column(DateTime, default=datetime.utcnow)
    modo           = Column(String(20), nullable=False)
    codigo_vigota  = Column(String(20), nullable=False)
    dados_entrada  = Column(JSON, nullable=False)   # DadosLaje serializado
    resultado      = Column(JSON, nullable=False)   # ResultadoDimensionamento serializado
    aprovado       = Column(Boolean, nullable=False)
