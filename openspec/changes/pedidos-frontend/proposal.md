# Proposta de Mudança: pedidos-frontend

## Objetivo

Implementar as páginas e componentes do fluxo de pedidos para o cliente (RF-02): carrinho de compras, checkout, histórico de pedidos e cancelamento, consumindo os endpoints de pedidos do backend.

## Contexto

Com o backend de pedidos pronto (`pedidos-backend`), esta mudança entrega a jornada completa do cliente: selecionar produtos → criar pedido → acompanhar status → cancelar se necessário.

---

## Escopo Funcional

### Carrinho (estado local do cliente)
- Componente `CartDrawer`: painel lateral com itens selecionados, quantidades e total estimado
- Hook `useCart`: gerenciamento de estado do carrinho (adicionar, remover, atualizar quantidade)
- Estado do carrinho persistido em `localStorage` enquanto não finalizado

### Páginas Next.js (App Router)
- `/cart` — Resumo do carrinho com lista de itens, subtotais e botão "Finalizar Pedido"
- `/checkout` — Confirmação de dados do cliente e submissão do pedido (rota protegida)
- `/orders` — Histórico de pedidos do cliente autenticado (rota protegida)
- `/orders/[id]` — Detalhe de um pedido: itens, status atual, linha do tempo de progresso

### Componentes
- `CartItem`: item do carrinho com controles de quantidade
- `OrderStatusBadge`: badge visual do status do pedido (cores semânticas mínimas)
- `OrderTimeline`: linha do tempo das transições de status do pedido
- `OrderCard`: card resumo do pedido para listagem de histórico

### Camada de Serviço
- `services/orders.ts`: funções para `POST /api/v1/orders`, `GET /api/v1/orders`, `GET /api/v1/orders/:id`, `PATCH /api/v1/orders/:id/cancel`

---

## Dependências

- `pedidos-backend` concluída ✅ (endpoints de pedidos disponíveis)
- `catalogo-frontend` concluída ✅ (botão "Adicionar ao Carrinho" nos cards de produto)
- `auth-infra-base` concluída ✅ (proteção de rotas e identidade do usuário)

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Estado do carrinho em `localStorage` desincronizado com estoque real | Média | Médio | Validar estoque novamente no checkout antes de enviar pedido; exibir erro ao usuário |
| Usuário não autenticado chegando na página de checkout | Baixa | Baixo | Middleware Clerk redireciona para sign-in automaticamente |
| Total exibido no carrinho diferindo do total calculado pelo backend | Baixa | Médio | Após criação do pedido, exibir o total retornado pelo backend, não o estimado localmente |

**Tamanho/Complexidade geral: MÉDIO**

---

## Execução de Linter Necessária

- `npm run lint` no workspace `apps/frontend`
- `npm run format:check`
- `npm run type-check`

---

## Testes Unitários Necessários

- `useCart.addItem()`: adiciona item corretamente ao estado
- `useCart.addItem()`: incrementa quantidade se produto já está no carrinho
- `useCart.removeItem()`: remove item do carrinho
- `useCart.updateQuantity()`: limita quantidade ao estoque disponível
- `useCart.total()`: calcula total estimado corretamente
- `CartItem`: renderiza nome, preço e controles de quantidade
- `OrderStatusBadge`: renderiza texto correto para cada status
- `services/orders.ts`: `createOrder()` chama endpoint correto com payload correto

---

## Testes de Integração Necessários

- `/cart` exibe itens adicionados anteriormente da vitrine
- `POST /api/v1/orders` via checkout retorna pedido criado com total do backend
- `/orders` exibe lista de pedidos do usuário autenticado
- `/orders/[id]` exibe detalhe correto de um pedido
- Cancelamento de pedido via `/orders/[id]` atualiza status para `CANCELLED`

---

## Testes E2E Necessários

- Playwright: fluxo completo — adicionar produto ao carrinho → ir ao checkout → confirmar pedido → ver pedido no histórico com status `NEW`
- Playwright: tentar adicionar ao carrinho produto sem estoque → botão permanece desabilitado
- Playwright: cancelar pedido no histórico → status muda para `CANCELLED`
- Playwright: acessar `/checkout` sem autenticação → redireciona para sign-in
- Playwright: após finalizar pedido, carrinho deve estar vazio

---

## Critério de Conclusão

- [ ] Fluxo completo cliente → carrinho → checkout → pedido criado funcionando
- [ ] Histórico de pedidos exibindo status atualizado em tempo real (polling ou reload)
- [ ] Cancelamento de pedido funcionando com feedback visual
- [ ] Total exibido é sempre o retornado pelo backend
- [ ] Todos os testes unitários, de integração e E2E passando
- [ ] Pipeline CI verde
