from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_orcamento_basico_retorna_campos_obrigatorios():
    payload = {
        "vao": 4.0,
        "intereixo": 0.42,
        "h_enchimento": 0.08,
        "h_capa": 0.04,
        "largura_total": 4.0,
        "fck": 20.0,
        "classe_aco": "CA-50",
        "codigo_vigota": "TR 8644",
        "uso": "residencial_dormitorio",
        "g_revestimento": 0.5,
        "modo": "analitico",
    }

    response = client.post("/api/v1/dimensionar", json=payload)

    assert response.status_code == 200
    data = response.json()
    assert data["orcamento"] is not None
    assert data["orcamento"]["regiao"] == "AM"
    assert data["orcamento"]["resumo"]["total_geral"] > 0
    assert data["orcamento"]["resumo_comercial"] is not None
    assert len(data["orcamento"]["resumo_comercial"]["top_insumos"]) == 5
