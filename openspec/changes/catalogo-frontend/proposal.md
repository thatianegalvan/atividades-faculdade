# Proposta de Mudança: catalogo-frontend

## Objetivo

Implementar as páginas públicas da vitrine digital (RF-01): listagem de produtos, filtros por categoria, e página de detalhe do produto, consumindo os endpoints públicos do catálogo.

## Contexto

Com o backend do catálogo pronto (`catalogo-backend`), esta mudança entrega a experiência visual da vitrine para os clientes, seguindo o sistema de design Nike definido em `docs/design.md`.

---

## Escopo Funcional

### Páginas Next.js (App Router)
- `/` (ou `/catalog`) — Vitrine principal: grid de produtos ativos com filtros de categoria
- `/products/[id]` — Página de detalhe do produto: imagem, nome, descrição, preço, botão "Adicionar ao Carrinho" (desabilitado se sem estoque)

### Componentes
- `ProductCard`: card de produto com imagem, nome, preço, badge "Sem Estoque" quando aplicável
- `CategoryFilter`: pills de filtro de categoria (seleção única/múltipla)
- `ProductGrid`: grid responsivo de `ProductCard`s com paginação
- `ProductDetail`: layout de detalhe com imagem e informações

### Camada de Serviço
- `services/catalog.ts`: funções para consumir `GET /api/v1/catalog/products` e `GET /api/v1/catalog/products/:id` via fetch com cache Next.js

### Sistema de Design (conforme `docs/design.md`)
- Cores: Nike Black `#111111`, White `#ffffff`, Soft Cloud `#f5f5f5`
- Botões: formato pílula (`border-radius: 9999px`), preto sobre branco
- Cards: zero border-radius, sem sombras
- Tipografia: Futura (display), Helvetica Now (body)

---

## Dependências

- `catalogo-backend` concluída ✅ (endpoints públicos de catálogo disponíveis)
- `auth-infra-base` concluída ✅ (ClerkProvider configurado no layout)

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| CORS bloqueando chamadas do frontend para o backend | Média | Alto | Configurar whitelist CORS no NestJS antes dos testes de integração |
| Fontes Futura/Helvetica Now não disponíveis via Google Fonts | Alta | Baixo | Usar fallback: Inter para display, system-ui para body; documentar como substituição temporária |
| Hidratação SSR incorreta com Next.js App Router | Baixa | Médio | Usar Server Components para a vitrine pública e Client Components apenas para interatividade |

**Tamanho/Complexidade geral: MÉDIO**

---

## Execução de Linter Necessária

- `npm run lint` no workspace `apps/frontend`
- `npm run format:check`
- Checar tipos com `npm run type-check` (tsc --noEmit)

---

## Testes Unitários Necessários

- `ProductCard`: renderiza corretamente com props de produto ativo
- `ProductCard`: exibe badge "Sem Estoque" quando `stock = 0`
- `ProductCard`: botão "Comprar" está desabilitado quando sem estoque
- `CategoryFilter`: emite evento de filtro ao selecionar categoria
- `services/catalog.ts`: `getProducts()` chama URL correta com parâmetros de paginação
- `services/catalog.ts`: `getProduct(id)` chama URL correta

---

## Testes de Integração Necessários

- Página `/` renderiza lista de produtos consumindo API real em ambiente de teste
- Filtro de categoria na URL (`?category=X`) filtra os produtos corretamente
- Página `/products/[id]` exibe dados corretos de um produto específico
- Navegação entre páginas de paginação funciona corretamente

---

## Testes E2E Necessários

- Playwright: acessar `/` → visualizar grid de produtos com nome, preço e imagem
- Playwright: clicar em filtro de categoria → grid atualiza com produtos da categoria selecionada
- Playwright: clicar em produto → navega para `/products/[id]` com dados corretos
- Playwright: produto sem estoque → botão "Adicionar ao Carrinho" está desabilitado
- Playwright: página de produto inativo (ou inexistente) → retorna página 404

---

## Critério de Conclusão

- [ ] Vitrine pública exibe produtos ativos do backend real
- [ ] Filtros de categoria funcionando
- [ ] Sistema de design Nike aplicado (cores, tipografia, geometria de botões e cards)
- [ ] Sem regras de negócio no frontend — toda lógica via `services/`
- [ ] Todos os testes unitários, de integração e E2E passando
- [ ] Pipeline CI verde
