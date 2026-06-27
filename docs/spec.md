# Especificação Funcional

## Requisitos

### RF-01 Vitrine de Produtos

- Permite ao cliente visualizar os produtos disponíveis em uma vitrine digital organizada em formato de catálogo.
- Exibe informações básicas dos produtos, como nome, descrição, preço e imagem, possibilitando a seleção de itens para compra.

#### Regras de negócio

- Produtos inativos não devem aparecer na vitrine.
- Produtos sem estoque podem ser visualizados, mas não podem ser adicionados ao carrinho.

### RF-02 Criação e Acompanhamento de Pedidos

- Permite ao cliente criar pedidos a partir da seleção de produtos e respectivas quantidades.
- Permite ao cliente visualizar o histórico de pedidos.
- Possibilita calcular automaticamente o valor total e informar dados básicos do cliente.
- Permite cancelar pedidos ainda não pagos.

#### Regras de negócio

- O sistema deve recalcular automaticamente o valor total do pedido sempre que a quantidade de um item for alterada
- Um pedido só pode ser confirmado se possuir pelo menos um produto selecionado
- Não permitir inclusão de quantidade superior ao estoque disponível
- Estoque deve ser validado novamente na confirmação do pedido
- Produtos inativos não podem ser vendidos.
- Pedidos cancelados não podem retornar ao fluxo operacional.
- Apenas administradores podem registrar pagamentos.
- O valor total do pedido é calculado pela soma dos itens.
- O cliente deve estar autenticado para criar pedidos.


#### Estados e transições dos pedidos

| Estado Atual             | Próximo Estado |
| ------------------------ | -------------- |
| Novo                     | Pago           |
| Pago                     | Preparação     |
| Preparação               | Faturado       |
| Faturado                 | Despachado     |
| Despachado               | Entregue       |
| Qualquer exceto Entregue | Cancelado      |

Novo = pedido criado aguardando pagamento


### RF-03 Gestão de Categorias

- Permite ao administrador cadastrar, editar, remover e organizar categorias.

#### Regras de negócio

- Apenas administradores podem criar, editar ou remover categorias

### RF-04 Gestão de Produtos

- Permite ao administrador cadastrar, editar, remover e organ

