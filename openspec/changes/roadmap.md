# Roadmap — e-micro-commerce (DevAI)

> Planejamento incremental do MVP da plataforma de gestão de pedidos e pagamentos para microempreendedores.
> Cada mudança tem tamanho, complexidade e risco máximos classificados como **médio**.
> Nenhuma mudança é considerada concluída sem os testes correspondentes.

---

## Visão Geral

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MVP e-micro-commerce                             │
├──────────────┬──────────────────────────────────────────────────────────┤
│  VITRINE     │  Clientes visualizam produtos, filtram por categoria,    │
│  (RF-01)     │  veem detalhes e adicionam ao carrinho                   │
├──────────────┼──────────────────────────────────────────────────────────┤
│  PEDIDOS     │  Clientes criam pedidos, acompanham status e cancelam    │
│  (RF-02)     │  Admins registram pagamentos e avançam o fluxo           │
├──────────────┼──────────────────────────────────────────────────────────┤
│  CATÁLOGO    │  Admins gerenciam categorias e produtos (RF-03, RF-04)   │
│  ADMIN       │                                                           │
└──────────────┴──────────────────────────────────────────────────────────┘
```

---

## Diagrama de Dependências

```
setup-monorepo
      │
      ▼
auth-infra-base
      │
      ▼
catalogo-backend ──────────────────────┐
      │                                │
      ▼                                │
catalogo-frontend              pedidos-backend
      │                                │
      └──────────────┬─────────────────┘
                     ▼
              pedidos-frontend
                     │
                     ▼
               admin-gestao
```

---

## Mudanças

| # | Mudança | Camada | RF(s) | Tamanho | Complexidade | Risco | Depende de |
|---|---------|--------|-------|---------|-------------|-------|------------|
| 1 | `setup-monorepo` | Infra | — | Baixo | Baixo | Baixo | — |
| 2 | `auth-infra-base` | Backend + Frontend | — | Médio | Médio | Médio | #1 |
| 3 | `catalogo-backend` | Backend | RF-01, RF-03, RF-04 | Médio | Médio | Baixo | #2 |
| 4 | `catalogo-frontend` | Frontend | RF-01 | Médio | Médio | Médio | #3 |
| 5 | `pedidos-backend` | Backend | RF-02 | Médio | Médio | Médio | #3 |
| 6 | `pedidos-frontend` | Frontend | RF-02 | Médio | Médio | Médio | #4, #5 |
| 7 | `admin-gestao` | Frontend | RF-03, RF-04, RF-02 (admin) | Médio | Médio | Médio | #5, #6 |

---

## Detalhamento por Mudança

### 1. `setup-monorepo` — Estrutura Base
**Escopo:** Monorepo npm Workspaces, scaffold Next.js + NestJS, Docker Compose, GitHub Actions CI
**Testes:** Smoke tests de build, health check E2E, `docker-compose up` sem erros

---

### 2. `auth-infra-base` — Autenticação e Infraestrutura Core
**Escopo:** Clerk no backend (JWT guard) e frontend (ClerkProvider, rotas protegidas), Prisma + PostgreSQL, RFC 9457, OpenTelemetry, rate limiting
**Testes:** Unitários de guards e filtros, integração de health check e JWT, E2E de login/logout

---

### 3. `catalogo-backend` — Backend do Catálogo
**Escopo:** Entidades `Category` e `Product` no Prisma, endpoints públicos do catálogo, endpoints admin protegidos, auditoria em CUD
**Testes:** Unitários de services e regras de negócio, integração de endpoints públicos e protegidos

---

### 4. `catalogo-frontend` — Vitrine Pública
**Escopo:** Páginas `/` e `/products/[id]`, componentes `ProductCard`, `CategoryFilter`, `ProductGrid`, sistema de design Nike
**Testes:** Unitários de componentes, integração com API real, E2E de navegação e filtros

---

### 5. `pedidos-backend` — Backend de Pedidos
**Escopo:** Entidades `Order` e `OrderItem`, máquina de estados completa, validação de estoque (transação Prisma), endpoints cliente e admin
**Testes:** Unitários exaustivos da máquina de estados, integração de criação e cancelamento, E2E de criação e pagamento

---

### 6. `pedidos-frontend` — Carrinho e Checkout
**Escopo:** `CartDrawer`, `useCart` hook, páginas `/cart`, `/checkout`, `/orders`, `/orders/[id]`
**Testes:** Unitários de hook e serviços, integração de checkout, E2E do fluxo completo cliente

---

### 7. `admin-gestao` — Painel Administrativo
**Escopo:** CRUD de produtos e categorias, gestão de pedidos, avanço de status, `AdminGuard`
**Testes:** Unitários de guard e formulários, integração de CRUD e fluxo de status, E2E do fluxo completo admin

---

## Estratégia de Testes (por mudança)

| Mudança | Unitários | Integração | E2E (Playwright) |
|---------|-----------|------------|-----------------|
| setup-monorepo | ✓ build smoke | ✓ docker health | ✓ página inicial + health endpoint |
| auth-infra-base | ✓ guards, RFC 9457 | ✓ JWT, migrations | ✓ login/logout |
| catalogo-backend | ✓ services, DTOs | ✓ endpoints públicos e admin | *(via catalogo-frontend)* |
| catalogo-frontend | ✓ componentes | ✓ integração com API | ✓ vitrine, filtros, detalhe |
| pedidos-backend | ✓ state machine, cálculo total | ✓ criação, cancelamento | ✓ fluxo básico |
| pedidos-frontend | ✓ useCart, serviços | ✓ checkout end-to-end | ✓ fluxo completo cliente |
| admin-gestao | ✓ AdminGuard, forms | ✓ CRUD, status flow | ✓ fluxo completo admin |

---

## Stitch (UI Prototypes)

> ⚠️ Nenhum projeto Stitch foi encontrado no momento da criação deste roadmap.
> Assim que os protótipos forem criados no Stitch, vincular os screens às mudanças correspondentes:
> - Screens de vitrine → `catalogo-frontend`
> - Screens de carrinho/checkout → `pedidos-frontend`
> - Screens de painel admin → `admin-gestao`

---

## Critério Global de Conclusão do MVP

- [ ] Todas as 7 mudanças concluídas com testes passando
- [ ] Pipeline CI verde em todas as mudanças
- [ ] Fluxo E2E completo: cliente adiciona produto → finaliza pedido → admin registra pagamento → admin entrega pedido
- [ ] Nenhum secret exposto em commits ou logs
- [ ] Documentação OpenAPI gerada para todos os endpoints

---

## Artefatos de Referência

| Documento | Localização |
|-----------|-------------|
| PRD | [docs/prd.md](../../../docs/prd.md) |
| Especificação Funcional | [docs/spec.md](../../../docs/spec.md) |
| Arquitetura | [docs/architecture.md](../../../docs/architecture.md) |
| Sistema de Design | [docs/design.md](../../../docs/design.md) |
| OpenSpec Config | [openspec/config.yaml](../../config.yaml) |
