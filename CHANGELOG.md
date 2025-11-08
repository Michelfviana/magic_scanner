# Changelog - Magic Scanner

## Versão 2.0.0 - Melhorias no Sistema de Histórico e Dados das Cartas

### 🎉 Novas Funcionalidades

#### 1. **Informações Expandidas das Cartas**
Agora o app captura e exibe muito mais informações sobre cada carta:

- **Tipo da Carta** (`typeLine`): Ex: "Creature — Human Wizard"
- **Custo de Mana** (`manaCost`): Ex: "{2}{U}{U}"
- **CMC** (Converted Mana Cost): Custo convertido
- **Poder/Resistência** (`power`/`toughness`): Para criaturas
- **Cores** (`colors`): Lista de cores da carta
- **Código do Set** (`setCode`): Identificador da edição
- **Número do Colecionador** (`collectorNumber`): Número da carta na coleção
- **Artista** (`artist`): Nome do ilustrador
- **Palavras-chave** (`keywords`): Habilidades como Flying, Haste, etc.

#### 2. **Armazenamento Local de Imagens**
- As imagens das cartas escaneadas agora são **salvas localmente** no dispositivo
- Acesso mais rápido ao histórico (não precisa baixar imagens da internet)
- Funciona offline para visualizar cartas já escaneadas
- Imagens armazenadas em: `<app_directory>/card_images/`

#### 3. **Tela de Resultado Melhorada**
A tela de resultados agora exibe:
- ✅ Imagem grande da carta
- ✅ Nome e custo de mana em destaque
- ✅ Tipo completo da carta
- ✅ Edição e número do colecionador
- ✅ Poder/Resistência (para criaturas)
- ✅ Texto da carta em box destacado
- ✅ Habilidades em badges coloridos
- ✅ Nome do artista
- ✅ Preços (USD e BRL)

#### 4. **Histórico Aprimorado**
O histórico agora mostra:
- ✅ Imagens locais (carregamento instantâneo)
- ✅ Tipo da carta abaixo do nome
- ✅ Custo de mana em badge
- ✅ Visual mais limpo e informativo

### 🔧 Melhorias Técnicas

#### Backend (Python)
- **Função `format_card_response()` expandida** para incluir todos os novos campos da API Scryfall
- Suporte para cartas de dupla face (extrai informações da primeira face)
- Retorna mais metadados: artista, palavras-chave, cores, etc.

#### Frontend (Flutter)
- **Modelo `CardModel` expandido** com 11 novos campos
- **Banco de dados SQLite atualizado** (versão 2)
- **Migração automática** do banco de dados antigo para o novo
- **Sistema de armazenamento de imagens** com `path_provider`
- **Limpeza de imagens** ao deletar cartas do histórico

#### Dependências Adicionadas
- `path_provider: ^2.1.1` - Para gerenciar diretórios do app

### 🗄️ Estrutura do Banco de Dados (v2)

```sql
CREATE TABLE cards (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  edition TEXT NOT NULL,
  officialImageUrl TEXT NOT NULL,
  localImagePath TEXT,              -- NOVO
  description TEXT,
  rarity TEXT NOT NULL,
  typeLine TEXT,                     -- NOVO
  manaCost TEXT,                     -- NOVO
  cmc INTEGER,                       -- NOVO
  power TEXT,                        -- NOVO
  toughness TEXT,                    -- NOVO
  colors TEXT,                       -- NOVO (JSON array)
  setCode TEXT,                      -- NOVO
  collectorNumber TEXT,              -- NOVO
  artist TEXT,                       -- NOVO
  keywords TEXT,                     -- NOVO (JSON array)
  prices TEXT NOT NULL,
  scannedAt TEXT NOT NULL
)
```

### 📱 Experiência do Usuário

#### Antes:
- Apenas nome, edição, raridade e preço
- Imagens carregadas da internet toda vez
- Informações limitadas

#### Agora:
- **Informações completas** da carta
- **Imagens salvas localmente** (acesso offline)
- **Visual rico** com badges, cores e layout melhorado
- **Detalhes técnicos** como CMC, tipo, poder/resistência
- **Metadados culturais** como artista e palavras-chave

### 🚀 Como Usar

1. **Escanear uma carta**: As novas informações são capturadas automaticamente
2. **Ver resultado**: Todas as informações expandidas são exibidas
3. **Histórico**: As imagens ficam salvas localmente para acesso rápido
4. **Offline**: Visualize cartas já escaneadas mesmo sem internet

### 🔄 Migração Automática

Se você já tinha cartas salvas na versão anterior:
- ✅ O app **atualiza automaticamente** o banco de dados
- ✅ Cartas antigas continuam funcionando
- ✅ Novos campos ficam vazios para cartas antigas
- ✅ Novas cartas terão todas as informações

### 🎯 Próximos Passos Sugeridos

1. **Filtros no Histórico**: Por raridade, cor, tipo, etc.
2. **Estatísticas**: Valor total da coleção, cartas por cor, etc.
3. **Exportação**: Exportar histórico para CSV/JSON
4. **Compartilhamento**: Compartilhar cartas via WhatsApp/Telegram
5. **Busca**: Buscar cartas no histórico por nome ou características
6. **Ordenação**: Ordenar por preço, data, raridade, etc.

### 📝 Notas de Desenvolvimento

- A versão do banco de dados foi incrementada de `1` para `2`
- Migração é tratada pela função `_onUpgrade()` em `local_data_source.dart`
- Imagens são copiadas para o diretório do app durante o escaneamento
- Ao deletar uma carta, a imagem local também é removida
- Ao limpar o histórico, todas as imagens locais são deletadas

### 🐛 Correções

- Tratamento de erros ao salvar imagens localmente
- Fallback para imagem da internet se local não estiver disponível
- Validação de campos nulos/vazios antes de exibir
- Suporte para cartas sem poder/resistência (não-criaturas)

---

**Data**: 08/11/2025
**Versão**: 2.0.0
**Autor**: Magic Scanner Team
