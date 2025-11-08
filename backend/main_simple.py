#!/usr/bin/env python3
"""
Backend Simplificado Magic Scanner
Versão otimizada para desenvolvimento local
"""

import os
import io
import asyncio
import json
from concurrent.futures import ThreadPoolExecutor
from typing import Optional

# Try importing modules with fallbacks
try:
    from fastapi import FastAPI, File, UploadFile, HTTPException
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse
except ImportError:
    print("❌ FastAPI não instalado. Execute: pip install fastapi uvicorn")
    exit(1)

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print("⚠️  python-dotenv não instalado. Usando variáveis de ambiente do sistema.")

try:
    import google.generativeai as genai
    from PIL import Image
except ImportError:
    print("❌ Dependências não instaladas. Execute:")
    print("pip install google-generativeai pillow")
    exit(1)

try:
    import httpx
except ImportError:
    print("⚠️  httpx não instalado. Funcionalidade Scryfall desabilitada.")
    httpx = None

app = FastAPI(title="Magic Scanner API - Otimizado", version="2.0.0")

# CORS para Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuração Gemini
gemini_api_key = os.getenv("GEMINI_API_KEY")
if not gemini_api_key:
    print("❌ GEMINI_API_KEY não configurada!")
    print("Configure no arquivo .env ou export GEMINI_API_KEY=sua_chave")
    exit(1)

genai.configure(api_key=gemini_api_key)

# Configuração otimizada do modelo
generation_config = {
    "temperature": 0.1,
    "top_p": 0.8,
    "top_k": 40,
    "max_output_tokens": 150,  # Resposta mais curta = mais rápida
}

# Modelo mais rápido
model = genai.GenerativeModel(
    'gemini-1.5-flash',
    generation_config=generation_config
)

def preprocess_image(image_data: bytes) -> Image.Image:
    """Pré-processa imagem para velocidade máxima"""
    try:
        image = Image.open(io.BytesIO(image_data))
        
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Redimensiona agressivamente para velocidade
        max_size = 512  # Bem pequeno para ser rápido
        if max(image.size) > max_size:
            ratio = max_size / max(image.size)
            new_size = (int(image.width * ratio), int(image.height * ratio))
            image = image.resize(new_size, Image.Resampling.LANCZOS)
            print(f"📐 Redimensionado para {new_size}")
        
        return image
    except Exception as e:
        raise ValueError(f"Erro ao processar imagem: {str(e)}")

def extract_card_name(text: str) -> Optional[str]:
    """Extrai nome da carta de forma simples"""
    import re
    
    # Padrões simples para extrair nome
    patterns = [
        r'NOME:\s*([^\n]+)',
        r'Nome:\s*([^\n]+)',  
        r'Card:\s*([^\n]+)',
        r'^([A-Za-z][A-Za-z0-9\s\-\']+)',  # Primeira linha que parece nome
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
        if match:
            name = match.group(1).strip()
            if len(name) > 2 and len(name) < 50:
                return name
    
    return None

async def describe_card_fast(image_data: bytes) -> dict:
    """Versão ultra-rápida para identificar carta"""
    try:
        image = preprocess_image(image_data)
        
        # Prompt super simples para velocidade máxima
        prompt = "Nome desta carta Magic: The Gathering?"
        
        def process_sync():
            return model.generate_content([prompt, image])
        
        # Timeout de 45 segundos
        with ThreadPoolExecutor() as executor:
            future = executor.submit(process_sync)
            try:
                response = future.result(timeout=45)
            except TimeoutError:
                raise HTTPException(408, "Timeout: Tente uma imagem mais simples")
        
        # Extrai resposta
        description = ""
        if hasattr(response, 'text') and response.text:
            description = response.text.strip()
        elif hasattr(response, 'candidates') and response.candidates:
            if response.candidates[0].content.parts:
                description = response.candidates[0].content.parts[0].text.strip()
        
        if not description:
            raise ValueError("Gemini não retornou resposta")
        
        # Tenta extrair nome
        card_name = extract_card_name(description)
        
        return {
            "success": True,
            "description": description,
            "card_name": card_name,
            "processing_mode": "fast"
        }
        
    except Exception as e:
        raise HTTPException(500, f"Erro: {str(e)}")

@app.get("/")
async def root():
    return {"message": "Magic Scanner API Otimizado", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "version": "2.0.0-optimized"}

@app.post("/api/scan")
async def scan_card(file: UploadFile = File(...)):
    """Endpoint otimizado para velocidade máxima"""
    try:
        # Validações rápidas
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(400, "Arquivo deve ser uma imagem")
        
        image_data = await file.read()
        if len(image_data) == 0:
            raise HTTPException(400, "Imagem vazia")
        
        if len(image_data) > 8 * 1024 * 1024:  # 8MB max
            raise HTTPException(400, "Imagem muito grande (max 8MB)")
        
        print(f"🔍 Processando {len(image_data)} bytes...")
        
        # Processa com Gemini otimizado
        result = await describe_card_fast(image_data)
        
        print(f"✅ Processado: {result.get('card_name', 'Nome não identificado')}")
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Erro: {e}")
        raise HTTPException(500, f"Erro interno: {str(e)}")

@app.post("/api/debug-image")
async def debug_image(file: UploadFile = File(...)):
    """Debug rápido da imagem"""
    try:
        image_data = await file.read()
        
        info = {
            "filename": file.filename,
            "content_type": file.content_type,
            "size_mb": round(len(image_data) / (1024*1024), 2),
            "size_bytes": len(image_data)
        }
        
        # Testa se consegue abrir
        try:
            image = Image.open(io.BytesIO(image_data))
            info["image"] = {
                "format": image.format,
                "size": image.size,
                "mode": image.mode
            }
            info["status"] = "✅ Imagem válida"
        except Exception as e:
            info["status"] = f"❌ Erro: {e}"
        
        return {"debug_info": info}
        
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    try:
        import uvicorn
        print("🚀 Iniciando Magic Scanner Backend Otimizado...")
        print("📡 Acesse: http://localhost:8000")
        print("📋 Docs: http://localhost:8000/docs")
        uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
    except ImportError:
        print("❌ uvicorn não instalado. Execute: pip install uvicorn")
        print("💡 Ou execute: python -m uvicorn main_simple:app --reload")