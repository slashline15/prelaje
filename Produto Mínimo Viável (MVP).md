# Planejamento de escopo

Em vez de um escopo único, o projeto é pensado como **três projetos simultâneos**: o projeto do produto (o que o app faz), o projeto técnico (implementação) e o projeto do domínio (regras de engenharia e normas)

### O que vai entrar

* Informações técnicas e instruções  
* Limitado a modelo de vigotas unidirecional passivas  
* Cálculo estrutural  
* Entrada de dados  
* Discretizados representação matemática  
  Resumo Informal do MVP da Laje Treliçada (Pontos Chave)  
    
  O projeto da sua ferramenta de dimensionamento de lajes pré-moldadas está focado no essencial: o **motor de cálculo** e a **segurança jurídica**.1. Escopo Básico (O que o App Faz)  
* **Foco Total:** Apenas em vigotas unidirecionais passivas.  
* **O que Calcula:**  
  * Análise e dimensionamento estrutural (cortante, fletores, reações de apoio).  
  * Quantificação de materiais e orçamento em PDF (simples, com custos indiretos).  
  * Geração de memorial de cálculo e relatório descritivo.  
* **O que NÃO Faz (Por enquanto):**  
  * Não se integra com BIM/CAD ou ERP.  
  * Não faz otimização automática complexa.  
  * Não dimensiona outros elementos (vigas, pilares, fundações).

2\. O Coração do Projeto: O Domínio Técnico (As Regras)

* **Prioridade Máxima:** Confiabilidade do cálculo (a regra de cálculo é mais importante que a tela\!).  
* **Normas:** Seguir rigorosamente as versões atualizadas da **NBR 6118 (2026)** e **NBR 6120 (2019)**.  
* **Motor Isolado:** A lógica do cálculo (o *backend*) deve ser separada da interface e do banco de dados.

3\. Abordagem do Motor de Cálculo

* **Método Adotado:** **Método da Rigidez Direta** (Direct Stiffness Method), porque ele facilita a automação e o cálculo matricial.  
* **Modelagem:** A laje é vista como um monte de **vigas paralelas**.  
* **Motor Duplo (Para o MVP):**  
  * **Modo Catálogo (Rápido):** Usa tabelas pré-dimensionadas de fabricantes (Vão x Carga) para orçamentos e pré-dimensionamento rápido.  
  * **Modo Analítico (Completo):** Faz o cálculo completo via Rigidez Direta, verificando os limites da NBR (ELU e ELS).

4\. O Essencial: As Travas de Segurança e o "Safe Harbor" (Protetor Jurídico)

É crucial se proteger legalmente, já que é uma ferramenta de engenharia:

* **Aviso Obriagatório:** O app é só um **guia de referência** ou para **estudos preliminares**.  
* **Responsabilidade Técnica (RT):** Deixar CLARO que o software NÃO substitui a contratação de um **Engenheiro Civil habilitado** (que precisa emitir a ART).  
* **Documentação Clara:** Todos os relatórios devem listar:  
  * Versão exata da NBR utilizada (Ex: NBR 6118:2026).  
  * Materiais e parâmetros usados (fck do concreto, classe do aço).  
* **Bloqueios Inteligentes:**  
  * Recusar cálculos que extrapolem limites seguros (vãos demais, cargas loucas).  
  * Alertar o usuário se ele tentar usar dados abaixo dos mínimos normativos (Ex: capa de concreto com menos de 4 cm).  
* **Visão Geral:** Lembrar o usuário que o app só calculou a laje, não as **vigas, pilares ou fundações**.

Próximo Passo Sugerido

* Antes de programar, crie **10 exemplos de cálculo manual** para ter certeza que o seu motor de cálculo (seja em Python ou onde for) vai acertar os números.  
* Análise estrutural com métodos simplificados  
* Diagramas de cortante, fletores  
* Reações de apoio  
* Dimensionamento  
* Modelagem estrutural  
* Materiais tabelados (treliças, eps, concreto)  
* Memorial de cálculo simples  
* Detalhamento simplificado  
* Geração de orçamento em pdf  
* Quantificação de materiais  
* Geração de relatório descritivo  
* Valores configuráveis  
* Inlcusão de Custos indiretos básicos

### Não vai entrar

* Compatibilidade com BIM/CAD  
* otimização automática complexa  
* integração com ERP e múltiplos usuários corporativos  
* Dimensionamento de demais elementos

## 2\. Especificação do Domínio Técnico

O planejamento do escopo de um sistema de engenharia não deve focar na interface (telas), mas sim na **regra de cálculo.**

* Prioridade para o motor de cálculo funcional  
* Confiabilidade nos resultados  
* Adotar NBR 6118 e 6120 atualizadas

### Ressalva jurídica

Para ressalvar juridicamente os criadores e garantir o uso correto da ferramenta, a inclusão de avisos explícitos e limitações de responsabilidade é considerada **essencial** nas fontes consultadas. As tabelas de mercado e manuais técnicos de fabricantes já adotam essa prática, deixando claro que tais ferramentas servem como **guia de referência**, mas não eliminam a necessidade de um **projetista legalmente habilitado** e do estrito atendimento às normas técnicas.  
Abaixo, detalho as adições recomendadas para o seu MVP e a lógica por trás delas:

### 1\. Adição de Termos de Uso e Isenção de Responsabilidade (Disclaimer)

* **Ferramenta de Referência:** O sistema deve exibir, preferencialmente antes do primeiro uso e em todos os relatórios gerados, que se trata de uma ferramenta para **estudos preliminares e pré-dimensionamento**, e não de um projeto estrutural final.  
* **Obrigatoriedade do Engenheiro Civil:** Deve-se informar explicitamente que a utilização do software não substitui a necessidade de contratação de um **Engenheiro Civil habilitado** para a elaboração e aprovação do projeto, bem como para a emissão da responsabilidade técnica correspondente.  
* **Riscos de Falhas Estruturais:** É importante ressaltar que erros de cálculo ou interpretação podem resultar em danos materiais, lesões ou perda de vidas, e que a responsabilidade final pela aplicação dos resultados é do profissional que assina a obra.

### 2\. Especificação do "Campo de Validade" nos Relatórios

* **Limitações dos Materiais:** O relatório deve listar precisamente quais parâmetros foram usados (como o $f\_{ck}$ do concreto e a classe do aço) e advertir que os resultados são válidos **apenas para aquela geometria e materiais específicos**.  
* **Versão das Normas:** Para segurança jurídica, o app deve registrar qual versão/emenda da norma (ex: NBR 6118:2026 ou NBR 6120:2019) foi utilizada no motor de cálculo, evitando que o criador seja responsabilizado por mudanças futuras na legislação técnica.

### 3\. Esclarecimento sobre a Visão Global da Estrutura

* **Além da Laje:** O MVP deve informar que o dimensionamento da laje é apenas uma parte do sistema estrutural.  
* **Cargas e Apoios:** É fundamental avisar que a ferramenta dimensiona a nervura, mas não verifica a capacidade das **vigas de apoio, pilares ou fundações**, que devem ser calculados separadamente por um profissional.  
* **Escoramento:** As fontes sugerem que o relatório recomende ao usuário a consulta obrigatória ao **projeto de escoramento** fornecido pelo fabricante ou por um engenheiro, pois a segurança durante a fase de montagem é crítica e depende de fatores externos ao cálculo da peça pronta.

### 4\. Bloqueios de Segurança (Travas Técnicas)

* **Casos não Suportados:** Juridicamente, é prudente que o sistema **recuse calcular** situações que fujam das hipóteses simplificadoras adotadas (como vãos excessivos ou cargas muito elevadas para o modelo), emitindo um alerta de que o caso exige análise especial de um especialista.  
* **Avisos de Mínimos Normativos:** Quando o usuário tentar inserir dados abaixo dos limites mínimos da NBR 6118 (como espessura de capa menor que 4 cm), o sistema deve emitir um aviso de "não conformidade normativa" para evitar que a ferramenta induza a erros graves de execução.

**O que eu acho:** Essas adições são vitais porque a engenharia civil é uma atividade de risco regulamentada. Isolar o motor de cálculo das telas e documentar todas as hipóteses simplificadoras no **Projeto do Domínio** do seu software ajudará a comprovar que a ferramenta foi construída seguindo a boa técnica, mas que o controle final deve ser sempre humano e profissional.

### 3\. Ordem Prática das Etapas

1. **Requisitos Funcionais**: O que o sistema deve fazer (ex: calcular capacidade, validar entradas)  
2. **Requisitos Não Funcionais:** Desempenho e rastreabilidade (ex: tempo de resposta, funcionamento offline)  
3. **Documento de Domínio Técnico:** O mais importante, contendo as fórmulas, tabelas de coeficientes e referências normativas

### Isolamento e Versionamento

O escopo deve prever que o **motor de cálculo seja isolado**, não dependendo de telas ou bancos de dados, o que permite trocar a interface (mobile para web) sem alterar a inteligência do sistema. Além disso, o planejamento deve incluir o **versionamento das regras técnicas**, garantindo que não se misturem normas atuais com versões antigas

# Método de análise estática adotado

O método de cálculo de análise estática mais indicado para adoção em um backend de software de engenharia, conforme as fontes, é o **Método da Rigidez Direta (Direct Stiffness Method).**  
Este método é amplamente preferido para implementação computacional pelos seguintes motivos:

### 1\. Vantagens para o Desenvolvimento (Backend)

* **Automação:** Diferente do método da flexibilidade, o método da rigidez elimina a necessidade de o projetista (ou o algoritmo) selecionar manualmente as reações redundantes e uma estrutura liberada, permitindo que a análise seja inteiramente automatizada.  
* **Escalabilidade Matricial:** O software pode ser programado para gerar matrizes de rigidez de membros individuais e combiná-las em uma **matriz de rigidez da estrutura (K)** global através de coordenadas

### Modelagem Estrutural Recomendada

Para o backend de um software de lajes pré-moldadas, as fontes sugerem as seguintes hipóteses de cálculo:

* **Vigas Paralelas:** A hipótese normativamente compatível (NBR 6118\) é tratar a laje unidirecional como um conjunto de **vigas ou faixas paralelas** na direção das nervuras, desprezando a rigidez transversal e a torção.  
* **Análise de Primeira Ordem:** Recomenda-se uma análise baseada na geometria original da estrutura, assumindo comportamento linear e elástico, o que é suficiente e conveniente para a maioria das vigas contínuas e pórticos da prática da engenharia.

### Pipeline de Implementação no Motor de Cálculo

O fluxo lógico (ou "pipeline") para o backend deve seguir a estrutura de um **fluxograma de dimensionamento**:

1. **Entrada de Dados:** Geometria da seção (intereixo, capa, modelo da vigota) e carregamentos (NBR 6120).  
2. **Montagem do Sistema:** Conversão da carga de área (kN/²) para carga linear por nervura (kN/m).  
3. **Cálculo de Esforços:** Uso do **Método da Rigidez** para determinar Momentos Fletores (Msd) e Esforços Cortantes (Vsd)  
4. **Verificações Normativas (ELU/ELS):** Testes de posição da linha neutra, armadura mínima, flechas (usando modelos como o de Branson para seções fissuradas) e cisalhamento.

### Abordagem para o MVP

Adotar um motor duplo para o backend:

* **Modo Catálogo:** O sistema consulta tabelas de pré-dimensionamento de fabricantes (vão x carga → armadura), que é extremamente rápido para orçamentos.  
* **Modo Analítico:** O sistema realiza o cálculo completo via Rigidez Direta, impondo os limites geométricos e coeficientes de segurança (γ e ψ) das normas **NBR 6118 e NBR 6120**.

É importante que o **motor de cálculo deva ser isolado** do banco de dados e da interface, garantindo que a inteligência da engenharia permaneça válida mesmo que a tecnologia do frontend mude

### O **Modo Catálogo** de cálculo

O **Modo Catálogo** de cálculo é uma abordagem de pré-dimensionamento simplificado que utiliza matrizes de dados pré-calibradas por fabricantes. Em vez de realizar uma análise estrutural completa do zero (como no modo analítico), o sistema consulta uma base de dados para encontrar uma solução (vigota \+ reforço) que atenda ao vão e à carga solicitados.  
Abaixo, detalho a arquitetura, as informações e a lógica desse módulo:

### 1\. Arquitetura do Módulo de Catálogo

Para garantir escalabilidade e evitar o "retrabalho" citado nas fontes, o módulo deve ser isolado do banco de dados e da interface.

* **Camada de Dados (Master Data):** Armazena as "Chaves" técnicas (Fabricante, Modelo da Treliça, $f\_{ck}$, intereixo e espessura da capa) e a **Matriz de Soluções** (Vão vs. Carga).  
* **Motor de Busca (Domain Logic):** Recebe o vão livre e a carga total calculada e busca na matriz a primeira célula que atenda a ambos os critérios, retornando a armadura adicional necessária.  
* **Filtro de Validade:** Verifica se a solicitação está dentro dos limites da tabela (ex: vãos máximos de 10m) e emite avisos caso a carga extrapole a capacidade do modelo.

### 2\. Informações Necessárias

Para que o cálculo funcione, o backend precisa de dois conjuntos de dados:  
**Entradas do Usuário (Input):**

* **Vão livre ($L$):** Distância entre apoios.  
* **Uso da laje:** Residencial, comercial ou forro (para definir a carga acidental via NBR 6120).  
* **Revestimento e enchimento:** Para compor a carga permanente.

**Dados de Referência (Stored Data):**

* **Designação da Treliça:** Códigos como **TR 8644** ou **TB 8L**.  
* **Geometria da Seção:** Altura total ($h$), capa ($h\_f$) e intereixo ($s$).  
* **Resistência ($f\_{ck}$):** Geralmente fixado em 20 MPa para tabelas de mercado.

### 3\. Estrutura da Tabela de Soluções

A tabela no banco de dados deve seguir o modelo das tabelas práticas de mercado (como a "Trelifácil" ou manuais técnicos):  
Vão (m) \\ Carga Total (kgf/m²)150250350450550600**3.00 m**Ø 4.22 Ø 4.24 Ø 4.21 Ø 10.02 Ø 5/161 Ø 12.5**3.50 m**1 Ø 5.04 Ø 4.24 Ø 5.01 Ø 12.53 Ø 5/164 Ø 5/16**4.00 m**4 Ø 4.23 Ø 5.0............*As células internas representam a* ***armadura de reforço*** *a ser adicionada na base da vigota.*

### 4\. Fórmulas e Lógica de Cálculo

O pipeline de cálculo no Modo Catálogo segue estas etapas:

1. **Cálculo da Carga de Área ($q\_k$):** $$q\_k \= \\text{Peso Próprio} \+ \\text{Revestimento} \+ \\text{Carga Acidental (NBR 6120)}$$  
2. **Verificação do Intereixo ($s$):** O sistema deve confirmar que o intereixo real da laje coincide com o do catálogo (ex: 42 cm ou 48 cm), pois a carga é selecionada por metro quadrado.  
3. **Busca por Interpolação (opcional):** Se o vão for 3,15m e houver dados apenas para 3,00m e 3,20m, o software deve adotar o valor do vão imediatamente **superior** (3,20m) para garantir a segurança.  
4. **Verificação de Serviço:** O catálogo assume um limite de flecha (deformação) padrão, geralmente de **vão/250**.

### 5\. Ressalvas de Segurança no Modo Catálogo

Como esta é uma ferramenta de referência para o seu MVP, o relatório gerado deve obrigatoriamente informar:

* **"Campo de Validade":** Que os resultados são válidos apenas para o $f\_{ck}$ e intereixo especificados na tabela do fabricante.  
* **Aviso de Escoramento:** Indicar a distância máxima entre linhas de escoras conforme a tabela (ex: 1,10 m para vigotas H8).  
* **Isenção Jurídica:** Que a tabela é um guia de pré-dimensionamento e a responsabilidade técnica final é do Engenheiro Civil habilitado.

Com base nas fontes fornecidas, elaborei o **Documento de Domínio Técnico** para a sua ferramenta de dimensionamento de lajes treliçadas unidirecionais em concreto armado. Este documento consolida a "fonte da verdade" do sistema, isolando a inteligência da engenharia de qualquer interface ou infraestrutura de banco de dados.  
Como a ferramenta será gratuita e sem gestão de usuários/projetos, o foco total recai sobre o **motor de cálculo** e as **ressalvas de segurança**.

# Documento de Domínio Técnico: Laje Treliçada Unidirecional (Armadura Passiva)

### 1\. Objetivos e Hipóteses de Cálculo

A ferramenta visa realizar o pré-dimensionamento e a verificação de lajes nervuradas com nervuras pré-moldadas treliçadas.

* **Modelagem Estrutural:** A laje é tratada como um **conjunto de vigas paralelas** na direção das nervuras, desprezando-se a rigidez transversal e à torção.  
* **Análise Estática:** Análise de **primeira ordem** (linear-elástica), baseada na geometria original da estrutura.  
* \*\*Método Backend:\*\***Método da Rigidez Direta** (Direct Stiffness Method), automatizando a geração de matrizes de rigidez de membros e da estrutura global.

### 2\. Referências Normativas Brasileiras

O motor de cálculo deve seguir estritamente as versões mais recentes das normas:

* **NBR 6118:2026 (NBR 6118:2023 \+ Emenda 1:2026):** Critérios de dimensionamento, coeficientes de segurança e verificações de estados-limites.  
* **NBR 6120:2019:** Definição de pesos específicos e cargas variáveis de utilização.  
* **NBR 7481:2023:** Especificações para armaduras de distribuição em telas soldadas.

### 3\. Parâmetros de Entrada (Inputs)

O sistema deve solicitar obrigatoriamente:

* **Geometria:** Vão livre ($L$), intereixo ($s$), altura do enchimento ($h\_e$) e espessura da capa ($h\_f$).  
* **Materiais:** Resistência do concreto ($f\_{ck}$), classe do aço (CA-50/60) e designação da treliça (ex: TR 8644).  
* **Carregamentos:** Uso da laje (residencial, comercial ou forro) para presets de carga acidental e pacote de camadas para carga permanente.

### 4\. Motor de Cálculo (Dual Engine)

A ferramenta operará com dois módulos simultâneos:

#### A. Modo Catálogo (Pré-dimensionamento Rápido)

* **Lógica:** Consulta de matrizes de dados pré-calibradas (Vão x Carga).  
* **Critério de Busca:** O software identifica na tabela a primeira célula que atenda ao vão e à carga total solicitada, retornando a armadura de reforço necessária.  
* **Limitação:** Resultados válidos apenas para a geometria e $f\_{ck}$ específicos do catálogo consultado.

#### B. Modo Analítico (Dimensionamento por Nervura)

* **Pipeline:** Conversão da carga de área ($kN/m²$) para carga linear por nervura ($kN/m$) multiplicando-se pelo intereixo ($w\_k \= q\_k \\cdot s$).  
* **ELU (Estado-Limite Último):** Verificação de flexão simples, cisalhamento e posição da linha neutra (que deve passar preferencialmente pela mesa/capa).  
* **ELS (Estado-Limite de Serviço):** Verificação de flecha imediata e diferida (limite prático de **vão/250**) e controle de fissuração.

### 5\. Quantitativos e Saídas (Outputs)

Sem depender de banco de dados de projetos, a ferramenta gerará instantaneamente:

* **Lista de Materiais:** Número estimado de vigotas, contagem de peças de enchimento (EPS/Cerâmica), volume de concreto da capa e peso de telas soldadas.  
* **Memorial de Cálculo:** Exibição das fórmulas, coeficientes de ponderação ($\\gamma \= 1,4$ e $\\psi$ conforme o uso) e status de aprovação.

### 6\. Ressalva Jurídica e "Safe Harbor" (Essencial para Disponibilização Online)

Como a ferramenta é gratuita e aberta, cada relatório gerado deve conter obrigatoriamente:

* **Aviso de Guia de Referência:** Informar que os cálculos são apenas para **estudos preliminares** e não substituem o projeto estrutural final assinado por profissional habilitado.  
* **Campo de Validade:** Especificação clara dos materiais usados e das normas aplicadas (NBR 6118:2026).  
* **Obrigatoriedade de RT:** Mensagem explícita de que a execução da obra exige um **Engenheiro Civil habilitado** e a respectiva Anotação de Responsabilidade Técnica (ART).  
* **Travas de Segurança:** O sistema deve **recusar o cálculo** e emitir alertas caso o usuário insira vãos excessivos ou espessuras de capa abaixo do mínimo normativo de 4 cm.

**Sugestão de Próximo Passo:** Para garantir a confiabilidade deste documento, recomendo a elaboração de **10 casos de teste manuais** (exemplos resolvidos à mão) para servirem como "matriz de verdade" durante a programação do motor em Python/FastAPI.  
