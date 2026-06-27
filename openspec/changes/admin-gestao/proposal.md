# Proposta de Mudança: admin-gestao

## Objetivo

Implementar o painel administrativo completo para o empreendedor: CRUD de categorias e produtos, gestão do fluxo de pedidos (avanço de status) e registro de pagamentos.

## Contexto

Esta é a última mudança funcional do MVP. Com carrinho, pedidos e catálogo entregues, esta mudança completa o "fluxo duplo" da plataforma: o empreendedor agora tem controle total do back-office.

---

## Escopo Funcional

### Área Administrativa (rotas protegidas — role Admin)

#### Gestão de Categorias
- `/admin/categories` — listagem de categorias com ações de editar e remover
- `/admin/categories/new` — formulário de criação de categoria
- `/admin/categories/[id]/edit` — formulário de edição de categoria

#### Gestão de Produtos
- `/admin/products` — listagem de produtos com filtros (categoria, ativo, estoque) e ações
- `/admin/products/new` — formulário de criação de produto (nome, descrição, preço, estoque, imagem URL, categoria, ativo)
- `/admin/products/[id]/edit` — formulário de edição de produto

#### Gestão de Pedidos
- `/admin/orders` — listagem de todos os pedidos com filtros (status, data) e paginação
- `/admin/orders/[id]` — detalhe do pedido com linha do tempo de status e ações disponíveis:
  - Botão "Registrar Pagamento" (NEW → PAID)
  - Botão "Iniciar Preparação" (PAID → IN_PREPARATION)
  - Botão "Faturar" (IN_PREPARATION → INVOICED)
  - Botão "Despachar" (INVOICED → DISPATCHED)
  - Botão "Marcar como Entregue" (DISPATCHED → DELIVERED)
  - Botão "Cancelar Pedido" (qualquer exceto DELIVERED)

### Componentes
- `AdminLayout`: layout lateral com menu de navegação admin
- `AdminGuard`: componente cliente que verifica role Admin; redireciona não-admins
- `ProductForm`: formulário reutilizável de criação e edição de produtos
- `CategoryForm`: formulário reutilizável de criação e edição de categorias
- `OrderActions`: botões de ação disponíveis conforme status atual do pedido
- `AdminOrderTable`: tabela de pedidos com paginação e filtros

### Camada de Serviço
- `services/admin-catalog.ts`: CRUD de categorias e produtos via endpoints admin
- `services/admin-orders.ts`: listagem, avanço de status e registro de pagamentos

---

## Dependências

- `pedidos-backend` concluída ✅ (endpoints admin de pedidos disponíveis)
- `catalogo-backend` concluída ✅ (endpoints admin de categorias e produtos disponíveis)
- `auth-infra-base` concluída ✅ (guards de role Admin no backend)
- `pedidos-frontend` concluída ✅ (componentes base reutilizáveis)

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Usuário não-admin acessando rotas `/admin/*` no frontend | Baixa | Alto | `AdminGuard` no client + middleware Next.js verificando claim de role do Clerk |
| Ação de status avançada com transição inválida passando pelo frontend | Baixa | Médio | Backend já valida a transição; frontend apenas exibe botões disponíveis conforme status |
| Deleção de categoria com produtos ativos | Baixa | Médio | Backend retorna 409; frontend exibe mensagem de erro clara ao usuário |
| Formulário de produto sem validação de preço negativo | Média | Baixo | Validação em DTO no backend + validação HTML5 no frontend |

**Tamanho/Complexidade geral: MÉDIO**

---

## Execução de Linter Necessária

- `npm run lint` no workspace `apps/frontend`
- `npm run format:check`
- `npm run type-check`

---

## Testes Unitários Necessários

- `AdminGuard`: redireciona usuário não-admin para `/`
- `ProductForm`: exibe erro de validação quando preço ≤ 0
- `ProductForm`: exibe erro quando nome está vazio
- `OrderActions`: exibe somente botões de transição válidos para cada status
- `services/admin-catalog.ts`: `createProduct()` chama endpoint correto com payload correto
- `services/admin-orders.ts`: `advanceStatus()` chama endpoint com action correta
- `services/admin-orders.ts`: `registerPayment()` chama endpoint de pagamento correto

---

## Testes de Integração Necessários

- `GET /admin/products` como admin → exibe lista completa de produtos
- `POST /admin` criar produto → produto aparece na listagem admin e na vitrine pública
- Desativar produto → produto some da vitrine pública (verificar via GET catálogo)
- `GET /admin/orders` como admin → exibe todos os pedidos
- Registrar pagamento em pedido NEW → status muda para PAID na interface admin
- Acessar `/admin/*` com usuário sem role Admin → redirecionado para página inicial

---

## Testes E2E Necessários

- Playwright: login como admin → navegar para `/admin/products` → criar novo produto → produto aparece na vitrine pública
- Playwright: editar produto existente (alterar preço) → preço atualizado na vitrine
- Playwright: desativar produto → produto some da vitrine imediatamente
- Playwright: acessar `/admin/orders` → ver pedido criado pelo cliente → avançar status para PAID → status refletido na view do cliente (`/orders/[id]`)
- Playwright: login como cliente comum → tentar acessar `/admin/orders` → redirecionado para `/`
- Playwright: fluxo completo de pedido — admin avança pedido de NEW → PAID → IN_PREPARATION → INVOICED → DISPATCHED → DELIVERED

---

## Critério de Conclusão

- [ ] CRUD completo de categorias e produtos funcionando no painel admin
- [ ] Fluxo de status de pedidos operacional para todas as transições válidas
- [ ] `AdminGuard` bloqueando acesso de não-admins tanto no frontend quanto no backend
- [ ] Todos os testes unitários, de integração e E2E passando
- [ ] Pipeline CI verde
- [ ] MVP completo: vitrine → pedido → pagamento → entrega funcional end-to-end
