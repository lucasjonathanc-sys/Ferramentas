# Organiza 💜

App de iOS (SwiftUI + SwiftData) para organizar a rotina de quem trabalha como **copywriter na China Link** e faz **social media freela** (vídeo, design, posts) para pequenas empresas.

## O que o app faz

Visual da identidade **Dulce Berdulles**: off-white `#F6F4EF`, preto `#0B0B0B`, vinho `#7A0E15`, bege `#D6CDC2` e taupe `#82766B`; tipografia Playfair Display (títulos), Montserrat (chamadas) e Inter (textos); logo **DB.**, traço de pincel, asterisco e seta como elementos de apoio.

| Aba | Para quê |
|---|---|
| **Hoje** | "Bom dia, Hanna", progresso do dia, agenda de hoje, atrasadas, o que vence hoje e os próximos dias |
| **Tarefas** | Busca + filtros Abertas / Concluídas / Canceladas / Só tarefas / Só compromissos e por contexto; agrupado por Atrasadas, Hoje, Amanhã, Próximos 7 dias... Deslize para concluir, cancelar ou apagar |
| **+ (centro)** | "Nova atividade": Tarefa ou Compromisso, vencimento e horário opcionais, contexto, cliente e "Mais opções" (prioridade, repetição, vários lembretes, descrição, local/link, tipo de trabalho e etapas) |
| **Agenda** | Dia / Semana (3 dias) / Mês, linha do tempo por hora com a hora atual marcada e faixa "Sem hora". Toque num horário vazio para criar um compromisso |
| **Clientes** | Ativos / Arquivados, busca, renda extra mensal e todas as atividades de cada cliente |

Contextos: **China Link, Freela, Pessoal, Faculdade e Igreja**.

O sininho mostra os próximos lembretes e o avatar abre os Ajustes (nome, notificações, limpeza de itens antigos).

## Como instalar no iPhone

Precisa de um **Mac com Xcode 16 ou mais novo** (o projeto usa pastas sincronizadas do Xcode 16) e iPhone com **iOS 17+**.

1. Clone o repositório e abra `Organiza.xcodeproj` no Xcode.
2. Clique no projeto **Organiza** → target **Organiza** → aba **Signing & Capabilities**.
3. Em **Team**, escolha seu Apple ID (Xcode → Settings → Accounts → adicionar). Se der erro de bundle id, troque `com.lucasjonathan.organiza` por algo único.
4. Conecte o iPhone no cabo, selecione ele lá em cima e aperte **▶︎ Run**.
5. No iPhone: **Ajustes → Geral → VPN e Gerenciamento de Dispositivo** → confiar no seu desenvolvedor. Se pedir, ative o **Modo de Desenvolvedor** em Ajustes → Privacidade e Segurança.

> Com Apple ID gratuito o app precisa ser reinstalado pelo Xcode a cada 7 dias. Com a conta Apple Developer (US$ 99/ano) dá pra distribuir via **TestFlight** e não expira assim.

## Estrutura

```
Organiza/
├── App/          OrganizaApp, Theme (cores/datas), Notificacoes
├── Models/       Atividade, Etapa, Cliente (SwiftData), enums e ações
├── Fonts/        Playfair Display, Montserrat e Inter (licença OFL em LicencasFontes/)
├── Components/   Cabeçalho, barra de abas, chips, linha de atividade
├── Views/        Hoje, Tarefas, Agenda, Clientes, Nova atividade, Ajustes
└── Assets.xcassets
```

O workflow `.github/workflows/ios-build.yml` compila o app num Mac do GitHub a cada push, para garantir que está sem erros.
