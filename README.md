# Organiza 💜

App de iOS (SwiftUI + SwiftData) para organizar a rotina de quem trabalha como **copywriter na China Link** e faz **social media freela** (vídeo, design, posts) para pequenas empresas.

## O que o app faz

| Aba | Para quê |
|---|---|
| **Hoje** | Saudação, progresso do dia, reuniões de hoje, entregas de hoje, atrasadas, aguardando aprovação e próximos 7 dias |
| **Tarefas** | Todas as tarefas agrupadas por status (A fazer → Fazendo → Em aprovação → Concluída), filtro por frente (China Link / Freela / Pessoal), busca, swipe para concluir/apagar, toque longo para mudar o status |
| **Agenda** | Semana com marcadores (azul = compromisso, rosa = entrega), calendário do mês, reuniões com link do Meet/Zoom e entregas do dia |
| **Clientes** | Clientes do freela com cor, nicho, @instagram, WhatsApp, valor mensal (soma da renda extra) e todas as entregas/reuniões de cada um |

Detalhes pensados pra rotina de marketing:
- **Tipos de tarefa**: Copy, Roteiro, Vídeo, Design, Post, Stories, Planejamento.
- **Etapas sugeridas** por tipo (ex.: Vídeo → Roteiro, Gravação, Edição, Legenda + capa, Aprovação, Postar), com barra de progresso.
- **Lembretes** (notificações locais) no prazo da tarefa e X minutos antes de cada reunião.
- Campo de **briefing / notas / links** em cada tarefa e **pauta** em cada reunião.
- Modo claro e escuro, tudo em português, dados salvos só no iPhone.

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
├── Models/       Tarefa, Etapa, Compromisso, Cliente (SwiftData) + enums
├── Components/   Chips, anel de progresso, linhas de tarefa/compromisso
├── Views/        Hoje, Tarefas, Agenda, Clientes, editores e Ajustes
└── Assets.xcassets
```

O workflow `.github/workflows/ios-build.yml` compila o app num Mac do GitHub a cada push, para garantir que está sem erros.
