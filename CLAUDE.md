# CLAUDE.md

    This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

    ## Contexto do Projeto

    Ferramenta SaaS de dimensionamento de lajes pré-moldadas treliçadas unidirecionais em concreto armado, voltada para o mercado brasileiro. O foco do MVP é exclusivamente em **vigotas unidirecionais passivas**.

    ## Stack Tecnológica Definida

    - **Backend:** Python + FastAPI
    - **Frontend:** Flutter (mobile/web)
    - **Banco de Dados:** PostgreSQL
    - **Método estrutural:** Método da Rigidez Direta (Direct Stiffness Method)

    > O projeto está na **fase de planejamento** — sem código implementado ainda. As especificações estão nos arquivos `.md` na raiz.

    ## Arquitetura do Sistema

    ### Princípio Fundamental
    O motor de cálculo deve ser **completamente isolado** da interface e do banco de dados. Troca de frontend (Flutter → Web) não deve exigir alteração no motor.

    ### Motor Duplo (Dual Engine)

    **Modo Catálogo (rápido):**
    - Consulta matrizes pré-calibradas de fabricantes (Vão × Carga Total)
    - Retorna armadura de reforço recomendada
    - Para orçamentos e pré-dimensionamento rápido
    - Assume `fck` e intereixo fixos conforme catálogo do fabricante
    - Busca sempre pelo vão imediatamente superior se não houver correspondência exata (margem de segurança)

    **Modo Analítico (completo):**
    - Pipeline: carga de área (kN/m²) → carga linear por nervura (kN/m) via `w_k = q_k × s`
    - ELU: verificação de flexão simples, cisalhamento, posição da linha neutra (deve estar na mesa/capa)
    - ELS: flecha imediata e diferida via modelo de Branson, limite prático de vão/250
    - Verificação de fissuração

    ### Pipeline de Cálculo (Modo Analítico)
    1. Entrada: geometria (L, s, h_e, h_f), materiais (fck, classe do aço, designação da treliça), uso da laje
    2. Conversão da carga: área → linear por nervura
    3. Cálculo de esforços via Método da Rigidez Direta (momentos fletores Msd e esforços cortantes Vsd)
    4. Verificações normativas (ELU + ELS)
    5. Quantificação de materiais e custos
    6. Geração de relatório PDF com memorial de cálculo

    ### Modelagem Estrutural
    A laje é tratada como um conjunto de **vigas paralelas** na direção das nervuras, desprezando rigidez transversal e torção. Análise de **primeira ordem** (linear-elástica).

    ## Normas Técnicas Obrigatórias

    - **NBR 6118:2026** (NBR 6118:2023 + Emenda 1:2026) — dimensionamento, coeficientes de segurança, ELU/ELS
    - **NBR 6120:2019** — pesos específicos e cargas variáveis de utilização
    - **NBR 7481:2023** — telas soldadas de armadura de distribuição

    Coeficientes: γ = 1,4 e ψ conforme uso (residencial/comercial/forro, per NBR 6120).

    ## Parâmetros de Entrada (Schema `DadosLaje`)

    | Campo | Descrição |
    |---|---|
    | `L` | Vão livre entre apoios |
    | `s` | Intereixo |
    | `h_e` | Altura do enchimento (EPS/cerâmica) |
    | `h_f` | Espessura da capa (mínimo normativo: 4 cm) |
    | `fck` | Resistência do concreto |
    | `aco` | Classe do aço (CA-50 / CA-60) |
    | `vigota` | Designação da treliça (ex: TR 8644, TB 8L) |
    | `uso` | residencial / comercial / forro |
    | `revestimento` | Pacote de camadas para carga permanente |

    ## Saídas (Schema `ResultadoDimensionamento`)

    - Número de vigotas estimado
    - Contagem de peças de enchimento (EPS/cerâmica)
    - Volume de concreto da capa
    - Peso de telas soldadas
    - Status de aprovação das verificações (ELU/ELS)
    - Memorial de cálculo com fórmulas e coeficientes

    ## Travas de Segurança (Obrigatórias)

    O sistema deve **recusar o cálculo** e emitir alerta explícito quando:
    - Vão extrapolar os limites do modelo/catálogo
    - Espessura de capa `h_f < 4 cm` (mínimo NBR 6118)
    - Qualquer parâmetro fora das hipóteses simplificadoras adotadas

    ## Ressalva Jurídica ("Safe Harbor")

    Todo relatório gerado deve conter obrigatoriamente:
    1. Aviso de que a ferramenta é para **estudos preliminares**, não substitui projeto estrutural final
    2. Obrigatoriedade de **Engenheiro Civil habilitado** e emissão de ART
    3. Especificação da versão exata da norma usada (ex: NBR 6118:2026)
    4. Materiais e parâmetros utilizados (fck, classe do aço)
    5. Aviso de que vigas de apoio, pilares e fundações **não são verificados** pela ferramenta
    6. Recomendação de consulta ao projeto de escoramento do fabricante

    ## Próximas Etapas de Desenvolvimento (em ordem de prioridade)

    1. **Matriz de Domínio Técnico** — consolidar todas as fórmulas (flexão, cisalhamento, Branson), tabelas de coeficientes e limites normativos em um único documento
    2. **10 casos de teste manuais** — cálculos resolvidos à mão para servir de "ground truth" na validação do motor
    3. **Diagrama ER** — tabelas: Usuarios, Projetos, Materiais_Catalogo, Resultados_Calculo
    4. **Contrato da API** — JSON de entrada (`DadosLaje`), JSON de saída (`ResultadoDimensionamento`), códigos de erro
    5. **Wireframes de navegação** — Tela Inicial → Lista de Projetos → Formulário → Resultado → PDF
    6. **Motor de cálculo Python** — implementar e validar contra os casos manuais antes de qualquer trabalho de interface
