#!/bin/bash

# Script para iniciar o backend

echo "🚀 Iniciando Magic Scanner Backend..."

# Verifica se o ambiente virtual existe
if [ ! -d "venv" ]; then
    echo "📦 Criando ambiente virtual..."
    python3 -m venv venv
fi

# Ativa o ambiente virtual
echo "🔧 Ativando ambiente virtual..."
source venv/bin/activate

# Instala dependências
echo "📥 Instalando dependências..."
pip install -r requirements.txt

# Verifica se o arquivo .env existe
if [ ! -f ".env" ]; then
    echo "⚠️  Arquivo .env não encontrado!"
    echo "📝 Crie um arquivo .env com:"
    echo "   Gemini_API_KEY={colocar chave aqui}"
    echo "   PORT=3000"
    echo "   HOST=0.0.0.0"
    exit 1
fi

# Inicia o servidor
echo "✅ Iniciando servidor..."
python main.py

