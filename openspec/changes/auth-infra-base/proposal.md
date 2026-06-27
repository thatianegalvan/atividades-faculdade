# Proposta de Mudança: auth-infra-base

## Objetivo

Implementar a infraestrutura base do backend NestJS com autenticação via Clerk, configuração do banco de dados PostgreSQL com Prisma, módulo de auditoria e observabilidade (OpenTelemetry).

## Contexto

Após o setup do monorepo (`setup-monorepo`), esta mudança estabelece os fundamentos de segurança e persistência que todas as funcionalidades de negócio irão consumir.

---

## Escopo Funcional

### Backend (NestJS)
- Módulo `core/auth`: integração com Clerk (validação de JWT, guards NestJS, extração de identidade)
- Módulo `core/database`: configuração do Prisma Client, conexão com PostgreSQL, health check de banco
- Schema Prisma inicial: entidade `User` (espelho de identidade Clerk)
- Módulo `core/audit`: serviço de auditoria para operações CUD (Create/Update/Delete)
- Módulo `core/observability`: setup OpenTelemetry para traces e métricas
- Middleware de rate limiting: 100 req/min por IP, 1.000 req/min por usuário autenticado
- Tratamento global de erros seguindo **RFC 9457 Problem Details**
- Endpoint `GET /api/v1/health` público com status do banco

### Frontend (Next.js)
- Integração do **Clerk** via `@clerk/nextjs`: `<ClerkProvider>`, middleware de proteção de rotas
- Layout de autenticação: páginas de sign-in e sign-up usando componentes próprios (Clerk hosted pages)
- Configuração de variáveis de ambiente para Clerk (`NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`)

---

## Dependências

- `setup-monorepo` concluída ✅

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Configuração incorreta do Clerk JWT no NestJS | Média | Alto | Seguir documentação oficial Clerk + skill `clerk-setup`; testar com token real em desenvolvimento |
| Prisma migrations quebrando em PostgreSQL 15 | Baixa | Médio | Testar migration em ambiente Docker local antes do merge |
| OpenTelemetry com overhead de performance inesperado | Baixa | Baixo | Configurar sampling para desenvolvimento; desativar em testes unitários |
| Rate limiting afetando testes E2E | Baixa | Médio | Desativar rate limiting em ambiente de testes via variável de ambiente |

**Tamanho/Complexidade geral: MÉDIO**

---

## Execução de Linter Necessária

- `npm run lint` no workspace `apps/backend` e `apps/frontend`
- `npx prisma format` para validar formatação do schema
- `npm run format:check` (Prettier)

---

## Testes Unitários Necessários

- `AuthGuard`: deve rejeitar requests sem token JWT válido
- `AuthGuard`: deve permitir requests com token Clerk válido
- `AuditService`: deve registrar corretamente usuário, entidade e operação
- `GlobalExceptionFilter`: deve retornar formato RFC 9457 para erros HTTP 400, 401, 403, 404, 500
- `RateLimitGuard`: deve bloquear após exceder limite configurado

---

## Testes de Integração Necessários

- `GET /api/v1/health` deve retornar 200 com status do banco de dados conectado
- Middleware Clerk: requisição com token inválido retorna 401 no formato RFC 9457
- Prisma migration `npx prisma migrate dev` deve rodar sem erros no banco de dados de teste

---

## Testes E2E Necessários

- Playwright: acessar rota protegida sem autenticação → redireciona para sign-in
- Playwright: fazer login via Clerk → redireciona para área autenticada
- Playwright: fazer logout → redireciona para página pública

---

## Critério de Conclusão

- [ ] Guards de autenticação Clerk funcionando no backend
- [ ] Schema Prisma com migration aplicada no banco de desenvolvimento
- [ ] Tratamento RFC 9457 ativo para todos os erros
- [ ] Rate limiting configurado e testado
- [ ] Todos os testes unitários e de integração passando
- [ ] Pipeline CI verde
