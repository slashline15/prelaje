# Catálogo de Materiais — Laje Treliçada

> Base de dados de referência para o Modo Catálogo e para o Modo Analítico.
> Fonte: manuais técnicos de fabricantes e tabelas de mercado (Trelifácil / similares).
> **TODO:** Validar com catálogos oficiais dos fabricantes antes de colocar em produção.

---

## 1. Modelos de Vigota Treliçada

### 1.1 Schema do Modelo

Cada vigota é descrita pelos seguintes atributos:

| Campo | Símbolo | Tipo | Unidade | Descrição |
|---|---|---|---|---|
| `codigo` | — | string | — | Designação do fabricante (ex: TR 8644) |
| `h_total` | h | float | cm | Altura total da seção (vigota + capa) |
| `h_vigota` | h_v | float | cm | Altura da vigota pré-moldada |
| `b_nerv` | bw | float | cm | Largura da nervura/alma |
| `intereixo` | s | float | cm | Intereixo padrão do catálogo |
| `As_base` | As | float | cm² | Armadura de tração da vigota |
| `fck_vigota` | fck_v | int | MPa | fck do concreto da vigota (fabricante) |
| `vao_max` | L_max | float | m | Vão máximo tabelado |
| `capa_min` | h_f_min | float | cm | Capa mínima (padrão: 4 cm) |

### 1.2 Tabela de Vigotas (Dados de Referência)

> **ATENÇÃO:** Os valores abaixo são aproximações de mercado. Devem ser substituídos pelos dados oficiais do fabricante escolhido.

```json
[
  {
    "codigo": "TR 8644",
    "h_vigota": 8.0,
    "b_nerv": 12.0,
    "intereixo": 42.0,
    "As_base": 0.95,
    "fck_vigota": 35,
    "vao_max": 6.0,
    "capa_min": 4.0,
    "comentario": "Vigota H8 — uso residencial típico"
  },
  {
    "codigo": "TR 10644",
    "h_vigota": 10.0,
    "b_nerv": 12.0,
    "intereixo": 42.0,
    "As_base": 1.26,
    "fck_vigota": 35,
    "vao_max": 7.5,
    "capa_min": 4.0,
    "comentario": "Vigota H10 — vãos médios"
  },
  {
    "codigo": "TR 12644",
    "h_vigota": 12.0,
    "b_nerv": 12.0,
    "intereixo": 42.0,
    "As_base": 1.58,
    "fck_vigota": 35,
    "vao_max": 9.0,
    "capa_min": 4.0,
    "comentario": "Vigota H12 — vãos maiores"
  },
  {
    "codigo": "TR 8648",
    "h_vigota": 8.0,
    "b_nerv": 12.0,
    "intereixo": 48.0,
    "As_base": 0.95,
    "fck_vigota": 35,
    "vao_max": 5.5,
    "capa_min": 4.0,
    "comentario": "Vigota H8 intereixo 48cm"
  },
  {
    "codigo": "TR 10648",
    "h_vigota": 10.0,
    "b_nerv": 12.0,
    "intereixo": 48.0,
    "As_base": 1.26,
    "fck_vigota": 35,
    "vao_max": 7.0,
    "capa_min": 4.0,
    "comentario": "Vigota H10 intereixo 48cm"
  }
]
```

---

## 2. Peças de Enchimento (EPS / Cerâmica)

### 2.1 Schema do Enchimento

| Campo | Tipo | Unidade | Descrição |
|---|---|---|---|
| `codigo` | string | — | Identificação da peça |
| `material` | enum | — | `EPS` ou `CERAMICA` |
| `largura` | float | cm | Largura da peça |
| `comprimento` | float | cm | Comprimento padrão da peça |
| `altura` | float | cm | Altura (h_e) |
| `peso_especifico` | float | kN/m³ | Para cálculo de carga permanente |
| `intereixo_compativel` | list[float] | cm | Intereixos com que é compatível |

### 2.2 Tabela de Enchimentos (Referência)

```json
[
  {
    "codigo": "EPS-8-42",
    "material": "EPS",
    "largura": 30.0,
    "comprimento": 125.0,
    "altura": 8.0,
    "peso_especifico": 0.15,
    "intereixo_compativel": [42.0]
  },
  {
    "codigo": "EPS-10-42",
    "material": "EPS",
    "largura": 30.0,
    "comprimento": 125.0,
    "altura": 10.0,
    "peso_especifico": 0.15,
    "intereixo_compativel": [42.0]
  },
  {
    "codigo": "EPS-12-42",
    "material": "EPS",
    "largura": 30.0,
    "comprimento": 125.0,
    "altura": 12.0,
    "peso_especifico": 0.15,
    "intereixo_compativel": [42.0]
  },
  {
    "codigo": "EPS-8-48",
    "material": "EPS",
    "largura": 36.0,
    "comprimento": 125.0,
    "altura": 8.0,
    "peso_especifico": 0.15,
    "intereixo_compativel": [48.0]
  },
  {
    "codigo": "CER-8-42",
    "material": "CERAMICA",
    "largura": 30.0,
    "comprimento": 25.0,
    "altura": 8.0,
    "peso_especifico": 6.0,
    "intereixo_compativel": [42.0]
  }
]
```

---

## 3. Telas Soldadas (NBR 7481:2023)

### 3.1 Schema

| Campo | Tipo | Unidade | Descrição |
|---|---|---|---|
| `designacao` | string | — | Ex: Q-92, Q-138 |
| `diametro_long` | float | mm | Diâmetro fio longitudinal |
| `diametro_transv` | float | mm | Diâmetro fio transversal |
| `espacamento_long` | float | mm | Espaçamento longitudinal |
| `espacamento_transv` | float | mm | Espaçamento transversal |
| `As_long` | float | cm²/m | Área de aço longitudinal por metro |
| `peso_unit` | float | kg/m² | Peso por m² da tela |

### 3.2 Tabela de Telas (Referência)

```json
[
  {
    "designacao": "Q-61",
    "diametro_long": 5.0,
    "diametro_transv": 5.0,
    "espacamento_long": 100,
    "espacamento_transv": 200,
    "As_long": 1.96,
    "peso_unit": 3.77
  },
  {
    "designacao": "Q-92",
    "diametro_long": 6.0,
    "diametro_transv": 5.0,
    "espacamento_long": 100,
    "espacamento_transv": 200,
    "As_long": 2.83,
    "peso_unit": 5.17
  },
  {
    "designacao": "Q-138",
    "diametro_long": 7.0,
    "diametro_transv": 6.0,
    "espacamento_long": 150,
    "espacamento_transv": 200,
    "As_long": 3.27,
    "peso_unit": 6.05
  },
  {
    "designacao": "Q-196",
    "diametro_long": 8.0,
    "diametro_transv": 6.0,
    "espacamento_long": 150,
    "espacamento_transv": 200,
    "As_long": 3.77,
    "peso_unit": 7.38
  }
]
```

---

## 4. Matriz de Pré-Dimensionamento (Modo Catálogo)

Estrutura da tabela: `vigota_codigo × vao(m)` → `{carga_max_kgf_m2, armadura_reforco}`

> Lógica de busca: dado `(vão, carga_total)`, encontrar a primeira célula com `vão_tabela ≥ vão_solicitado` e `carga_max ≥ carga_total`. Sempre usar o vão imediatamente superior.

### 4.1 Exemplo — TR 8644 (intereixo 42cm, fck=20MPa, capa 4cm)

| Vão (m) | ≤150 kgf/m² | ≤250 kgf/m² | ≤350 kgf/m² | ≤450 kgf/m² | ≤550 kgf/m² |
|---|---|---|---|---|---|
| 3,00 | sem reforço | Ø4.2 (1) | Ø4.2 (2) | Ø5.0 (1) | Ø6.3 (1) |
| 3,50 | Ø4.2 (1) | Ø4.2 (2) | Ø5.0 (1) | Ø6.3 (1) | Ø6.3 (2) |
| 4,00 | Ø4.2 (2) | Ø5.0 (1) | Ø6.3 (1) | Ø6.3 (2) | — |
| 4,50 | Ø5.0 (1) | Ø6.3 (1) | Ø6.3 (2) | — | — |
| 5,00 | Ø5.0 (2) | Ø6.3 (2) | — | — | — |
| 5,50 | Ø6.3 (1) | — | — | — | — |
| 6,00 | Ø6.3 (2) | — | — | — | — |

> **"—"** indica fora da capacidade do modelo → motor deve sugerir vigota de seção maior.

### 4.2 Formato JSON para a Matriz no Banco

```json
{
  "vigota": "TR 8644",
  "fck_capa": 20,
  "intereixo": 42,
  "capa": 4.0,
  "tabela": [
    {
      "vao": 3.0,
      "cargas": [
        {"carga_max": 150, "reforco": null, "escoramento_max": 1.5},
        {"carga_max": 250, "reforco": {"diametro": 4.2, "quantidade": 1}, "escoramento_max": 1.5},
        {"carga_max": 350, "reforco": {"diametro": 4.2, "quantidade": 2}, "escoramento_max": 1.5},
        {"carga_max": 450, "reforco": {"diametro": 5.0, "quantidade": 1}, "escoramento_max": 1.5},
        {"carga_max": 550, "reforco": {"diametro": 6.3, "quantidade": 1}, "escoramento_max": 1.5}
      ]
    },
    {
      "vao": 3.5,
      "cargas": [
        {"carga_max": 150, "reforco": {"diametro": 4.2, "quantidade": 1}, "escoramento_max": 1.2},
        {"carga_max": 250, "reforco": {"diametro": 4.2, "quantidade": 2}, "escoramento_max": 1.2},
        {"carga_max": 350, "reforco": {"diametro": 5.0, "quantidade": 1}, "escoramento_max": 1.2},
        {"carga_max": 450, "reforco": {"diametro": 6.3, "quantidade": 1}, "escoramento_max": 1.2},
        {"carga_max": 550, "reforco": {"diametro": 6.3, "quantidade": 2}, "escoramento_max": 1.2}
      ]
    }
  ]
}
```

---

## 5. Coeficientes de Carga Permanente por Pacote de Revestimento

Presets configuráveis para o usuário selecionar no formulário:

```json
[
  {
    "id": "liso",
    "descricao": "Piso liso (cerâmica fina)",
    "g_rev": 0.5,
    "unidade": "kN/m²"
  },
  {
    "id": "contrapiso_ceramica",
    "descricao": "Contrapiso + cerâmica",
    "g_rev": 1.2,
    "unidade": "kN/m²"
  },
  {
    "id": "contrapiso_porcelanato",
    "descricao": "Contrapiso + porcelanato",
    "g_rev": 1.4,
    "unidade": "kN/m²"
  },
  {
    "id": "sem_revestimento",
    "descricao": "Sem revestimento (estrutural)",
    "g_rev": 0.0,
    "unidade": "kN/m²"
  }
]
```

---

## 6. TODO — Dados a Validar com Fabricantes

- [ ] Confirmar geometria exata (b_nerv, As_base) dos modelos TR 8644, TR 10644, TR 12644 com fabricante
- [ ] Obter tabelas completas de pré-dimensionamento (Modo Catálogo) de fabricante homologado
- [ ] Confirmar limites de escoramento (distância máxima entre escoras) por modelo de vigota
- [ ] Verificar disponibilidade regional dos modelos de vigota e peças de enchimento
- [ ] Validar pesos das telas soldadas com distribuidor (Q-61, Q-92, Q-138, Q-196)
- [ ] Definir quais modelos serão suportados no MVP (recomendado: 3 a 4 vigotas mais comuns)
