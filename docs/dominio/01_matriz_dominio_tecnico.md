       # Matriz de Domínio Técnico — Laje Treliçada Unidirecional

       > Fonte da verdade do motor de cálculo. Toda fórmula implementada no backend deve ser rastreável a uma seção deste documento.

       ---

       ## 1. Hipóteses de Cálculo

       | # | Hipótese | Justificativa normativa |
       |---|---|---|
       | H1 | Laje tratada como conjunto de vigas paralelas na direção das nervuras | NBR 6118:2026 §13.2.4 |
       | H2 | Rigidez transversal e torção desprezadas | NBR 6118:2026 §13.2.4 |
       | H3 | Análise de primeira ordem (linear-elástica) | NBR 6118:2026 §15.4 |
       | H4 | Seção T (nervura + mesa/capa) para flexão positiva | NBR 6118:2026 §14.6 |
       | H5 | Seção retangular (nervura apenas) para flexão negativa | NBR 6118:2026 §14.6 |
       | H6 | Ligação monolítica entre capa e vigota (aderência garantida) | — |

       ---

       ## 2. Parâmetros de Material

       ### 2.1 Concreto

       | Parâmetro | Símbolo | Valor padrão (catálogo) | Unidade | Norma |
       |---|---|---|---|---|
       | Resistência característica à compressão | fck | 20 | MPa | NBR 6118 §8.2.4 |
       | Módulo de elasticidade secante | Ecs | 25.100 (C20) | MPa | NBR 6118 §8.2.8: `Ecs = 5600√fck` |
       | Coef. Poisson | ν | 0,2 | — | NBR 6118 §8.2.9 |
       | Peso específico (armado) | γc | 25 | kN/m³ | NBR 6120:2019 Tab. 1 |
       | Resistência de cálculo à compressão | fcd | fck / γc | MPa | NBR 6118 §12.3.3 |
       | Coef. αc (redução da resistência) | αc | 0,85 | — | NBR 6118 §17.2.2 |

       > `fcd = αc × fck / γc`  onde `γc = 1,4` (NBR 6118 Tab. 1)

       ### 2.2 Aço (Armadura Passiva)

       | Parâmetro | CA-50 | CA-60 | Unidade | Norma |
       |---|---|---|---|---|
       | fyk (resist. característica) | 500 | 600 | MPa | NBR 7480 |
       | fyd (resist. de cálculo) | 434,8 | 521,7 | MPa | `fyd = fyk / γs` (γs = 1,15) |
       | Es (módulo elástico) | 210.000 | 210.000 | MPa | NBR 6118 §8.3.6 |
       | εuk (deformação última) | 50‰ | 35‰ | — | NBR 6118 §8.3.6 |

       ### 2.3 Coeficientes de Ponderação

       | Coeficiente | Símbolo | Valor | Aplicação |
       |---|---|---|---|
       | Coef. ponderação do concreto | γc | 1,4 | ELU |
       | Coef. ponderação do aço | γs | 1,15 | ELU |
       | Coef. ponderação carga permanente | γg | 1,4 | ELU (desfavorável) |
       | Coef. ponderação carga variável | γq | 1,4 | ELU |

       ---

       ## 3. Carregamentos (NBR 6120:2019)

       ### 3.1 Cargas Permanentes (Peso Próprio + Revestimento)

       | Componente | Peso específico | Unidade |
       |---|---|---|
       | Concreto armado (capa) | 25 | kN/m³ |
       | Argamassa de revestimento | 21 | kN/m³ |
       | Cerâmica/porcelanato | 0,5 | kN/m² |
       | EPS (enchimento) | 0,15 | kN/m³ |
       | Contrapiso | 21 | kN/m³ |

       **Fórmula peso próprio da laje (por m²):**
       ```
       g_pp = γc × h_f + γ_enc × h_e × (1 - b_nerv/s)
       ```
       onde `b_nerv` = largura da nervura, `s` = intereixo.

       ### 3.2 Cargas Variáveis (NBR 6120:2019 Tab. 2)

       | Uso | Carga acidental (qk) | Unidade |
       |---|---|---|
       | Residencial (dormitórios, sala) | 1,5 | kN/m² |
       | Residencial (área social) | 2,0 | kN/m² |
       | Comercial (escritórios) | 3,0 | kN/m² |
       | Comercial (lojas/corredor) | 4,0 | kN/m² |
       | Forro (sem acesso) | 0,5 | kN/m² |

       ### 3.3 Combinação ELU (NBR 6118 §11.7)

       ```
       Fd = γg × Fgk + γq × (Fq1k + Σψ0j × Fqjk)
       ```

       Para lajes residenciais (combinação normal):
       ```
       q_sd = 1,4 × g_k + 1,4 × q_k
       ```

       ### 3.4 Combinação ELS (NBR 6118 §11.7)

       ```
       q_ser = g_k + ψ2 × q_k
       ```

       | Uso | ψ2 |
       |---|---|
       | Residencial | 0,3 |
       | Comercial | 0,4 |
       | Forro | 0,2 |

       ---

       ## 4. Conversão de Carga (Área → Linear por Nervura)

       ```
       w_k  = q_k  × s    [kN/m] — carga característica linear
       w_sd = q_sd × s    [kN/m] — carga de cálculo (ELU)
       w_ser= q_ser× s    [kN/m] — carga de serviço (ELS)
       ```

       ---

       ## 5. Análise Estrutural — Método da Rigidez Direta

       ### 5.1 Tipos de Apoio Suportados (MVP)

       | Tipo | Descrição | Grau de liberdade |
       |---|---|---|
       | Biapoiada simples | Ambos os extremos simplesmente apoiados | Rotação livre, translação nula |
       | Contínua (2 ou 3 vãos) | Apoios intermediários rígidos | Continuidade de rotação |

       ### 5.2 Viga Biapoiada — Fórmulas Fechadas

       Para carregamento uniformemente distribuído `w_sd`:

       ```
       Msd_max = w_sd × L² / 8     [kN·m]  — momento máximo (centro)
       Vsd_max = w_sd × L / 2      [kN]    — cortante máximo (apoio)
       Ra = Rb = w_sd × L / 2      [kN]    — reações de apoio
       ```

       ### 5.3 Viga Contínua — Método da Rigidez Direta

       Matriz de rigidez de membro (viga de Euler-Bernoulli), coordenadas locais:

       ```
       k_local = (EI/L³) × |  12    6L   -12   6L  |
                            |  6L    4L²  -6L   2L² |
                            | -12   -6L   12   -6L  |
                            |  6L    2L²  -6L   4L² |
       ```

       **Pipeline:**
       1. Calcular `EI` da seção composta (nervura + capa) para cada vão
       2. Montar matriz global `K` por sobreposição das matrizes locais
       3. Aplicar condições de contorno (deslocamentos nulos nos apoios)
       4. Resolver `K × u = F` para vetor de deslocamentos nodais `u`
       5. Recuperar esforços internos por `f = k_local × u_local - f_fixed`

       **Vetor de cargas nodais equivalentes** (carga distribuída `w`):
       ```
       f_fixed = [ wL/2,  wL²/12,  wL/2,  -wL²/12 ]ᵀ
       ```

       ---

       ## 6. Seção Transversal — Geometria

       ### 6.1 Seção T Efetiva (Flexão Positiva)

       Largura efetiva da mesa (NBR 6118 §14.6.2):
       ```
       b_ef = min(b_nerv + L/10,  s)
       ```

       Momento de inércia da seção não-fissurada (seção T):
       ```
       y_cg = (b_ef × h_f × h_f/2 + b_nerv × h_nerv × (h_f + h_nerv/2)) /
              (b_ef × h_f + b_nerv × h_nerv)

       I_c  = b_ef × h_f³/12 + b_ef × h_f × (y_cg - h_f/2)² +
              b_nerv × h_nerv³/12 + b_nerv × h_nerv × (h_f + h_nerv/2 - y_cg)²
       ```

       ### 6.2 Altura Útil

       ```
       d = h_total - c_nom - φ_est - φ_long/2
       ```

       onde `c_nom` = cobrimento nominal (mínimo per NBR 6118 §7.4).

       ---

       ## 7. Verificações ELU

       ### 7.1 Flexão Simples — Seção T (NBR 6118 §17.2)

       **Passo 1 — Verificar se a LN está na mesa (caso mais comum):**
       ```
       MRd_mesa = αc × fcd × b_ef × h_f × (d - h_f/2)
       ```
       Se `Msd ≤ MRd_mesa` → LN na mesa → calcular como seção retangular `b_ef`:

       ```
       x/d = 1 - √(1 - 2Msd / (αc × fcd × b_ef × d²))
       As  = (αc × fcd × b_ef × x) / fyd
       ```

       **Passo 2 — Verificar limites:**
       ```
       x/d ≤ 0,45  (aço CA-50, domínio 2/3)
       x/d ≤ 0,35  (aço CA-60)
       As ≥ As_min
       ```

       ### 7.2 Armadura Mínima (NBR 6118 §17.3.5)

       ```
       As_min = ρ_min × b_w × d
       ```

       | fck (MPa) | ρ_min (CA-50) |
       |---|---|
       | 20 | 0,0015 |
       | 25 | 0,0015 |
       | 30 | 0,0020 |

       ### 7.3 Cisalhamento (NBR 6118 §17.4)

       **Resistência sem armadura transversal (vigotas):**
       ```
       VRd1 = [τRd × k × (1,2 + 40ρl) + 0,15σcp] × b_w × d
       ```
       onde:
       - `τRd = 0,25 × fctd`
       - `fctd = fctk,inf / γc = 0,7 × 0,3 × fck^(2/3) / 1,4`
       - `k = 1,6 - d` (d em metros, mínimo 1,0)
       - `ρl = As / (b_w × d)` (máximo 0,02)
       - `σcp = 0` (sem protensão)

       **Condição de verificação:**
       ```
       Vsd ≤ VRd1  →  aprovado (sem estribos)
       Vsd > VRd1  →  necessário estribos ou reforço (fora do escopo do MVP → BLOQUEIO)
       ```

       ---

       ## 8. Verificações ELS

       ### 8.1 Flecha — Modelo de Branson (NBR 6118 §17.3.2)

       **Momento de fissuração:**
       ```
       Mcr = fctk,inf × I_c / y_t
       ```
       onde `y_t` = distância do centroide à fibra mais tracionada, `fctk,inf = 0,7 × fctm`.

       **Momento de inércia efetivo (Branson):**
       ```
       Ie = Ic × (Mcr/Ma)³ + Ics × [1 - (Mcr/Ma)³]   ≤  Ic
       ```
       onde `Ics` = momento de inércia da seção fissurada (seção T com apenas armadura).

       **Flecha imediata:**
       ```
       δ_imediata = 5 × w_ser × L⁴ / (384 × Ecs × Ie)
       ```

       **Flecha diferida (longa duração):**
       ```
       δ_diferida = φ × δ_imediata_perm
       ```
       onde `φ = 2,0` (NBR 6118 §17.3.2.2, para t → ∞).

       **Flecha total:**
       ```
       δ_total = δ_imediata + δ_diferida
       ```

       **Limite normativo (NBR 6118 Tab. 13.3):**
       ```
       δ_lim = L / 250   (caso geral de pisos)
       δ_lim = L / 350   (sensível a recalque/vibração)
       ```

       **Verificação:** `δ_total ≤ δ_lim`

       ---

       ## 9. Quantitativos de Materiais

       ### 9.1 Por Unidade de Área da Laje (por m²)

       ```
       n_vigotas    = largura_total / s               [unid]
       n_enchimento = largura_total × L / (s_enc)     [unid]  — depende da peça

       V_capa       = b_ef_med × h_f × (largura_total × L)    [m³]
                     — subtrai volume das nervuras

       m_tela       = ρ_tela × h_f × 1,0              [kg/m²] — tela soldada NBR 7481
       ```

       ### 9.2 Fórmula de Cálculo do Número de Vigotas

       ```
       n_vigotas = ceil(largura / s)
       ```

       ### 9.3 Capa de Concreto — Volume

       ```
       V_capa = largura × comprimento × h_f
              - n_vigotas × comprimento × A_nerv
       ```
       onde `A_nerv` = área da seção transversal da nervura (variável por modelo de vigota).

       ---

       ## 10. Travas de Segurança (Hard Limits)

       | Condição | Ação do Sistema |
       |---|---|
       | `h_f < 4 cm` | BLOQUEAR + aviso: "Espessura de capa abaixo do mínimo NBR 6118" |
       | `L > 10 m` | BLOQUEAR + aviso: "Vão excede limite do modo catálogo" |
       | `Vsd > VRd1` | BLOQUEAR + aviso: "Cisalhamento excede capacidade sem estribos — consulte engenheiro" |
       | `x/d > 0,45 (CA-50)` | BLOQUEAR + aviso: "Armadura insuficiente — seção subdimensionada" |
       | `δ_total > δ_lim` | ALERTA (não bloquear) + aviso: "Flecha excede limite — verificar continuidade ou contraflecha" |
       | `As < As_min` | BLOQUEAR + aviso: "Armadura abaixo do mínimo normativo" |

       ---

       ## 11. Disclaimer Obrigatório em Todo Relatório

       ```
       Este relatório é resultado de ferramenta de pré-dimensionamento para estudos
       preliminares. NÃO substitui projeto estrutural elaborado por Engenheiro Civil
       habilitado com emissão de ART (CREA/CFT). O projetista responsável deve
       verificar as hipóteses, confirmar os parâmetros de entrada e atender
       integralmente à NBR 6118:2026 e demais normas aplicáveis.

       Normas utilizadas: NBR 6118:2026 | NBR 6120:2019 | NBR 7481:2023
       Parâmetros: fck = {fck} MPa | Aço {aco} | Intereixo {s} cm
       Campo de validade: Lajes unidirecionais com vigotas treliçadas passivas.
       ```
