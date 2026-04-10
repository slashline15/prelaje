from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_relatorio_pdf_analitico_retorna_pdf():
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
        "tipo_apoio": "biapoiada",
        "modo": "analitico",
    }
    response = client.post("/api/v1/relatorio-pdf", json=payload)

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert response.content.startswith(b"%PDF")
    assert b"TR 8644" in response.content
    assert b"NBR 6118:2026" in response.content
    assert b"Flecha total" in response.content
    assert b"Orcamento preliminar" in response.content
    assert b"Total geral" in response.content
    assert b"RESUMO COMERCIAL" in response.content
    assert b"Top 5 Insumos" in response.content


def test_relatorio_pdf_catalogo_retorna_resultado_catalogado():
    payload = {
        "vao": 3.5,
        "intereixo": 0.42,
        "h_enchimento": 0.08,
        "h_capa": 0.04,
        "largura_total": 4.0,
        "fck": 20.0,
        "classe_aco": "CA-50",
        "codigo_vigota": "TR 8644",
        "uso": "forro",
        "g_revestimento": 0.0,
        "tipo_apoio": "biapoiada",
        "modo": "catalogo",
    }
    response = client.post("/api/v1/relatorio-pdf", json=payload)

    assert response.status_code == 200
    assert response.content.startswith(b"%PDF")
    assert b"Resultado do modo catalogo" in response.content
    assert b"153.8 kgf/m2" in response.content
    assert b"CATALOGO_REFERENCIA" in response.content
    assert b"Orcamento preliminar" in response.content
    assert b"RESUMO COMERCIAL" in response.content
