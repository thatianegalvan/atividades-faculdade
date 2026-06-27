# Arquitetura de Software

## Contexto Arquitetural

### Objetivo

Este documento define a arquitetura de software do produto e-micro-commerce, estabelecendo diretrizes técnicas, restrições arquiteturais e requisitos não funcionais para implementação por equipes humanas e agentes de inteligência artificial.

### Escopo

A arquitetura contempla:

* Frontend Web
* Backend NestJS
* Banco de Dados PostgreSQL
* Infraestrutura baseada em containers
* Segurança, observabilidade e qualidade de software

### Arquitetura de Referência

* Estilo arquitetural: Aplicação Web com Backend desacoplado via APIs RESTful
* Comunicação: HTTP/HTTPS com payload JSON
* Infraestrutura: Containers compatíveis com OCI
* Observabilidade: OpenTelemetry
* Segurança: OpenID Connect (OIDC) e OAuth 2.0

### Stack Tecnológica

* Frontend:

  * TypeScript
  * Next.js 16+
  * App Router
  * Vanilla CSS

* Backend:

  * TypeScript
  * Node.js 24+
  * NestJS 11+
  * Prisma 7+

* Banco de Dados:

  * PostgreSQL 15+

* Observabilidade:

  * Grafana Cloud

* Identidade:

  * Clerk

* Desenvolvimento:

  * Google Antigravity
  * npm Workspaces
  * Docker

* DevOps:

  * Terraform
  * GitHub Actions

### Estrutura do Monorepo

```text
apps/
 ├── frontend/
       └── src/
            └── app/
            └── components/
            └── features/
            └── services/
            └── hooks/
            └── types/
 └── backend/
       └── src/
            └── /core/
                  ├── auth/
                  ├── database/
                  ├── observability/
                  └── audit/
            └── /modules/
                   ├── catalog/
                   ├── orders/
                   └── customers/
infra/
docs/
.env
```
---

## Adequação Funcional

### Backend como Fonte Única de Verdade

* Toda regra de negócio deve residir exclusivamente no backend NestJS.
* O backend é a única fonte de verdade do sistema.

### Política Backend for Frontend

Toda comunicação de negócio deve ocorrer através das APIs do backend NestJS.

É proibido:

* acesso direto ao PostgreSQL
* acesso direto ao Prisma
* acesso direto ao Supabase
* acesso direto a recursos administrativos

### APIs e Versionamento

Base URL:

```text
https://api.dominio.com/v1
```

Versionamento:

```text
/v1/recurso/id
```

### Endpoints Públicos

* Catálogo
* Produtos ativos

### Endpoints Protegidos

* Pedidos
* Administração
* Dashboards

### Contrato de API

- Backend expõe contratos HTTP versionados.
- APIs seguem semântica REST.
- Payloads JSON.
- Versionamento obrigatório.
- Paginação obrigatória para coleções.
- Filtros, ordenação e pesquisa textual são suportados quando aplicáveis.
- Backend é a única fonte de verdade.
- Nenhuma regra de negócio pode existir no frontend.

A definição detalhada dos endpoints será mantida em OpenAPI.

---


### Estratégia de Tenancy

- MVP
Sem tenancy

- Evolução futura

Existe tenant_id
Banco compartilhado com schemas separados por tenant

---

## Eficiência de Desempenho

### Comunicação entre Componentes

* Comunicação via APIs REST
* Payloads JSON
* HTTPS obrigatório

### Rate Limiting

* 100 requisições por minuto por IP
* 1000 requisições por minuto por usuário autenticado

### Transações e Persistência

* Utilizar transações Prisma para operações atômicas

### Estratégias Futuras de Escalabilidade

- Serviço gerenciado PostgreSQL
- Orquestrador Kubernetes
- Fila assíncrona
- Serviço de observabilidade
- Provedor de identidade
- Serviço de e-mail
- Armazenamento de objetos
---

## Compatibilidade

### Integração via APIs REST

* Comunicação baseada em HTTP/HTTPS
* APIs RESTful

### Formatos de Comunicação

* JSON como formato padrão de integração

### Versionamento de APIs

* Versionamento obrigatório via URI

### CORS

* Whitelist explícita de origens permitidas

### Portabilidade entre Provedores PostgreSQL

* É proibido utilizar recursos específicos de fornecedores SaaS
* A aplicação deve permanecer portável entre provedores PostgreSQL

---

## Usabilidade

### Diretrizes Frontend

* As páginas não devem conter regras de negócio
* Toda integração com APIs deve ocorrer através da camada services
* Componentes devem permanecer desacoplados da infraestrutura

### Experiência de Autenticação

Toda experiência visual deve ser implementada utilizando componentes próprios da aplicação.

### Consistência de Interfaces

Server Actions podem ser utilizadas apenas como camada de transporte.

Restrições:

* Não conter regras de negócio
* Não acessar banco de dados
* Não acessar Prisma
* Não acessar serviços protegidos

---

## Confiabilidade

### Tratamento de Erros

Todos os erros expostos pela API devem seguir RFC 9457 Problem Details.

Formato:

```json
{
  "type": "...",
  "title": "...",
  "status": 400,
  "detail": "...",
  "instance": "..."
}
```

### Auditoria

Toda operação de Create, Update ou Delete em entidades críticas deve gerar auditoria.

Campos obrigatórios:

* Usuário
* Objeto


