# Proposta de Mudança: catalogo-backend

## Objetivo

Implementar os módulos de backend responsáveis pelo catálogo de produtos: gestão de categorias (RF-03), gestão de produtos (RF-04) e os endpoints públicos da vitrine (RF-01).

## Contexto

Com a infraestrutura base pronta (`auth-infra-base`), esta mudança entrega os dados que alimentam a vitrine pública e o painel administrativo.

---

## Escopo Funcional

### Schema Prisma (novas entidades)
- `Category`: id, name, description, active, timestamps
- `Product`: id, name, description, price, stock, imageUrl, active, categoryId, timestamps
- Migration: criar tabelas + índices

### Módulo `catalog` (NestJS)

**Endpoints de Administração (protegidos — role Admin):**
- `POST /api/v1/categories` — criar categoria
- `GET /api/v1/categories` — listar categorias (paginado)
- `PATCH /api/v1/categories/:id` — editar categoria
- `DELETE /api/v1/categories/:id` — remover categoria
- `POST /api/v1/products` — criar produto (com upload de URL de imagem)
- `GET /api/v1/products` — listar produtos com filtros (categoria, ativo, estoque)
- `PATCH /api/v1/products/:id` — editar produto
- `DELETE /api/v1/products/:id` — remover produto

**Endpoints Públicos (sem autenticação):**
- `GET /api/v1/catalog/products` — listar somente produtos ativos (paginado)
- `GET /api/v1/catalog/products/:id` — detalhe de produto ativo
- `GET /api/v1/catalog/categories` — listar categorias com produtos ativos

### Regras de negócio implementadas
- Produtos inativos não aparecem nos endpoints públicos
- Validação de dados de entrada via `class-validator` (DTO)
- Auditoria em operações CUD de produtos e categorias

---

## Dependências

- `auth-infra-base` concluída ✅ (guards, Prisma, auditoria)

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Migration Prisma quebrando dados existentes | Baixa | Médio | Banco limpo nesta fase; migration cria do zero |
| Validação de estoque inconsistente entre leitura e escrita | Média | Médio | Usar transações Prisma para operações de escrita de estoque |
| Paginação sem índice adequado causando lentidão | Baixa | Baixo | Adicionar índice em `active`, `categoryId` no migration |

**Tamanho/Complexidade geral: MÉDIO**

---

## Execução de Linter Necessária

- `npm run lint` no workspace `apps/backend`
- `npx prisma format` para validar o schema atualizado
- `npm run format:check`

---

## Testes Unitários Necessários

- `CatalogService.createProduct()`: deve criar produto com dados válidos
- `CatalogService.createProduct()`: deve lançar erro se categoria não existir
- `CatalogService.listPublicProducts()`: deve retornar apenas produtos com `active = true`
- `CatalogService.updateProduct()`: deve ativar/desativar produto corretamente
- `CategoryService.deleteCategory()`: deve impedir exclusão se houver produtos ativos vinculados
- DTOs: validações obrigatórias de nome, preço (> 0), estoque (≥ 0)

---

## Testes de Integração Necessários

- `GET /api/v1/catalog/products` sem autenticação → retorna 200 com lista paginada de produtos ativos
- `POST /api/v1/products` sem token Admin → retorna 403 (RFC 9457)
- `POST /api/v1/products` com token Admin e payload válido → retorna 201
- `GET /api/v1/catalog/products/:id` com produto inativo → retorna 404 (RFC 9457)
- `DELETE /api/v1/categories/:id` com categoria que tem produtos → retorna 409

---

## Testes E2E Necessários

*(Estes serão executados com o frontend em `catalogo-frontend`)*
- Playwright: página da vitrine exibe lista de produtos ativos retornados pelo backend real
- Playwright: produto inativo não aparece na listagem pública

---

## Critério de Conclusão

- [ ] Migration Prisma aplicada com entidades `Category` e `Product`
- [ ] Endpoints de catálogo público retornam dados corretos sem autenticação
- [ ] Endpoints administrativos protegidos por guard de role Admin
- [ ] Todos os testes unitários e de integração passando
- [ ] Pipeline CI verde
