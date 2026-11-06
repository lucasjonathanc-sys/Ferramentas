# HB Organiza 💜

App para organizar a rotina de quem trabalha como **copywriter na China Link** e faz **social media freela** (vídeo, design, posts) para pequenas empresas.

Existem duas versões, com as mesmas telas e a mesma identidade visual:

- **`web/`: app web instalável (PWA), a versão usada no iPhone.** É grátis, não expira e não precisa de Mac.
- **`Organiza/`: app nativo em SwiftUI.** Fica guardado para o futuro e precisa de Mac/Xcode e de conta Apple para instalar.

## Instalar no iPhone (versão web, grátis)

1. Abra **https://lucasjonathanc-sys.github.io/Ferramentas/** no **Safari** do iPhone.
2. Toque em **Compartilhar** (o quadrado com a seta) e depois em **"Adicionar à Tela de Início"**.
3. Pronto: o **HB Organiza** aparece com o ícone **DB.** e abre em tela cheia, como um app.

- Os dados ficam salvos **só no iPhone**. Em **Ajustes → Salvar backup** dá para guardar uma cópia no app Arquivos ou no iCloud Drive.
- Para receber os **lembretes com o app fechado**, abra a atividade e toque em **"Adicionar ao Calendário do iPhone"**. Os alarmes vão junto e quem avisa é o Calendário.
- Funciona sem internet depois da primeira abertura.

### Publicação (GitHub Pages)

O workflow `.github/workflows/web-pages.yml` compila o app a cada push e **publica quando o código chega na branch `main`**.
Para ativar, uma única vez: o repositório precisa ser **público**, e em **Settings → Pages → Build and deployment → Source** é preciso escolher **GitHub Actions**.

Para rodar no computador: `cd web && npm install && npm run dev`.

---

# Versão nativa (SwiftUI)

## O que o app faz

Visual da identidade **Dulce Berdulles**: off-white `#F6F4EF`, preto `#0B0B0B`, vinho `#7A0E15`, bege `#D6CDC2` e taupe `#82766B`; tipografia Playfair Display (títulos), Montserrat (chamadas) e Inter (textos); logo **DB.**, traço de pincel, asterisco e seta como elementos de apoio.

| Aba | Para quê |
|---|---|
| **Hoje** | "Bom dia, Hanna", progresso do dia, agenda de hoje, atrasadas, o que vence hoje e os próximos dias |
| **Tarefas** | Busca + filtros Abertas / Concluídas / Canceladas / Só tarefas / Só compromissos; agrupado por Atrasadas, Hoje, Amanhã, Próximos 7 dias... Deslize para concluir, cancelar ou apagar |
| **+ (centro)** | "Nova atividade": Tarefa ou Compromisso, vencimento e horário opcionais, contexto, cliente e "Mais opções" (prioridade, repetição, vários lembretes, descrição e, nos compromissos, local e link) |
| **Agenda** | Dia / Semana (3 dias) / Mês, linha do tempo por hora com a hora atual marcada e faixa "Sem hora". Toque num horário vazio para criar um compromisso |
| **Clientes** | Ativos / Arquivados, busca, renda extra mensal e todas as atividades de cada cliente |

Contextos: **China Link, Clientes, Pessoal, Faculdade e Igreja**.

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
├── Models/       Atividade, Cliente (SwiftData), enums e ações
├── Fonts/        Playfair Display, Montserrat e Inter (licença OFL em LicencasFontes/)
├── Components/   Cabeçalho, barra de abas, chips, linha de atividade
├── Views/        Hoje, Tarefas, Agenda, Clientes, Nova atividade, Ajustes
└── Assets.xcassets
```

O workflow `.github/workflows/ios-build.yml` compila o app num Mac do GitHub a cada push, para garantir que está sem erros.
