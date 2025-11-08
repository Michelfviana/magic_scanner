# Magic Scanner Backend

Backend PoC para o aplicativo Magic Scanner, orquestrando chamadas para:
- OpenAI Vision API (identificação de cartas)
- Scryfall API (dados oficiais das cartas)
- APIs de preços (TCGPlayer, LigaMagic - em desenvolvimento)

## Instalação

1. Crie um ambiente virtual:
```bash
python -m venv venv
source venv/bin/activate  # No Windows: venv\Scripts\activate
```

2. Instale as dependências:
```bash
pip install -r requirements.txt
```

3. Configure as variáveis de ambiente:
```bash
# Crie o arquivo .env
echo "GEMINI_API_KEY=sua_chave_aqui" > .env
echo "PORT=3000" >> .env
echo "HOST=0.0.0.0" >> .env
```

**Para obter a chave do Gemini:**
1. Acesse: https://aistudio.google.com/apikey
2. Faça login com sua conta Google
3. Clique em "Create API Key"
4. Copie a chave e cole no arquivo .env

## Executar

```bash
python main.py
```

Ou com uvicorn diretamente:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 3000
```

O servidor estará disponível em `http://localhost:3000`

## Endpoints

### GET /
Retorna status da API

### GET /health
Health check

### POST /api/scan
Recebe uma imagem e retorna dados da carta identificada.

**Request:**
- Content-Type: multipart/form-data
- Body: arquivo de imagem

**Response:**
```json
{
  "id": "sol_ring_c21",
  "name": "Sol Ring",
  "edition": "Commander 2021",
  "officialImageUrl": "https://...",
  "description": "...",
  "rarity": "Uncommon",
  "prices": {
    "tcgplayer": 2.50,
    "ligamagic": 12.00
  },
  "scannedAt": null
}
```

## Próximos Passos

- [ ] Integrar com TCGPlayer API real
- [ ] Integrar com LigaMagic API
- [ ] Adicionar cache de resultados
- [ ] Implementar rate limiting
- [ ] Adicionar logging estruturado
- [ ] Configurar banco de dados para histórico

