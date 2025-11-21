# Magic Scanner - Projeto de Aplicativo de Reconhecimento de Cartas de Magic

**Membros do Grupo:**

- Gabriel de Oliveira Ramin
- João Victor de Oliveira  
- Alex Zulini Venier
- Michel Ferreira Viana de Carvalho
- Gabriel Pinson

## 1. Definição do Problema

Jogadores de Magic: The Gathering frequentemente precisam identificar rapidamente cartas e consultar seus valores de mercado. Atualmente, esse processo depende de buscas manuais em sites especializados, o que pode ser demorado, especialmente quando se está fora de casa ou em torneios. A ausência de uma solução prática que integre reconhecimento automático de cartas via imagem com consulta em bases de dados de preços gera dificuldades na gestão de coleções e negociações.

## 2. Objetivo do Projeto

Desenvolver um aplicativo móvel em Flutter que, utilizando recursos de inteligência artificial e APIs externas, permita:

- Identificar cartas de Magic a partir de fotos tiradas com o celular
- Consultar automaticamente informações oficiais (nome, edição, imagem, descrição)
- Exibir o valor de mercado atualizado da carta em tempo real
- Manter um histórico de consultas, armazenando a imagem oficial da carta obtida via API

## 3. Público-Alvo

- **Colecionadores**: desejam acompanhar o valor de suas cartas
- **Jogadores ocasionais e competitivos**: precisam consultar rapidamente informações durante jogos ou trocas
- **Lojas e vendedores**: interessados em ter uma ferramenta prática para agilizar cotações e negociações

## 4. Funcionalidades Principais

- ✅ Captura de imagem da carta (via câmera ou galeria)
- ✅ Identificação automática da carta usando Google Gemini Vision API
- ✅ Consulta em bases externas (Scryfall) para informações detalhadas e preços
- ✅ Exibição do valor de mercado atualizado
- ✅ Interface responsiva e otimizada para mobile
- ⏳ Histórico de consultas para referência futura
- ⏳ Comparação de preços em diferentes mercados

## 5. Tecnologias Utilizadas

- **Frontend/App**: Flutter (multiplataforma – Android/iOS/Linux/Web)
- **IA para reconhecimento**: Google Gemini Vision API
- **APIs externas**: Scryfall API (informações oficiais das cartas)
- **Gerenciamento de estado**: Riverpod
- **Persistência local**: SQLite/Hive (para histórico de buscas)
- **Backend**: Python (FastAPI) para orquestração
- **Navegação**: GoRouter
- **HTTP Client**: Dio

## 6. Estrutura do Projeto

```text
magic/
├── lib/                    # Código Flutter
│   ├── core/              # Configurações e constantes
│   ├── data/              # Camada de dados (repositories, data sources)
│   ├── domain/            # Modelos e entidades de negócio
│   └── presentation/      # UI e gerenciamento de estado
│       ├── screens/       # Telas do aplicativo
│       └── providers/     # Providers do Riverpod
├── backend/               # API Python (FastAPI)
│   ├── main.py           # Servidor principal
│   ├── requirements.txt  # Dependências Python
│   └── .env             # Variáveis de ambiente
└── test/                 # Testes automatizados
```

## 7. Como Executar o Projeto

### Pré-requisitos

- Flutter SDK 3.0+
- Python 3.8+ com pip
- Chave API do Google Gemini ([Obter aqui](https://makersuite.google.com/app/apikey))
- Git para clonar o repositório

### Instalação Completa

#### 1. Clone o Repositório

```bash
git clone https://github.com/Michelfviana/magic_scanner.git
cd magic
```

#### 2. Configure o Backend (Python)

```bash
# Entre na pasta backend
cd backend

# Crie e ative um ambiente virtual (recomendado)
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# ou no Windows: venv\Scripts\activate

# Instale as dependências
pip install -r requirements.txt

# Configure a chave da API
cp .env.example .env
# Edite o arquivo .env e adicione sua GEMINI_API_KEY
```

**Execute o servidor:**
```bash
uvicorn main:app --reload --port 8000
```

**O backend estará rodando em:** `http://localhost:8000`

#### 3. Configure o Frontend (Flutter)

```bash
# Em um novo terminal, vá para a pasta raiz do projeto
cd magic  # ou cd .. se estiver na pasta backend

# Instale as dependências do Flutter
flutter pub get

# Execute o aplicativo
flutter run
```

### Execução Rápida (Desenvolvimento)

Se já tiver tudo configurado:

```bash
# Terminal 1: Backend
cd backend && source venv/bin/activate
uvicorn main:app --reload --port 8000

# Terminal 2: Frontend  
flutter run
```

## Executar em Servidor/Produção

### Opção 1: Servidor Local (Linux/Ubuntu)

```bash
# 1. Instale dependências do sistema
sudo apt update
sudo apt install python3 python3-pip python3-venv git

# 2. Clone e configure o projeto
git clone https://github.com/Michelfviana/magic.git
cd magic/backend

# 3. Configure ambiente
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Configure variáveis de ambiente
cp .env.example .env
# Edite .env com sua GEMINI_API_KEY

# 5. Execute em produção
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Opção 1B: Rodando no Windows

```bat
REM 1. Instale Python 3.8+ e Git (https://www.python.org/downloads/)
REM 2. Clone o repositório
git clone https://github.com/Michelfviana/magic.git
cd magic\backend

REM 3. Crie e ative o ambiente virtual
python -m venv venv
venv\Scripts\activate

REM 4. Instale as dependências
pip install -r requirements.txt

REM 5. Configure variáveis de ambiente
copy .env.example .env
REM Edite .env e adicione sua GEMINI_API_KEY

REM 6. Rode o servidor
uvicorn main:app --reload --port 8000
REM O backend estará disponível em http://localhost:8000
```

> **Dicas Windows:**

> - Use o Prompt de Comando (cmd) ou PowerShell.
> - Para ativar o venv no PowerShell: `venv\Scripts\Activate.ps1`
> - Se der erro de permissão, execute: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` no PowerShell.

---

### Opção 1C: Rodando com Docker

> **Pré-requisito:** Docker instalado ([download](https://www.docker.com/products/docker-desktop/))

#### Build e run manual do backend

```bash
cd backend
docker build -t magic-backend .
docker run -d -p 8000:8000 --env-file .env magic-backend
# O backend estará disponível em http://localhost:8000
```

#### Usando docker-compose

```bash
cd backend
docker-compose up --build
# O backend estará disponível em http://localhost:8000
```

> **Dicas Docker:**

> - Edite o arquivo `.env` antes de rodar para garantir que a variável `GEMINI_API_KEY` está definida.
> - Para parar os containers: `docker-compose down` ou `docker stop <id>`
> - Para logs: `docker logs <id>`

---

### Opção 1B: Rodando no Windows

```bat
REM 1. Instale Python 3.8+ e Git (https://www.python.org/downloads/)
REM 2. Clone o repositório
git clone https://github.com/Michelfviana/magic.git
cd magic\backend

REM 3. Crie e ative o ambiente virtual
python -m venv venv
venv\Scripts\activate

REM 4. Instale as dependências
pip install -r requirements.txt

REM 5. Configure variáveis de ambiente
copy .env.example .env
REM Edite .env e adicione sua GEMINI_API_KEY

REM 6. Rode o servidor
uvicorn main:app --reload --port 8000
REM O backend estará disponível em http://localhost:8000
```

> **Dicas Windows:**

> - Use o Prompt de Comando (cmd) ou PowerShell.
> - Para ativar o venv no PowerShell: `venv\Scripts\Activate.ps1`
> - Se der erro de permissão, execute: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` no PowerShell.

---

### Opção 1C: Rodando com Docker

> **Pré-requisito:** Docker instalado ([download](https://www.docker.com/products/docker-desktop/))

#### Build e run manual do backend:
```bash
cd backend
docker build -t magic-backend .
docker run -d -p 8000:8000 --env-file .env magic-backend
# O backend estará disponível em http://localhost:8000
```

#### Usando docker-compose:
```bash
cd backend
docker-compose up --build
# O backend estará disponível em http://localhost:8000
```

> **Dicas Docker:**
> - Edite o arquivo `.env` antes de rodar para garantir que a variável `GEMINI_API_KEY` está definida.
> - Para parar os containers: `docker-compose down` ou `docker stop <id>`
> - Para logs: `docker logs <id>`

#### 2. **Teste do Aplicativo Flutter**

**Passo 1: Tela de Escaneamento**
- ✅ Abra o app (deve iniciar na tela "Escanear")
- ✅ Teste o botão "Abrir Câmera" (deve abrir a câmera do dispositivo)
- ✅ Teste o botão "Selecionar da Galeria" (deve abrir a galeria)
- ✅ Verifique se o loading aparece durante o processamento

**Passo 2: Envio e Processamento**
- ✅ Selecione uma imagem de carta de Magic
- ✅ Aguarde o processamento (deve mostrar "Identificando carta...")
- ✅ Verificar se navega automaticamente para a tela de resultado

**Passo 3: Tela de Resultado**
- ✅ Verificar se exibe o nome da carta (se identificado)
- ✅ Verificar se exibe a descrição detalhada
- ✅ Verificar se exibe preços (USD e BRL, se disponíveis)
- ✅ Testar botão "Escanear Nova Carta" (deve voltar à tela inicial)

**Passo 4: Tela de Histórico**
- ✅ Clicar na aba "Histórico" na barra inferior
- ✅ Verificar se as cartas escaneadas aparecem na lista
- ✅ Testar navegação entre as abas (Escanear ↔ Histórico)

#### 3. **Teste de Responsividade**
- ✅ Testar em diferentes tamanhos de tela
- ✅ Testar rotação da tela (portrait/landscape)
- ✅ Verificar se textos não ultrapassam os limites
- ✅ Verificar se botões permanecem acessíveis

#### 4. **Teste de Validação**
- ✅ Tentar enviar arquivo que não é imagem (deve dar erro)
- ✅ Tentar usar o app sem conexão com internet
- ✅ Verificar mensagens de erro (devem ser claras e em português)

#### 5. **Casos de Teste Específicos**

**Cartas Conhecidas para Testar:**
- Lightning Bolt
- Black Lotus
- Sol Ring
- Mana Crypt
- Counterspell

**Cenários de Teste:**
1. **Carta bem conhecida**: Deve retornar nome, descrição e preço
2. **Carta obscura**: Deve retornar pelo menos descrição
3. **Imagem de baixa qualidade**: Deve tentar processar ou dar erro claro
4. **Múltiplas cartas na imagem**: Deve tentar identificar ou dar feedback

### Resultados Esperados

#### ✅ **Sucesso Completo**
- Nome da carta identificado corretamente
- Descrição detalhada em português
- Preços em USD e BRL (quando disponível)
- Carta salva no histórico automaticamente

#### ⚠️ **Sucesso Parcial**
- Descrição detalhada da imagem
- Nome não identificado ou incerto
- Preços não disponíveis

#### ❌ **Erro Esperado**
- Mensagem de erro clara em português
- App não trava nem fecha
- Usuário pode tentar novamente

## 9. Status de Desenvolvimento

- ✅ **Estrutura base do projeto**: Implementada
- ✅ **Interface de usuário**: Todas as telas implementadas (Escanear, Resultado, Histórico)
- ✅ **Integração com IA**: Google Gemini funcionando
- ✅ **API externa**: Scryfall integrada
- ✅ **Fluxo principal**: Upload → Reconhecimento → Exibição
- ✅ **Histórico local**: Implementado e funcionando
- ✅ **Navegação**: Completa entre todas as telas
- ✅ **Validações**: Implementadas (verificação de imagem, tratamento de erros)
- ✅ **Layout responsivo**: Funcionando em múltiplas plataformas

## 10. Observações Técnicas

- O aplicativo funciona em múltiplas plataformas (Android, iOS, Linux, Web)
- Layout responsivo adaptado para diferentes tamanhos de tela
- Código organizado seguindo Clean Architecture
- Tratamento de erros implementado
- Documentação completa no código
