"""
Backend PoC para Magic Scanner
Orquestra chamadas para Google Gemini Pro, Scryfall e APIs de preços
"""

import os
import asyncio
from typing import Optional
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import httpx
import google.generativeai as genai
from PIL import Image
import io

# Carrega variáveis de ambiente
load_dotenv()

app = FastAPI(title="Magic Scanner API", version="1.0.0")

# CORS para permitir requisições do Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Em produção, especificar domínios
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configura Gemini
gemini_api_key = os.getenv("GEMINI_API_KEY")
if not gemini_api_key:
    raise ValueError("GEMINI_API_KEY não configurada no arquivo .env")

genai.configure(api_key=gemini_api_key)

# Configuração do modelo para velocidade otimizada
generation_config = {
    "temperature": 0.1,
    "top_p": 0.8,
    "top_k": 40,
    "max_output_tokens": 200,  # Limita resposta para ser mais rápida
}

safety_settings = [
    {
        "category": "HARM_CATEGORY_HARASSMENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
    },
    {
        "category": "HARM_CATEGORY_HATE_SPEECH",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
    },
    {
        "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
    },
    {
        "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
    }
]

# Modelo Gemini otimizado para velocidade
model = genai.GenerativeModel(
    'gemini-2.5-flash',  # Versão mais rápida
    generation_config=generation_config,
    safety_settings=safety_settings
)

# Base URL da Scryfall API
SCRYFALL_API = "https://api.scryfall.com"



# Função melhorada: pré-processar e descrever a imagem
def preprocess_image(image_data: bytes) -> Image.Image:
    """
    Pré-processa a imagem para melhorar a qualidade do reconhecimento
    """
    try:
        image = Image.open(io.BytesIO(image_data))
        
        # Converte para RGB se necessário
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Redimensiona para tamanho otimizado (mais agressivo para melhor performance)
        target_size = 768  # Menor para processar mais rápido
        if max(image.size) > target_size:
            ratio = target_size / max(image.size)
            new_size = (int(image.width * ratio), int(image.height * ratio))
            image = image.resize(new_size, Image.Resampling.LANCZOS)
            print(f"📐 Imagem redimensionada de {image_data.__len__()} bytes para {new_size}")
        
        # Aplica compressão adicional se necessário
        if len(image_data) > 2 * 1024 * 1024:  # > 2MB
            output = io.BytesIO()
            image.save(output, format='JPEG', quality=85, optimize=True)
            compressed_data = output.getvalue()
            print(f"🗜️ Imagem comprimida de {len(image_data)} para {len(compressed_data)} bytes")
            image = Image.open(io.BytesIO(compressed_data))
        
        return image
    except Exception as e:
        raise ValueError(f"Erro ao processar imagem: {str(e)}")


def extract_card_name_advanced(description: str) -> str:
    """
    Extrai o nome da carta usando múltiplas estratégias
    """
    import re
    
    # Estratégia 1: Procura por padrões comuns
    patterns = [
        r"[Nn]ome[:\s]*([A-Za-zÀ-ÿ0-9 ''\-,]+?)(?:\n|\.|\s*-|\s*\()",
        r"[Cc]arta[:\s]*([A-Za-zÀ-ÿ0-9 ''\-,]+?)(?:\n|\.|\s*-|\s*\()",
        r"^([A-Za-zÀ-ÿ0-9 ''\-,]+?)(?:\s*-|\s*é|\s*\()",
        r"\"([A-Za-zÀ-ÿ0-9 ''\-,]+)\"",
        r"'([A-Za-zÀ-ÿ0-9 ''\-,]+)'",
    ]
    
    for pattern in patterns:
        match = re.search(pattern, description, re.MULTILINE)
        if match:
            name = match.group(1).strip()
            # Remove palavras comuns que não são nomes de carta
            exclude_words = {'da', 'de', 'do', 'das', 'dos', 'uma', 'um', 'esta', 'este', 'essa', 'esse', 'tipo', 'custo', 'carta', 'criatura'}
            if len(name) > 2 and name.lower() not in exclude_words:
                return name
    
    # Estratégia 2: Procura por linhas que podem ser nomes
    lines = description.split('\n')
    for line in lines[:5]:  # Verifica primeiras 5 linhas
        line = line.strip()
        if (len(line) > 3 and len(line) < 40 and 
            not line.lower().startswith(('esta', 'essa', 'a carta', 'tipo', 'custo')) and
            re.match(r'^[A-Za-zÀ-ÿ0-9 ''\-,]+$', line)):
            return line
    
    return None


async def describe_card_with_gemini(image_data: bytes) -> dict:
    """
    Usa Google Gemini Pro Vision para descrever a imagem e tentar identificar o nome da carta
    """
    try:
        # Pré-processa a imagem
        image = preprocess_image(image_data)
        
        # Prompt otimizado para velocidade e precisão
        prompt = (
            "Esta é uma carta de Magic: The Gathering. Identifique rapidamente:\n\n"
            "NOME: [nome da carta - MAIS IMPORTANTE]\n"
            "DESCRIÇÃO: [breve descrição da carta]\n\n"
            "Foque APENAS no nome da carta. Se não conseguir ler o nome completo, "
            "tente ler pelo menos parte dele. Seja rápido e direto."
        )
        
        # Processamento com timeout
        import asyncio
        from concurrent.futures import ThreadPoolExecutor
        
        def process_with_gemini():
            """Função que roda o Gemini de forma síncrona"""
            return model.generate_content([prompt, image])
        
        # Executa com timeout de 90 segundos
        try:
            with ThreadPoolExecutor() as executor:
                future = executor.submit(process_with_gemini)
                try:
                    response = future.result(timeout=90)  # 90 segundos max
                except TimeoutError:
                    raise HTTPException(
                        status_code=408, 
                        detail="Timeout: Imagem muito complexa. Tente uma imagem mais simples ou com melhor qualidade."
                    )
                
            # Extrai texto da resposta
            description = None
            if hasattr(response, 'text') and response.text:
                description = response.text.strip()
            elif hasattr(response, 'candidates') and response.candidates:
                candidate = response.candidates[0]
                if hasattr(candidate, 'content') and candidate.content.parts:
                    description = candidate.content.parts[0].text.strip()
            
            if not description:
                raise ValueError("Resposta do Gemini vazia")
            
            # Extrai nome usando função avançada
            card_name = extract_card_name_advanced(description)
            
            return {
                "description": description,
                "card_name": card_name,
                "processing_time": "< 90s"
            }
                
        except HTTPException:
            raise  # Re-propaga HTTPExceptions
        except Exception as e:
            print(f"❌ Erro no processamento: {str(e)}")
            # Fallback: tenta uma vez mais com prompt simplificado
            try:
                simple_prompt = "Nome desta carta Magic:"
                response = model.generate_content([simple_prompt, image])
                description = response.text if hasattr(response, 'text') else "Processamento parcial"
                card_name = extract_card_name_advanced(description)
                return {
                    "description": description,
                    "card_name": card_name,
                    "processing_time": "fallback"
                }
            except:
                raise e
    
    except Exception as e:
        print(f"❌ Erro detalhado no Gemini: {type(e).__name__}: {str(e)}")
        
        # Verifica tipos específicos de erro
        error_msg = str(e).lower()
        if "quota" in error_msg or "limit" in error_msg:
            raise HTTPException(status_code=429, detail="Limite de requisições excedido. Tente novamente em alguns minutos.")
        elif "safety" in error_msg or "blocked" in error_msg:
            raise HTTPException(status_code=400, detail="Imagem bloqueada por filtros de segurança. Tente uma imagem diferente.")
        elif "invalid" in error_msg and "image" in error_msg:
            raise HTTPException(status_code=400, detail="Formato de imagem inválido. Use JPG, PNG ou WebP.")
        else:
            raise HTTPException(status_code=500, detail=f"Erro ao processar imagem: {str(e)}")


async def get_card_from_scryfall(card_name: str) -> dict:
    """
    Busca informações da carta na Scryfall API
    """
    try:
        async with httpx.AsyncClient() as client:
            # Busca exata por nome
            response = await client.get(
                f"{SCRYFALL_API}/cards/named",
                params={"exact": card_name}
            )
            
            if response.status_code == 404:
                # Tenta busca fuzzy se não encontrar exato
                response = await client.get(
                    f"{SCRYFALL_API}/cards/named",
                    params={"fuzzy": card_name}
                )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=404,
                    detail=f"Carta '{card_name}' não encontrada na Scryfall"
                )
            
            return response.json()
    except httpx.HTTPError as e:
        raise HTTPException(status_code=500, detail=f"Erro ao buscar na Scryfall: {str(e)}")


async def get_card_prices(card_name: str, set_code: Optional[str] = None) -> dict:
    """
    Busca preços da carta (mock inicial - será substituído por APIs reais)
    """
    # TODO: Integrar com TCGPlayer API e LigaMagic API
    # Por enquanto, retorna valores mock baseados na raridade
    
    # Valores mock (em produção, buscar de APIs reais)
    prices = {
        "tcgplayer": 0.0,
        "ligamagic": 0.0
    }
    
    # Tenta buscar preços da Scryfall (algumas cartas têm preços)
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{SCRYFALL_API}/cards/named",
                params={"exact": card_name} if not set_code else {"exact": card_name, "set": set_code}
            )
            if response.status_code == 200:
                data = response.json()
                # Scryfall tem preços em USD
                if "prices" in data and data["prices"].get("usd"):
                    prices["tcgplayer"] = float(data["prices"]["usd"])
                    # Converte para BRL (mock - taxa fixa)
                    prices["ligamagic"] = prices["tcgplayer"] * 5.0
    
    except Exception:
        pass  # Se falhar, mantém valores mock
    
    return prices


def format_card_response(scryfall_data: dict, prices: dict) -> dict:
    """
    Formata a resposta no formato esperado pelo app Flutter com informações expandidas
    """
    # Pega a melhor imagem disponível
    image_url = (
        scryfall_data.get("image_uris", {}).get("normal") or
        scryfall_data.get("image_uris", {}).get("large") or
        scryfall_data.get("card_faces", [{}])[0].get("image_uris", {}).get("normal") or
        ""
    )
    
    # Pega também outras versões da imagem
    image_uris = scryfall_data.get("image_uris", {})
    art_crop_url = image_uris.get("art_crop", "")
    border_crop_url = image_uris.get("border_crop", "")
    
    # Determina raridade
    rarity = scryfall_data.get("rarity", "common").capitalize()
    
    # Gera ID único baseado no nome e set
    card_id = f"{scryfall_data.get('name', '').lower().replace(' ', '_')}_{scryfall_data.get('set', '').lower()}"
    
    # Extrai informações adicionais
    type_line = scryfall_data.get("type_line", "")
    mana_cost = scryfall_data.get("mana_cost", "")
    cmc = scryfall_data.get("cmc", 0)
    power = scryfall_data.get("power")
    toughness = scryfall_data.get("toughness")
    colors = scryfall_data.get("colors", [])
    color_identity = scryfall_data.get("color_identity", [])
    set_code = scryfall_data.get("set", "")
    set_name = scryfall_data.get("set_name", "")
    collector_number = scryfall_data.get("collector_number", "")
    artist = scryfall_data.get("artist", "")
    keywords = scryfall_data.get("keywords", [])
    
    # Informações adicionais detalhadas
    legalities = scryfall_data.get("legalities", {})
    flavor_text = scryfall_data.get("flavor_text", "")
    released_at = scryfall_data.get("released_at", "")
    rarity_code = scryfall_data.get("rarity", "common")
    card_layout = scryfall_data.get("layout", "normal")
    
    # Informações de jogo
    edhrec_rank = scryfall_data.get("edhrec_rank")
    penny_rank = scryfall_data.get("penny_rank")
    
    # URLs relacionadas
    scryfall_uri = scryfall_data.get("scryfall_uri", "")
    tcgplayer_id = scryfall_data.get("tcgplayer_id")
    
    # Para cartas de dupla face, pega as informações da primeira face
    oracle_text = scryfall_data.get("oracle_text", "")
    if not type_line and "card_faces" in scryfall_data and scryfall_data["card_faces"]:
        first_face = scryfall_data["card_faces"][0]
        type_line = first_face.get("type_line", "")
        mana_cost = first_face.get("mana_cost", "")
        power = first_face.get("power")
        toughness = first_face.get("toughness")
        oracle_text = first_face.get("oracle_text", oracle_text)
    
    return {
        "id": card_id,
        "name": scryfall_data.get("name", ""),
        "edition": set_name,
        "officialImageUrl": image_url,
        "artCropUrl": art_crop_url,
        "borderCropUrl": border_crop_url,
        "description": oracle_text,
        "flavorText": flavor_text,
        "rarity": rarity,
        "rarityCode": rarity_code,
        "typeLine": type_line,
        "manaCost": mana_cost,
        "cmc": int(cmc),
        "power": power,
        "toughness": toughness,
        "colors": colors,
        "colorIdentity": color_identity,
        "setCode": set_code,
        "setName": set_name,
        "collectorNumber": collector_number,
        "artist": artist,
        "keywords": keywords,
        "layout": card_layout,
        "releasedAt": released_at,
        "legalities": legalities,
        "edhrecRank": edhrec_rank,
        "pennyRank": penny_rank,
        "scryfallUri": scryfall_uri,
        "tcgplayerId": tcgplayer_id,
        "prices": prices,
        "scannedAt": None  # Será preenchido pelo app
    }


@app.get("/")
async def root():
    return {"message": "Magic Scanner API", "status": "running"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.get("/test/gemini")
async def test_gemini():
    """
    Endpoint de teste para verificar se o Gemini está funcionando
    """
    try:
        # Testa com uma imagem simples (pode ser qualquer coisa)
        test_prompt = "Diga apenas 'OK' se você está funcionando."
        response = model.generate_content(test_prompt)
        
        result = response.text if hasattr(response, 'text') else "Resposta recebida"
        return {"status": "success", "message": "Gemini está funcionando", "response": result}
    except Exception as e:
        import traceback
        return {
            "status": "error",
            "message": str(e),
            "traceback": traceback.format_exc()
        }


@app.post("/api/debug-image")
async def debug_image(file: UploadFile = File(...)):
    """
    Endpoint para debug: analisa problemas com imagens específicas
    """
    try:
        image_data = await file.read()
        
        # Informações básicas
        info = {
            "file_info": {
                "filename": file.filename,
                "content_type": file.content_type,
                "size_bytes": len(image_data),
                "size_mb": round(len(image_data) / (1024*1024), 2)
            },
            "validations": {}
        }
        
        # Validação 1: Tipo de arquivo
        if file.content_type and file.content_type.startswith("image/"):
            info["validations"]["content_type"] = "✅ OK"
        else:
            info["validations"]["content_type"] = f"❌ Inválido: {file.content_type}"
        
        # Validação 2: Tamanho
        if len(image_data) > 0:
            if len(image_data) <= 10 * 1024 * 1024:  # 10MB
                info["validations"]["size"] = "✅ OK"
            else:
                info["validations"]["size"] = "⚠️  Muito grande (>10MB)"
        else:
            info["validations"]["size"] = "❌ Arquivo vazio"
        
        # Validação 3: Formato da imagem
        try:
            from PIL import Image
            image = Image.open(io.BytesIO(image_data))
            info["image_details"] = {
                "format": image.format,
                "mode": image.mode,
                "size": image.size,
                "has_transparency": image.mode in ('RGBA', 'LA', 'P')
            }
            info["validations"]["format"] = "✅ Imagem válida"
        except Exception as e:
            info["validations"]["format"] = f"❌ Erro: {str(e)}"
            return {"status": "error", "info": info}
        
        # Validação 4: Teste básico com Gemini
        try:
            processed_image = preprocess_image(image_data)
            simple_prompt = "Descreva brevemente o que você vê nesta imagem."
            response = model.generate_content([simple_prompt, processed_image])
            
            if hasattr(response, 'text') and response.text:
                info["gemini_test"] = {
                    "status": "✅ Sucesso",
                    "preview": response.text[:200] + "..." if len(response.text) > 200 else response.text
                }
            else:
                info["gemini_test"] = {"status": "❌ Resposta vazia"}
        except Exception as e:
            info["gemini_test"] = {"status": f"❌ Erro: {str(e)}"}
        
        return {"status": "success", "debug_info": info}
        
    except Exception as e:
        return {
            "status": "error", 
            "message": str(e),
            "type": type(e).__name__
        }



@app.post("/api/scan")
async def scan_card(file: UploadFile = File(...)):
    """
    Endpoint melhorado: recebe imagem, valida, processa e busca dados da carta
    """
    try:
        # Validação básica
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Arquivo deve ser uma imagem (JPG, PNG, WebP)")
        
        image_data = await file.read()
        if len(image_data) == 0:
            raise HTTPException(status_code=400, detail="Imagem vazia")
        
        # Validação de tamanho (máximo 10MB)
        if len(image_data) > 10 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="Imagem muito grande. Máximo 10MB")

        print(f"🔍 Processando carta com Gemini Vision...")
        print(f"📏 Tamanho: {len(image_data)} bytes ({len(image_data)/1024:.1f}KB)")
        print(f"📄 Tipo: {file.content_type}")
        
        # Processa com Gemini
        try:
            gemini_result = await describe_card_with_gemini(image_data)
            description = gemini_result["description"]
            card_name = gemini_result["card_name"]
            attempt = gemini_result.get("attempt", 1)
            
            print(f"✅ Descrição obtida (tentativa {attempt})")
            if card_name:
                print(f"🎯 Nome extraído: '{card_name}'")
            else:
                print(f"⚠️  Nome não identificado automaticamente")
                
        except HTTPException as he:
            # Re-propaga HTTPExceptions (já têm mensagens adequadas)
            raise he
        except Exception as e:
            print(f"❌ Erro na descrição: {type(e).__name__}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Erro ao processar imagem: {str(e)}")

        # Busca dados adicionais se nome foi encontrado
        scryfall_data = None
        prices = None
        
        if card_name:
            print(f"📚 Buscando '{card_name}' na Scryfall...")
            try:
                scryfall_data = await get_card_from_scryfall(card_name)
                print(f"✅ Carta encontrada: {scryfall_data.get('name', 'N/A')}")
                
                # Busca preços
                set_code = scryfall_data.get("set")
                prices = await get_card_prices(card_name, set_code)
                print(f"💰 Preços: TCG=${prices.get('tcgplayer', 0):.2f}")
                
            except HTTPException as he:
                if he.status_code == 404:
                    print(f"🔍 Carta '{card_name}' não encontrada na Scryfall")
                else:
                    print(f"⚠️  Erro ao buscar dados: {he.detail}")
            except Exception as e:
                print(f"⚠️  Erro inesperado: {type(e).__name__}: {str(e)}")

        # Monta resposta final
        response = {
            "success": True,
            "description": description,
            "card_name": card_name,
            "processing_info": {
                "file_size": len(image_data),
                "content_type": file.content_type,
                "gemini_attempts": attempt
            }
        }
        
        if scryfall_data:
            response["card_data"] = format_card_response(scryfall_data, prices or {})
            response["data_source"] = "scryfall"
        else:
            response["data_source"] = "gemini_only"
            
        return response

    except HTTPException as he:
        # Re-propaga HTTPExceptions
        raise he
    except Exception as e:
        # Captura erros não tratados
        import traceback
        error_trace = traceback.format_exc()
        error_type = type(e).__name__
        error_msg = str(e)
        
        print(f"❌ ERRO CRÍTICO ({error_type}):")
        print(error_trace)
        
        # Mensagens de erro específicas
        if "API key" in error_msg or "authentication" in error_msg.lower():
            detail = "Erro de autenticação com Gemini. Verifique a configuração da API."
        elif "connection" in error_msg.lower() or "network" in error_msg.lower():
            detail = "Erro de conexão. Verifique sua internet e tente novamente."
        elif "timeout" in error_msg.lower():
            detail = "Timeout na requisição. Tente com uma imagem menor."
        elif "memory" in error_msg.lower() or "size" in error_msg.lower():
            detail = "Imagem muito grande para processar. Use uma imagem menor."
        else:
            detail = f"Erro interno do servidor: {error_msg}"
            
        raise HTTPException(status_code=500, detail=detail)


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run(app, host=host, port=port)

