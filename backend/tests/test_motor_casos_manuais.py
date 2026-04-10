"""
Casos de teste manuais — Matriz de Verdade.
Cada teste deve ser validado com cálculo manual antes de considerar aprovado.

Rastreável a: docs/dominio/01_matriz_dominio_tecnico.md
TODO: Completar os 10 casos manuais conforme Diretrizes de Implementação §2
"""

import pytest
from app.schemas import DadosLaje, UsoLaje, ClasseAco, TipoApoio, ModoCalculo
from app.engine.motor import calcular
from app.engine.cargas import calcular_cargas
from app.engine.materiais import get_vigota
from app.engine.analise_estrutural import esforcos_biapoiada


# ---------------------------------------------------------------------------
# Caso 1 — Viga biapoiada simples, residencial, TR 8644, L=4m
# Referência manual: calcular à mão e preencher os valores esperados
# ---------------------------------------------------------------------------

class TestCaso01_Biapoiada_Residencial_L4:
    """TR 8644, L=4m, residencial (qk=1.5 kN/m²), fck=20MPa, CA-50."""

    DADOS = DadosLaje(
        vao=4.0,
        intereixo=0.42,
        h_enchimento=0.08,
        h_capa=0.04,
        largura_total=4.0,
        fck=20.0,
        classe_aco=ClasseAco.CA50,
        codigo_vigota="TR 8644",
        uso=UsoLaje.RESIDENCIAL_DORMITORIO,
        g_revestimento=0.5,
        tipo_apoio=TipoApoio.BIAPOIADA,
        modo=ModoCalculo.ANALITICO,
    )

    def test_cargas(self):
        vigota = get_vigota("TR 8644")
        cargas = calcular_cargas(
            uso="residencial_dormitorio",
            vigota=vigota,
            h_capa_m=0.04,
            h_enc_m=0.08,
            g_revestimento=0.5,
        )
        # g_capa = 25 × 0.04 = 1.0 kN/m²
        assert cargas.g_pp == pytest.approx(1.0 + 0.15 * 0.08 * (1 - 0.12/0.42), abs=0.01)
        # q_k residencial dormitório = 1.5 kN/m²
        assert cargas.q_k == 1.5

    def test_esforcos_biapoiada(self):
        vigota = get_vigota("TR 8644")
        cargas = calcular_cargas(
            uso="residencial_dormitorio",
            vigota=vigota,
            h_capa_m=0.04,
            h_enc_m=0.08,
            g_revestimento=0.5,
        )
        esf = esforcos_biapoiada(cargas.w_sd, 4.0)
        # Msd = w_sd × L² / 8 — verificar manualmente
        assert esf.msd_max == pytest.approx(cargas.w_sd * 4.0**2 / 8, abs=0.001)
        assert esf.vsd_max == pytest.approx(cargas.w_sd * 4.0 / 2, abs=0.001)

    def test_resultado_aprovado(self):
        resultado = calcular(self.DADOS)
        assert len(resultado.erros) == 0, f"Erros inesperados: {resultado.erros}"
        # TODO: validar valores específicos após cálculo manual
        # assert resultado.elu.as_calculado == pytest.approx(X.XX, abs=0.1)

    def test_quantitativos(self):
        resultado = calcular(self.DADOS)
        assert resultado.quantitativos.n_vigotas == pytest.approx(10, abs=1)  # 4.0 / 0.42


# ---------------------------------------------------------------------------
# Caso 2 — Vão maior, TR 10644, L=6m
# TODO: preencher após cálculo manual
# ---------------------------------------------------------------------------

class TestCaso02_L6_TR10644:
    """TR 10644, L=6m, residencial social (qk=2.0 kN/m²)."""

    DADOS = DadosLaje(
        vao=6.0,
        intereixo=0.42,
        h_enchimento=0.10,
        h_capa=0.05,
        largura_total=5.0,
        fck=20.0,
        classe_aco=ClasseAco.CA50,
        codigo_vigota="TR 10644",
        uso=UsoLaje.RESIDENCIAL_SOCIAL,
        g_revestimento=1.2,
        tipo_apoio=TipoApoio.BIAPOIADA,
        modo=ModoCalculo.ANALITICO,
    )

    def test_sem_erros(self):
        resultado = calcular(self.DADOS)
        assert len(resultado.erros) == 0, f"Erros: {resultado.erros}"


# ---------------------------------------------------------------------------
# Caso 3 — Trava: h_capa < 4cm deve ser rejeitado pela validação Pydantic
# ---------------------------------------------------------------------------

class TestCaso03_TravaCapa:
    def test_capa_invalida(self):
        with pytest.raises(Exception):  # ValidationError do Pydantic
            DadosLaje(
                vao=4.0,
                intereixo=0.42,
                h_enchimento=0.08,
                h_capa=0.03,   # < 4cm → deve falhar
                largura_total=4.0,
                fck=20.0,
                classe_aco=ClasseAco.CA50,
                codigo_vigota="TR 8644",
                uso=UsoLaje.RESIDENCIAL_DORMITORIO,
                g_revestimento=0.0,
            )


# ---------------------------------------------------------------------------
# Caso 4 — Trava: vão excede capacidade da vigota
# ---------------------------------------------------------------------------

class TestCaso04_TravaVaoMaximo:
    def test_vao_excede_vigota(self):
        dados = DadosLaje(
            vao=7.0,   # TR 8644 suporta até 6.0m
            intereixo=0.42,
            h_enchimento=0.08,
            h_capa=0.04,
            largura_total=4.0,
            fck=20.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TR 8644",
            uso=UsoLaje.RESIDENCIAL_DORMITORIO,
            g_revestimento=0.0,
        )
        resultado = calcular(dados)
        assert not resultado.aprovado
        assert len(resultado.erros) > 0


# ---------------------------------------------------------------------------
# Casos 5–10: TODO — elaborar com cálculo manual conforme Diretrizes §2
# ---------------------------------------------------------------------------
