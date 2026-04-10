Com base nas fontes e no histórico de planejamento, o documento de **Produto Mínimo Viável (MVP)** já consolidou a fundação técnica e estratégica do software. O foco agora deve migrar da especificação macro para a **documentação de detalhamento lógico**, garantindo que o desenvolvimento do "motor de cálculo" tenha uma referência absoluta para testes.  
Abaixo, apresento o check list completo, indicando o que já foi finalizado e os próximos passos em ordem de prioridade.

### Check list de Finalização do MVP

**Itens Concluídos (Base Técnica e Escopo)**

* ***Definição do Escopo (In/Out):** Definição clara de que o app será limitado a vigotas unidirecionais passivas e o que não será implementado (BIM, ERP, etc.).*  
* ***Modelagem Estrutural e Hipóteses:** Escolha da hipótese de vigas paralelas e análise de primeira ordem via **Método da Rigidez Direta**.*  
* ***Arquitetura do Sistema:** Decisão por **arquitetura em camadas** com motor de cálculo isolado e sistema de **Motor Duplo** (Catálogo \+ Analítico).*  
* ***Stack Tecnológica:** Definição de Python/FastAPI (Backend), Flutter (Frontend) e PostgreSQL (Banco).*  
* ***Ressalvas Jurídicas:** Estruturação de disclaimers, obrigatoriedade de RT por engenheiro e campo de validade nos relatórios.*  
* ***Lógica de Quantitativos:** Fórmulas para contagem de vigotas, volumes de concreto, peças de EPS e peso de telas soldadas.*

**Itens Pendentes (Ordem Decrescente de Prioridade)**

### 1\. Documento de Domínio Técnico: Matriz de Verdade (Prioridade Máxima)

Este é o item mais crítico, pois serve como a "fonte da verdade" para o backend.

* **O que falta:** Consolidar em um único documento todas as fórmulas (flexão, cisalhamento, flecha de Branson), tabelas de coeficientes ($\\\\gamma$, $\\\\psi$) e os limites normativos da NBR 6118:2026 e NBR 6120:2019.  
* **Ação:** Criar a **Matriz de Cálculo** em planilha com todas as entradas e saídas esperadas para servir de especificação.

#### 2\. Elaboração de 10 Casos de Teste Manuais

Essencial para validar se o motor de cálculo está "mentindo" ou não.

* **O que falta:** Resolver manualmente 10 situações distintas (diferentes vãos, cargas e modelos de vigota) e documentar o passo a passo dos resultados.  
* **Ação:** Usar os exemplos do capítulo de validação das fontes como base para os primeiros casos.

#### 3\. Modelo de Entidades e Modelo de Dados Final

Definir como as informações serão armazenadas para permitir o histórico e o versionamento.

* **O que falta:** Desenhar o diagrama ER (Entidade-Relacionamento) contendo as tabelas de Usuarios, Projetos, Materiais\_Catalogo e Resultados\_Calculo.  
* **Ação:** Mapear os campos obrigatórios para o PostgreSQL.

#### 4\. Contrato da API (Especificação de Endpoints)

Define como o Frontend (Flutter) conversará com o Motor de Cálculo.

* **O que falta:** Documentar o JSON de entrada (DadosLaje) e o JSON de saída (ResultadoDimensionamento), incluindo os códigos de erro para entradas inválidas.

#### 5\. Fluxo de Navegação e Wireframes de Casos de Uso

Definir a jornada do usuário antes de iniciar o design visual.

* **O que falta:** Mapear o fluxo: Tela Inicial → Lista de Projetos → Novo Dimensionamento (Formulário) → Resultado (Gráficos/Diagramas) → Memorial PDF.

#### 6\. Manual Técnico de Execução (Documento Complementar)

O guia de referência para o usuário final que resguarda a ferramenta tecnicamente.

* **O que falta:** Redigir as instruções de escoramento, manuseio e montagem baseadas nas boas práticas das fontes.

### Resumo da Próxima Fase

O projeto deve agora entrar na **Fase 1 (Domínio)** e **Fase 2 (Motor de Cálculo)**. O foco total deve ser na implementação do cálculo isolado e sua validação com os casos manuais, antes de se investir tempo na interface visual.  
