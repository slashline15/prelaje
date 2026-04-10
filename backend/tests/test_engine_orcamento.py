from app.engine.motor import calcular
import pytest

from app.schemas import ClasseAco, DadosLaje, ModoCalculo, TipoApoio, UsoLaje


def _dados_base(**overrides) -> DadosLaje:
    payload = {
        "vao": 4.0,
        "intereixo": 0.42,
        "h_enchimento": 0.08,
        "h_capa": 0.04,
        "largura_total": 4.0,
        "fck": 20.0,
        "classe_aco": ClasseAco.CA50,
        "codigo_vigota": "TR 8644",
        "uso": UsoLaje.RESIDENCIAL_DORMITORIO,
        "g_revestimento": 0.5,
        "modo": ModoCalculo.ANALITICO,
    }
    payload.update(overrides)
    return DadosLaje(**payload)


def test_orcamento_sem_regiao_usa_default_am():
    resultado = calcular(_dados_base())

    assert resultado.orcamento is not None
    assert resultado.orcamento.regiao == "AM"


def test_orcamento_regiao_sem_preco_emite_alerta():
    resultado = calcular(_dados_base(regiao="RJ"))

    assert resultado.orcamento is not None
    assert resultado.orcamento.regiao == "AM"
    assert any("Regiao RJ sem cobertura comercial completa" in alerta for alerta in resultado.orcamento.alertas)


def test_orcamento_eps_desconhecido_emite_alerta():
    resultado = calcular(_dados_base(h_enchimento=0.20))

    assert resultado.orcamento is not None
    assert any("eps:eps-20-42" in alerta.lower() for alerta in resultado.orcamento.alertas)


def test_regras_comerciais_arredondam_para_multiplo():
    resultado = calcular(_dados_base())

    assert resultado.orcamento is not None
    tela = resultado.orcamento.materiais["Q-92"]
    assert tela.quantidade_compra >= tela.quantidade
    assert tela.quantidade_compra % 50 == 0


def test_orcamento_tela_sobe_em_caso_mais_exigente():
    resultado_leve = calcular(_dados_base())
    resultado_pesado = calcular(_dados_base(uso=UsoLaje.COMERCIAL_LOJA))

    assert resultado_leve.orcamento is not None
    assert resultado_pesado.orcamento is not None
    assert "Q-92" in resultado_leve.orcamento.materiais
    assert any(
        codigo in resultado_pesado.orcamento.materiais
        for codigo in ("Q-131", "Q-165")
    )


def test_orcamento_concreto_fck_intermediario_sobe_para_faixa_superior():
    resultado = calcular(_dados_base(fck=22.0))

    assert resultado.orcamento is not None
    assert "CONC25" in resultado.orcamento.materiais
    assert any("CONC25" in alerta for alerta in resultado.orcamento.alertas)


def test_orcamento_regiao_parcial_faz_fallback_para_base_completa():
    resultado = calcular(_dados_base(regiao="SP"))

    assert resultado.orcamento is not None
    assert resultado.orcamento.regiao == "AM"
    assert any("Regiao SP sem cobertura comercial completa" in alerta for alerta in resultado.orcamento.alertas)


def test_orcamento_inclui_arame_e_espacadores():
    resultado = calcular(_dados_base())

    assert resultado.orcamento is not None
    assert "ARAME-1.6" in resultado.orcamento.materiais
    assert "ESP-PLASTICO" in resultado.orcamento.materiais
    assert resultado.orcamento.materiais["ARAME-1.6"].quantidade > 0
    assert resultado.orcamento.materiais["ESP-PLASTICO"].quantidade > 0


def test_preenchimento_mao_de_obra_usa_area_liquida_entre_nervuras():
    resultado = calcular(_dados_base())

    assert resultado.orcamento is not None
    preenchimento = resultado.orcamento.mao_obra["preenchimento_enchimento_m2"]
    assert preenchimento.quantidade < resultado.orcamento.resumo.area_laje_m2


def test_orcamento_reforco_biapoiada_vs_continua():
    base = _dados_base(
        uso=UsoLaje.COMERCIAL_LOJA,
        tipo_apoio=TipoApoio.BIAPOIADA,
    )
    resultado_bi = calcular(base)
    resultado_cont = calcular(_dados_base(
        uso=UsoLaje.COMERCIAL_LOJA,
        tipo_apoio=TipoApoio.CONTINUA_2,
    ))

    assert resultado_bi.orcamento is not None
    assert resultado_cont.orcamento is not None
    peso_bi = resultado_bi.orcamento.materiais["CA50-8.0"].quantidade
    peso_cont = resultado_cont.orcamento.materiais["CA50-8.0"].quantidade
    assert peso_cont < peso_bi


def test_orcamento_resumo_comercial_top5():
    resultado = calcular(_dados_base())

    assert resultado.orcamento is not None
    rc = resultado.orcamento.resumo_comercial
    assert rc is not None
    assert len(rc.top_insumos) == 5
    assert rc.total_geral == resultado.orcamento.resumo.total_geral
    assert rc.custo_unitario_m2 == pytest.approx(
        rc.total_geral / rc.area_laje_m2,
        abs=0.01,
    )
    assert "referencia" in rc.aviso_comercial.lower()


def test_orcamento_resumo_comercial_ordenado():
    resultado = calcular(_dados_base())

    assert resultado.orcamento is not None
    rc = resultado.orcamento.resumo_comercial
    assert rc is not None
    valores = [item.valor for item in rc.top_insumos]
    assert valores == sorted(valores, reverse=True)
