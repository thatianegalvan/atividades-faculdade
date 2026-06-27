# Proposta de Mudança: pedidos-backend

## Objetivo

Implementar o módulo de pedidos no backend (RF-02): criação de pedidos, máquina de estados, validação de estoque, cancelamento e registro de pagamentos por administradores.

## Contexto

Com o catálogo de produtos disponível no backend, esta mudança adiciona o fluxo central de negócio: o pedido do cliente — desde a criação até a entrega.

---

## Escopo Funcional

### Schema Prisma (novas entidades)
- `Order`: id, customerId (Clerk userId), status (enum), total, timestamps
- `OrderItem`: id, orderId, productId, quantity, unitPrice, subtotal
- `OrderStatus` (enum): `NEW`, `PAID`, `IN_PREPARATION`, `INVOICED`, `DISPATCHED`, `DELIVERED`, `CANCELLED`
- Migration: criar tabelas, enum, índices, auditoria de transições

### Módulo `orders` (NestJS)

**Endpoints do Cliente (protegidos — autenticação Clerk):**
- `POST /api/v1/orders` — criar pedido com lista de itens e quantidades
- `GET /api/v1/orders` — listar pedidos do cliente autenticado (histórico)
- `GET /api/v1/orders/:id` — detalhe de um pedido do cliente
- `PATCH /api/v1/orders/:id/cancel` — cancelar pedido (somente status ≠ DELIVERED)

**Endpoints do Administrador (protegidos — role Admin):**
- `GET /api/v1/admin/orders` — listar todos os pedidos com filtros (status, data)
- `PATCH /api/v1/admin/orders/:id/status` — avançar status do pedido conforme máquina de estados
- `POST /api/v1/admin/orders/:id/payment` — registrar pagamento (transição NEW → PAID)

### Regras de negócio implementadas
- Pedido só confirmado com ≥ 1 item
- Estoque validado na criação e revalidado na confirmação (transação Prisma)
- Apenas transições permitidas pela máquina de estados são aceitas
- Apenas admins registram pagamentos
- Pedidos cancelados não retornam ao fluxo
- Total calculado exclusivamente no backend
- Auditoria em todas as transições de status

---

## Dependências

- `catalogo-backend` concluída ✅ (entidades Product/Category disponíveis no Prisma)
- `auth-infra-base` concluída ✅ (guards, auditoria, rate limiting)

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Race condition em validação de estoque com pedidos concorrentes | Média | Alto | Usar transação Prisma com `SELECT FOR UPDATE` ou bloqueio de linha |
| Transição de estado inválida aceita por erro de lógica | Média | Alto | Implementar tabela de transições explícita e cobrir com testes exaustivos |
| Cálculo de total divergindo do frontend | Baixa | Médio | Total sempre calculado pelo backend; frontend exibe valor retornado pela API |

**Tamanho/Complexidade geral: MÉDIO**

---

## Execução de Linter Necessária

- `npm run lint` no workspace `apps/backend`
- `npx prisma format`
- `npm run format:check`

---

## Testes Unitários Necessários

- `OrderService.createOrder()`: deve calcular total corretamente
- `OrderService.createOrder()`: deve rejeitar pedido sem itens
- `OrderService.createOrder()`: deve rejeitar item com quantidade > estoque disponível
- `OrderService.createOrder()`: deve rejeitar produto inativo
- `OrdersStateMachine.canTransition(from, to)`: todas as 7 transições válidas retornam `true`
- `OrdersStateMachine.canTransition(from, to)`: transições inválidas retornam `false`
- `OrderService.cancelOrder()`: pedido com status `DELIVERED` não pode ser cancelado
- `OrderService.cancelOrder()`: pedido com status `NEW` pode ser cancelado
- `PaymentService.registerPayment()`: apenas usuário com role Admin pode registrar

---

## Testes de Integração Necessários

- `POST /api/v1/orders` com token de cliente e items válidos → retorna 201 com total calculado
- `POST /api/v1/orders` sem autenticação → retorna 401 (RFC 9457)
- `POST /api/v1/orders` com produto inativo → retorna 422 (RFC 9457)
- `POST /api/v1/orders` com quantidade > estoque → retorna 422 (RFC 9457)
- `PATCH /api/v1/admin/orders/:id/status` com transição inválida → retorna 409 (RFC 9457)
- `POST /api/v1/admin/orders/:id/payment` com token cliente → retorna 403 (RFC 9457)
- Após cancelamento, pedido não pode ser movido para outro estado → retorna 409

---

## Testes E2E Necessários

*(Estes serão finalizados em conjunto com `pedidos-frontend`)*
- Playwright: cliente autenticado cria pedido → pedido aparece no histórico com status `NEW`
- Playwright: admin registra pagamento → pedido muda para status `PAID`
- Playwright: cliente cancela pedido → pedido aparece como `CANCELLED`

---

## Critério de Conclusão

- [ ] Schema Prisma com entidades `Order` e `OrderItem` e migration aplicada
- [ ] Máquina de estados implementada e testada exaustivamente
- [ ] Race condition de estoque tratada com transação Prisma
- [ ] Auditoria registrando todas as transições de status
- [ ] Todos os testes unitários e de integração passando
- [ ] Pipeline CI verde
