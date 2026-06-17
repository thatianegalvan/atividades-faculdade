# AGENTS.md — Regras operacionais para agentes

Objetivo: fornecer diretrizes operacionais concisas e executáveis para agentes autônomos que atuam neste repositório, priorizando comandos diretos, limites claros e critérios de conclusão verificáveis.

1) Comportamento geral
- Antes de agir: declare suposições e pergunte se houver ambiguidade (veja `CLAUDE.md` para estilo de execução).
- Simplicidade: faça a menor mudança possível para cumprir a tarefa.
- Mudanças cirúrgicas: toque apenas o necessário; remova artefatos que sua mudança gerou.
- Critério de conclusão: só considere tarefa concluída quando os checks abaixo passarem (ex.: `pytest` retorna 0, linter retorna sem erros, build concluído).

2) Stack técnica (resumida)
- Fonte: preencher com o conteúdo de `@docs/architecture.md` (não encontrado localmente). Estrutura esperada:
  - Backend: linguagem, framework, runtime (ex.: Python 3.11 + FastAPI)
  - Frontend: framework + versão (ex.: React 18)
  - Infra: container runtime, orquestrador, banco de dados (ex.: Docker, Postgres)
  - CI/CD: ferramentas (ex.: GitHub Actions)

3) Estrutura do monorepo
- Fonte: preencher com o conteúdo de `@docs/architecture.md`.
- Exemplo de formato a preencher:
  - /packages/backend
  - /packages/frontend
  - /infra
  - /libs/shared

4) Comandos (Commands-First)
- Setup inicial (template — substitua conforme `@docs`):
  - `git clone <REPO_URL>`
  - `cd projeto_CI_CD`
  - `cp .env.example .env` (preencher variáveis)
  - `./scripts/setup.sh` ou `pip install -r requirements.txt` / `npm install`
- Build (template):
  - Backend: `./scripts/build-backend.sh` ou `python -m build` (preencher)
  - Frontend: `npm run build` (substituir conforme pacote)
- Run (template):
  - `./scripts/run.sh` ou `docker-compose up --build`
- Setup banco de dados (template):
  - `docker-compose up -d db`
  - `./scripts/db/migrate.sh` ou `alembic upgrade head`

5) Regras de qualidade e testes
- Comandos exemplares (substuir pelos reais):
  - Lint: `ruff check . --fix --select E,W,F` ou `npm run lint`
  - Formatação: `black .` ou `prettier --write .`
  - Testes unitários: `pytest` ou `npm test`
- Prioridade: 1) Testes passando, 2) Lint/format, 3) Performance/optimização.
- Critério de `done`: executar `pytest` e `build` sem erros; se houver mudanças geradas por linters/formatters, commitar junto.

6) Governança e autonomia no terminal
- Always do (sempre):
  - Executar testes em modo local antes de abrir PR.
  - Buscar contexto relevante em `@docs` e no serviço `context7` via `mcp` antes de mudanças grandes.
  - Fazer commit atômico com mensagem clara e referencia a issue/PR.
- Ask first (perguntar antes):
  - Alterações em esquema de banco de dados (migrations que alteram dados em produção).
  - Deploys para ambientes de produção ou criação de releases.
  - Alterações que mudam contratos públicos (APIs, DB schemas).
- Never do (nunca):
  - Expor secrets em commits ou logs.
  - Executar comandos destrutivos sem confirmação explícita (ex.: `DROP TABLE`, `rm -rf /`).
  - Alterar pipelines de CI/CD sem revisão humana.

7) Regras de aprendizado contínuo
- Após cada mudança relevante (PR fechada), o agente deve executar o seguinte loop:
  1. Rodar testes e checks (lint, build).
  2. Gerar um breve resumo das mudanças e das lições aprendidas (3-5 linhas).
  3. Propor uma atualização pontual ao `AGENTS.md` se detectar uma regra operacional que falhou ou poderia ser melhorada.
  4. Incluir no PR/issue uma seção `Post-change notes` com a proposta de ajuste para revisão humana.

8) Referências do projeto
- Documentação principal esperada na pasta `@docs` (architecture.md, setup.md, run.md). No workspace atual `@docs` não foi localizada; por favor, disponibilize `@docs/architecture.md` para completar automaticamente as seções de Stack e Monorepo.

9) Busca atualizada via MCP / context7
- Antes de tomar decisões que dependem de contexto do repositório, sempre tentar obter informações atualizadas com o serviço de contexto (`context7`) via a ferramenta interna MCP:
  - Exemplo genérico: `mcp serve context7 --query "<termo>"` ou `mcp context7 search "<termo>"` (substituir pelo CLI local da equipe).
  - Se `mcp` não estiver disponível localmente, documentar o erro e pedir instruções/credenciais.

10) Critérios de validação do AGENTS.md
- Este arquivo segue os princípios do guia `agents-md-guidelines.md`:
  - Comandos em primeiro lugar (commands-first).
  - Limites claros (Always/Ask first/Never).
  - Critérios de conclusão verificáveis.
  - Tamanho e escopo reduzidos; referencias externas a `@docs` para detalhes.

---

Observação: Preenchar os blocos marcados como "template" com comandos e paths reais contidos em `@docs/architecture.md`. Posso atualizar `AGENTS.md` automaticamente assim que você fornecer a pasta `@docs` ou o arquivo `architecture.md`.
