from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_referencias_trelicas_expoe_dados_informados():
    response = client.get("/api/v1/referencias/trelicas")

    assert response.status_code == 200
    dados = response.json()
    assert any(item["designacao"] == "TR 8644" for item in dados)
    assert any(item["designacao"] == "TR 30858" for item in dados)


def test_referencias_alturas_eps_expoe_combinacoes():
    response = client.get("/api/v1/referencias/alturas-eps")

    assert response.status_code == 200
    dados = response.json()
    assert {"h_enchimento_cm": 8.0, "h_total_cm": 11.0} in dados
    assert {"h_enchimento_cm": 29.0, "h_total_cm": 35.0} in dados


def test_referencias_cargas_uso_expoe_categorias_detalhadas():
    response = client.get("/api/v1/referencias/cargas-uso")

    assert response.status_code == 200
    dados = response.json()
    assert any(
        item["uso"] == "residencial_dormitorios_salas_cozinha"
        and item["carga_kn_m2"] == 1.5
        and item["psi_2"] == 0.3
        for item in dados
    )
    assert any(
        item["uso"] == "biblioteca_sala_de_estantes"
        and item["carga_kn_m2"] == 6.0
        and item["psi_0"] == 0.7
        for item in dados
    )
    assert any(
        item["uso"] == "forro"
        and item["depreciado"] is True
        and item["alias_de"] == "servico_forros_sem_acesso_pessoas"
        and item["psi_0"] == 0.5
        and item["psi_1"] == 0.4
        and item["psi_2"] == 0.2
        for item in dados
    )
    assert any(
        item["uso"] == "comercial_loja"
        and item["depreciado"] is True
        and item["alias_de"] is None
        and item["carga_kn_m2"] == 4.0
        for item in dados
    )


def test_vigotas_expoe_codigos_canonicos_aliases_e_modos():
    response = client.get("/api/v1/vigotas")

    assert response.status_code == 200
    dados = response.json()

    assert any(
        item["codigo_canonico"] == "TR 8644"
        and "TB 8L" in item["aliases"]
        and "TR644" in item["aliases"]
        and item["disponivel_analitico"] is True
        and item["disponivel_catalogo"] is True
        for item in dados
    )
    assert any(
        item["codigo_canonico"] == "TP-8-42"
        and item["disponivel_analitico"] is False
        and item["disponivel_catalogo"] is True
        for item in dados
    )


def test_referencias_custos_regiao_existente():
    response = client.get("/api/v1/referencias/custos?regiao=AM")

    assert response.status_code == 200
    dados = response.json()

    assert dados["regiao"] == "AM"
    assert dados["data_referencia"] == "2026-04-09"
    assert any(item["codigo"] == "TR 8644" for item in dados["materiais"])
    assert any(item["codigo"] == "EPS-8-42" for item in dados["materiais"])
    assert any(item["codigo"] == "Q-92" for item in dados["materiais"])
    assert any(item["codigo"] == "CONC20" for item in dados["materiais"])
    assert any(item["codigo"] == "montagem_laje_m2" for item in dados["mao_obra"])
    assert any(item["codigo"] == "bdi_simples" for item in dados["indiretos"])
    assert any(item["codigo"] == "TR 8644" for item in dados["regras_comerciais"])


def test_referencias_custos_regiao_indisponivel_fallback():
    response = client.get("/api/v1/referencias/custos?regiao=XX")

    assert response.status_code == 200
    dados = response.json()

    assert dados["materiais"]
    assert len(dados["alertas"]) > 0
    assert "XX" in dados["alertas"][0]


def test_referencias_custos_regiao_parcial_fallback_para_am():
    response = client.get("/api/v1/referencias/custos?regiao=SP")

    assert response.status_code == 200
    dados = response.json()
    assert dados["regiao"] == "AM"
    assert len(dados["alertas"]) > 0
    assert "SP" in dados["alertas"][0]
    assert any(item["codigo"] == "EPS-8-42" for item in dados["materiais"])
