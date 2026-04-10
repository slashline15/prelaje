# Prelaje Flutter Shell

Scaffold Flutter offline-first para o MVP do Prelaje, pensado para uso em obra e sem depender de servidor no primeiro passo.

## O que este shell cobre

- Primeiro acesso com cadastro simples do empreiteiro.
- Home com atalhos de uso frequente.
- Wizard de 4 passos: dimensoes, uso, vigota e acabamento.
- Historico local de projetos.
- Persistencia offline com `SharedPreferences`.

## Fallback offline

O shell foi desenhado para operar sem backend:

- o wizard usa dados locais e estimativas comerciais provisorias;
- o historico fica salvo no dispositivo;
- o perfil do empreiteiro tambem fica salvo localmente;
- o PDF tecnico e a engine analitica ficam para a fase conectada.

## Pontos pendentes de integracao

- Conectar o wizard ao motor de catalogo local quando ele estiver pronto.
- Substituir os placeholders comerciais pela matriz de catalogo oficial em Dart.
- Adicionar seletor de logo da galeria e geracao de PDF no dispositivo.
- Criar a camada de sincronizacao com o backend analitico quando houver VPS.

## Estrutura

- `lib/app.dart` - bootstrap do app, onboarding e shell com abas.
- `lib/features/profile` - cadastro e persistencia do empreiteiro.
- `lib/features/home` - painel inicial.
- `lib/features/wizard` - fluxo de orcamento em 4 passos.
- `lib/features/history` - historico local.
- `lib/core/theme` - identidade visual do app.
