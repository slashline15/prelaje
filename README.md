# PréLaje — Dimensionamento de Lajes Treliçadas

<div align="center">

[![Python](https://img.shields.io/badge/Python-3.11+-blue?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-00a?logo=fastapi)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-025?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**Ferramenta SaaS de dimensionamento de lajes pré-moldadas treliçadas unidirecionais em concreto armado.**

_mercado brasileiro • normas NBR 6118:2026 • MVP em desenvolvimento_

</div>

---

## O Projeto

O PréLaje é uma ferramenta de dimensionamento estrutural para lajes treliçadas com enchimento em EPS (poliestireno expandido), desenvolvida para o mercado brasileiro de engenharia civil.

### Diferenciais

- **Dual Engine**: modo catálogo (rápido) + modo analítico (completo)
- **Motor isolado**: cálculo independente de interface e banco de dados
- **Normativo**: compliance com NBR 6118:2026, NBR 6120:2019, NBR 7481:2023
- **Orçamento integrado**: composição de custos com BDI, perdas e arredondamentos

---

## Stack Tecnológica

| Componente | Tecnologia |
|------------|------------|
| Backend | Python 3.11+ • FastAPI |
| Frontend | Flutter (mobile/web) |
| Banco de Dados | PostgreSQL |
| Método Estrutural | Método da Rigidez Direta |

---

## Status do MVP

### ✅ Concluído

- [x] Schema de entrada (`DadosLaje`) e saída (`ResultadoDimensionamento`)
- [x] Motor de cálculo analítico (flexão, cisalhamento, flecha via Branson)
- [x] Motor de cálculo por catálogo
- [x] Pipeline de cargas (NBR 6120)
- [x] Verificações ELU/ELS
- [x] Quantitativos (vigotas, EPS, capa, tela)
- [x] Módulo de orçamento preliminar
- [x] Tabelas de custos (materiais, mão de obra, indiretos)
- [x] Regras comerciais (perdas, múltiplos de compra)
- [x] API REST FastAPI
- [x] Geração de relatório PDF
- [x] Endpoints de referências (vigotas, treliças, EPS, cargas de uso)

### 🔄 Em Andamento

- [ ] Endpoint `/api/v1/referencias/custos` para expor tabelas de custo ao frontend

### ⏳ Pendente (MVP)

| # | Item | Módulo | Prioridade |
|---|------|--------|------------|
| 1 | Correção heurística `preenchimento_enchimento_m2` | orcamento.py | 🔴 Alta |
| 2 | Inclusão de arame e espaçadores no orçamento | orcamento.py | 🔴 Alta |
| 3 | Ajuste de cálculo de aço de reforço (modo analítico) | orcamento.py | 🟡 Média |
| 4 | Lógica dinâmica de escolha de tela (Q-92/Q-131/Q-165) | orcamento.py | 🟢 Baixa |
| 5 | Normalização CSVs: preset_revestimentos.csv | db/ | 🔴 Alta |
| 6 | Normalização CSVs: classes_uso.csv | db/ | 🔴 Alta |
| 7 | Alinhamento taxonomia vigota (matriz_catalogo ↔ custos_materiais) | db/ | 🔴 Alta |
| 8 | Remoção de referências a enchimento cerâmico | db/ | 🔴 Alta |
| 9 | Casos de teste manuais (10 cálculos validados) | tests/ | 🟡 Média |
| 10 | Diagrama ER (Usuarios, Projetos, Materiais_Catalogo, Resultados_Calculo) | db/ | 🟡 Média |
| 11 | Wireframes de navegação | frontend/ | 🟡 Média |
| 12 | Integração PostgreSQL | backend/ | 🔴 Alta |
| 13 | Autenticação e autorização | backend/ | 🟡 Média |
| 14 | Frontend Flutter (MVP) | frontend/ | 🟡 Média |

---

## Arquitetura

```
prelaje-linux/
├── backend/
│   ├── app/
│   │   ├── api/routes.py        # Endpoints REST
│   │   ├── engine/
│   │   │   ├── motor.py        # Orquestrador de cálculo
│   │   │   ├── analise_estrutural.py
│   │   │   ├── cargas.py
│   │   │   ├── catalogo.py
│   │   │   ├── materiais.py
│   │   │   ├── verificacoes.py
│   │   │   └── orcamento.py    # Composição de custos
│   │   ├── schemas.py          # Contratos JSON
│   │   └── main.py
│   ├── db/
│   │   ├── custos_materiais.csv
│   │   ├── custos_mao_obra.csv
│   │   ├── custos_indiretos.csv
│   │   └── regras_comerciais.csv
│   └── tests/
├── frontend/                    # Flutter (a iniciar)
├── docs/
│   └── dominio/
│       ├── 01_matriz_dominio_tecnico.md
│       └── 02_catalogo_materiais.md
└── CLAUDE.md                   # Contexto para IA
```

### Princípio Fundamental

> O **motor de cálculo** deve ser **completamente isolado** da interface e do banco de dados. Troca de frontend (Flutter → Web) não deve exigir alteração no motor.

---

## Uso da API

### Dimensionamento

```bash
curl -X POST "http://localhost:8000/api/v1/dimensionar" \
  -H "Content-Type: application/json" \
  -d '{
    "vao": 4.0,
    "intereixo": 0.42,
    "h_enchimento": 0.08,
    "h_capa": 0.04,
    "largura_total": 4.0,
    "fck": 20.0,
    "classe_aco": "CA-50",
    "codigo_vigota": "TR 8644",
    "uso": "residencial_dormitorios_salas_cozinha",
    "g_revestimento": 0.5,
    "modo": "analitico"
  }'
```

### Listar Vigotas

```bash
curl "http://localhost:8000/api/v1/vigotas"
```

### Referências de Custos

```bash
curl "http://localhost:8000/api/v1/referencias/custos?regiao=AM"
```

---

## Executando o Backend

```bash
cd backend

# Criar ambiente virtual
python -m venv venv
source venv/bin/activate  # Linux/macOS
# venv\Scripts\activate   # Windows

# Instalar dependências
pip install -r requirements.txt

# Executar servidor
uvicorn app.main:app --reload
```

O servidor estará disponível em `http://localhost:8000`.

Documentação interativa: `http://localhost:8000/docs`

---

## Executando os Testes

```bash
cd backend
pytest tests/ -v
```

---

## Normas Técnicas

O sistema implementa as seguintes normas brasileiras:

| Norma | Assunto |
|-------|---------|
| NBR 6118:2026 | Projeto de estruturas de concreto |
| NBR 6120:2019 | Cargas para cálculo de estruturas |
| NBR 7481:2023 | Telas soldadas para armadura de distribuição |

### Coeficientes de Segurança

- γ (concreto): **1.4**
- γ (aço): **1.15**
- γ (carga permanente): **1.4**
- γ (carga variável): **1.4**

---

## Travas de Segurança

O sistema **recusa o cálculo** e emite alerta explícito quando:

- Vão extrapola os limites do modelo/catálogo
- Espessura de capa `h_f < 4 cm` (mínimo NBR 6118)
- Parâmetro fora das hipóteses simplificadoras

---

## Ressalva Jurídica ("Safe Harbor")

Todo relatório gerado contém obrigatoriamente:

1. Aviso de que a ferramenta é para **estudos preliminares**, não substitui projeto estrutural final
2. Obrigatoriedade de **Engenheiro Civil habilitado** e emissão de ART
3. Especificação da versão exata da norma usada
4. Materiais e parâmetros utilizados
5. Aviso de que vigas de apoio, pilares e fundações **não são verificados**
6. Recomendação de consulta ao projeto de escoramento do fabricante

---

## Roadmap

### Fase 1 — Motor de Cálculo (concluída)
- [x] Pipeline analítico
- [x] Pipeline por catálogo
- [x] Verificações ELU/ELS

### Fase 2 — Orçamento (em andamento)
- [x] Composição de custos
- [x] Tabelas de referência
- [ ] Endpoint de custos

### Fase 3 — Dados e Persistência
- [ ] PostgreSQL
- [ ] Casos de teste validados
- [ ] Diagrama ER

### Fase 4 — Frontend
- [ ] Wireframes
- [ ] Flutter MVP

---

## Licença

MIT License — see [LICENSE](LICENSE) for details.

---

## Contato

**PréLaje** — Ferramenta de dimensionamento para lajes treliçadas

_Este projeto é para fins educacionais e de estudo. Sempre consulte um engenheiro civil habilitado para projetos estruturais reais._