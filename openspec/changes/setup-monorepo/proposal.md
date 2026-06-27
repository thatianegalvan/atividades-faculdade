# Proposta de Mudança: setup-monorepo

## Objetivo

Estabelecer a estrutura base do monorepo e-micro-commerce com toda a configuração de ambiente, ferramentas de desenvolvimento, pipelines de CI/CD e orquestração via Docker Compose.

## Contexto

O projeto não possui codebase existente. Esta mudança cria o esqueleto necessário para que todas as demais mudanças possam ser desenvolvidas de forma consistente e integrada.

---

## Escopo Funcional

- Criação da estrutura de diretórios do monorepo (`apps/frontend`, `apps/backend`, `infra`, `docs`)
- Configuração do **npm Workspaces** para gerenciamento dos pacotes
- Scaffold do projeto **Next.js 16+** (App Router, TypeScript, Vanilla CSS) em `apps/frontend`
- Scaffold do projeto **NestJS 11+** (TypeScript) em `apps/backend`
- Configuração do **Docker Compose** para orquestração local (PostgreSQL 15+, frontend, backend)
- Configuração dos arquivos `.env.example`, `.gitignore`, `README.md`
- Pipeline **GitHub Actions** inicial (lint + build + testes em PR)
- Configuração de linting e formatação: ESLint + Prettier
- Configuração do tsconfig base compartilhado

---

## Dependências

- **Nenhuma mudança anterior** — esta é a mudança inaugural
- Node.js 24+ e npm instalados localmente
- Docker e Docker Compose disponíveis localmente
- Repositório GitHub criado e configurado

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Incompatibilidade entre versões Next.js 16 e NestJS 11 | Baixa | Médio | Fixar versões exatas no `package.json` |
| npm Workspaces com hoisting incorreto | Baixa | Médio | Testar build isolado de cada workspace após setup |
| Pipeline CI/CD com permissões de secrets faltando | Média | Baixo | Usar variáveis de ambiente de exemplo para CI |

**Tamanho/Complexidade geral: BAIXO**

---

## Execução de Linter Necessária

- `npm run lint` (ESLint em todos os workspaces)
- `npm run format:check` (Prettier check)
- Verificar ausência de erros antes de aprovar PR

---

## Testes Unitários Necessários

- Smoke test do bootstrap NestJS: verificar que o servidor inicia sem erros
- Smoke test do Next.js: verificar que `npm run build` conclui sem erros
- Não há lógica de negócio nesta mudança — cobertura mínima aceitável

---

## Testes de Integração Necessários

- `docker-compose up --build` deve iniciar todos os serviços sem erros
- Conectividade entre backend e PostgreSQL validada via health check endpoint (`GET /health`)

---

## Testes E2E Necessários

- Playwright: verificar que a página inicial do Next.js carrega (HTTP 200) no navegador
- Playwright: verificar que o endpoint de saúde do backend responde (`GET /api/v1/health`)

---

## Critério de Conclusão

- [ ] Estrutura de diretórios criada conforme `docs/architecture.md`
- [ ] `npm install` executa sem erros em todos os workspaces
- [ ] `docker-compose up` inicia frontend, backend e banco de dados
- [ ] Pipeline CI passa (lint + build + testes) no pull request
- [ ] Nenhum secret exposto em commits
