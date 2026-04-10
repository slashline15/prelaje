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
            intereixo_m=0.42,
            b_nerv_m=vigota.b_nerv / 100.0,
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
            intereixo_m=0.42,
            b_nerv_m=vigota.b_nerv / 100.0,
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
        assert resultado.aprovado is True
        assert resultado.status == "approved_with_warnings"
        # TODO: validar valores específicos após cálculo manual
        # assert resultado.elu.as_calculado == pytest.approx(X.XX, abs=0.1)

    def test_quantitativos(self):
        resultado = calcular(self.DADOS)
        assert resultado.quantitativos.n_vigotas == pytest.approx(10, abs=1)  # 4.0 / 0.42
        assert resultado.quantitativos.n_enchimento == 36
        assert resultado.orcamento is not None
        assert resultado.orcamento.resumo.total_geral > 0
        assert resultado.orcamento.resumo.subtotal_direto > 0
        assert any(item.codigo == "TR 8644" for item in resultado.orcamento.itens)
        assert any(item.codigo == "CONC20" for item in resultado.orcamento.itens)
        assert "bdi_simples" in resultado.orcamento.indiretos


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
                h_capa=0.02,   # < 2.5cm → deve falhar
                largura_total=4.0,
                fck=20.0,
                classe_aco=ClasseAco.CA50,
                codigo_vigota="TR 8644",
                uso=UsoLaje.RESIDENCIAL_DORMITORIO,
                g_revestimento=0.0,
            )

    def test_capa_minima_25cm_aceita(self):
        dados = DadosLaje(
            vao=4.0,
            intereixo=0.42,
            h_enchimento=0.08,
            h_capa=0.025,
            largura_total=4.0,
            fck=20.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TR 8644",
            uso=UsoLaje.RESIDENCIAL_DORMITORIO,
            g_revestimento=0.0,
        )

        assert dados.h_capa == pytest.approx(0.025)


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
        assert resultado.erros[0].code == "L_MAX_CATALOGO"
        assert resultado.quantitativos.n_vigotas == 0
        assert resultado.orcamento is None


class TestCaso05_IntereixoIncompativel:
    def test_intereixo_diferente_do_catalogo_bloqueia(self):
        dados = DadosLaje(
            vao=4.0,
            intereixo=0.48,
            h_enchimento=0.08,
            h_capa=0.04,
            largura_total=4.0,
            fck=20.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TR 8644",
            uso=UsoLaje.RESIDENCIAL_DORMITORIO,
            g_revestimento=0.0,
            modo=ModoCalculo.ANALITICO,
        )
        resultado = calcular(dados)
        assert not resultado.aprovado
        assert resultado.status == "rejected"
        assert resultado.erros[0].code == "INTEREIXO_INCOMPATIVEL"


class TestCaso06_ModoCatalogo:
    def test_modo_catalogo_deve_retornar_solucao(self):
        dados = DadosLaje(
            vao=3.5,
            intereixo=0.42,
            h_enchimento=0.08,
            h_capa=0.04,
            largura_total=4.0,
            fck=20.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TR 8644",
            uso=UsoLaje.FORRO,
            g_revestimento=0.0,
            modo=ModoCalculo.CATALOGO,
        )
        resultado = calcular(dados)
        assert resultado.aprovado
        assert resultado.status == "approved_with_warnings"
        assert resultado.catalogo is not None
        assert resultado.catalogo.vao_tabelado == 3.5
        # Sobrecarga = (g_rev + q_k) * 101.97 = (0 + 0.5) * 101.97 ≈ 51.0
        assert resultado.catalogo.carga_total_kgf_m2 == pytest.approx(51.0, abs=0.5)
        assert resultado.catalogo.reforco is not None
        assert resultado.catalogo.reforco.diametro_mm == 4.2
        assert resultado.catalogo.reforco.quantidade == 1
        assert resultado.alertas[0].code == "CATALOGO_REFERENCIA"


class TestCaso07_CargaForaCatalogo:
    def test_carga_acima_da_faixa_rejeita(self):
        dados = DadosLaje(
            vao=4.0,
            intereixo=0.42,
            h_enchimento=0.08,
            h_capa=0.04,
            largura_total=4.0,
            fck=20.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TR 8644",
            uso=UsoLaje.COMERCIAL_LOJA,
            g_revestimento=4.0,
            modo=ModoCalculo.CATALOGO,
        )
        resultado = calcular(dados)
        assert not resultado.aprovado
        assert resultado.status == "rejected"
        assert resultado.erros[0].code == "CARGA_FORA_CATALOGO"


class TestCaso08_CatalogoIndisponivel:
    def test_vigota_sem_matriz_homologada_rejeita(self):
        # fck=30 não existe no catálogo para TR 10644
        dados = DadosLaje(
            vao=4.0,
            intereixo=0.42,
            h_enchimento=0.10,
            h_capa=0.04,
            largura_total=4.0,
            fck=30.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TR 10644",
            uso=UsoLaje.RESIDENCIAL_DORMITORIO,
            g_revestimento=0.5,
            modo=ModoCalculo.CATALOGO,
        )
        resultado = calcular(dados)
        assert not resultado.aprovado
        assert resultado.status == "rejected"
        assert resultado.erros[0].code == "CATALOGO_FCK_INDISPONIVEL"


class TestCaso09_CatalogoSemFckHomologado:
    def test_catalogo_deve_respeitar_fck_da_matriz(self):
        dados = DadosLaje(
            vao=4.0,
            intereixo=0.42,
            h_enchimento=0.08,
            h_capa=0.04,
            largura_total=4.0,
            fck=25.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TR 8644",
            uso=UsoLaje.RESIDENCIAL_DORMITORIO,
            g_revestimento=0.0,
            modo=ModoCalculo.CATALOGO,
        )
        resultado = calcular(dados)
        assert resultado.aprovado
        assert resultado.catalogo is not None
        assert resultado.catalogo.vao_tabelado == 4.0
        # Sobrecarga = (g_rev + q_k) * 101.97 = (0 + 1.5) * 101.97 ≈ 153.0
        assert resultado.catalogo.carga_total_kgf_m2 == pytest.approx(153.0, abs=0.5)
        assert resultado.catalogo.reforco is not None
        assert resultado.catalogo.reforco.diametro_mm == 4.2
        assert resultado.catalogo.reforco.quantidade == 1


class TestCaso10_CatalogoAceitaCodigoComercial:
    def test_catalogo_deve_aceitar_codigo_tp_8_42(self):
        dados = DadosLaje(
            vao=3.5,
            intereixo=0.42,
            h_enchimento=0.08,
            h_capa=0.04,
            largura_total=4.0,
            fck=20.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TP-8-42",
            uso=UsoLaje.FORRO,
            g_revestimento=0.0,
            modo=ModoCalculo.CATALOGO,
        )
        resultado = calcular(dados)
        assert resultado.aprovado
        assert resultado.codigo_vigota == "TP-8-42"
        assert resultado.catalogo is not None
        assert resultado.catalogo.vao_tabelado == 3.5
        assert resultado.catalogo.reforco is not None
        assert resultado.catalogo.reforco.diametro_mm == 4.2
        assert resultado.catalogo.reforco.quantidade == 1


class TestCaso11_AliasResolveParaCodigoCanonico:
    def test_catalogo_deve_aceitar_alias_tb_8l(self):
        dados = DadosLaje(
            vao=3.5,
            intereixo=0.42,
            h_enchimento=0.08,
            h_capa=0.04,
            largura_total=4.0,
            fck=20.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TB 8L",
            uso=UsoLaje.FORRO,
            g_revestimento=0.0,
            modo=ModoCalculo.CATALOGO,
        )
        resultado = calcular(dados)
        assert resultado.aprovado
        assert resultado.codigo_vigota == "TR 8644"
        assert resultado.catalogo is not None
        assert resultado.catalogo.vao_tabelado == 3.5

    def test_catalogo_deve_aceitar_alias_tr644(self):
        dados = DadosLaje(
            vao=3.5,
            intereixo=0.42,
            h_enchimento=0.08,
            h_capa=0.04,
            largura_total=4.0,
            fck=20.0,
            classe_aco=ClasseAco.CA50,
            codigo_vigota="TR644",
            uso=UsoLaje.FORRO,
            g_revestimento=0.0,
            modo=ModoCalculo.CATALOGO,
        )
        resultado = calcular(dados)
        assert resultado.aprovado
        assert resultado.codigo_vigota == "TR 8644"
        assert resultado.catalogo is not None


class TestCaso12_CodigoSomenteCatalogoNaoPodeEntrarNoAnalitico:
    def test_analitico_deve_bloquear_codigo_sem_secao_homologada(self):
        with pytest.raises(ValueError, match="modo catálogo"):
            calcular(
                DadosLaje(
                    vao=3.5,
                    intereixo=0.42,
                    h_enchimento=0.08,
                    h_capa=0.04,
                    largura_total=4.0,
                    fck=20.0,
                    classe_aco=ClasseAco.CA50,
                    codigo_vigota="TP-8-42",
                    uso=UsoLaje.FORRO,
                    g_revestimento=0.0,
                    modo=ModoCalculo.ANALITICO,
                )
            )


# ---------------------------------------------------------------------------
# Casos 10–12: TODO — elaborar com cálculo manual conforme Diretrizes §2
# ---------------------------------------------------------------------------
