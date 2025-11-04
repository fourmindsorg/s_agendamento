"""
Utilitários para geração de QR Codes PIX
"""

import base64
import io
from typing import Optional


def generate_qr_code_from_payload(payload: str, size: int = 10) -> Optional[str]:
    """
    Gera uma imagem QR Code (base64) a partir de um payload PIX.
    
    Args:
        payload: String com o payload PIX
        size: Tamanho do QR Code (padrão 10)
    
    Returns:
        String base64 da imagem do QR Code ou None se houver erro
    """
    if not payload or not payload.strip():
        import logging
        logger = logging.getLogger(__name__)
        logger.warning("Payload vazio ou None, não é possível gerar QR Code")
        return None
    
    try:
        import qrcode
        from PIL import Image
        
        # Limpar payload (remover espaços extras)
        payload_clean = payload.strip()
        
        # Criar QR Code com configurações otimizadas para PIX
        qr = qrcode.QRCode(
            version=None,  # Auto-detect version
            error_correction=qrcode.constants.ERROR_CORRECT_M,  # M para melhor correção
            box_size=size,
            border=4,
        )
        qr.add_data(payload_clean)
        qr.make(fit=True)
        
        # Criar imagem com alta qualidade
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Converter para base64
        buffer = io.BytesIO()
        img.save(buffer, format='PNG', optimize=True)
        img_str = base64.b64encode(buffer.getvalue()).decode()
        
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"QR Code gerado com sucesso. Payload tamanho: {len(payload_clean)}, Imagem base64 tamanho: {len(img_str)}")
        
        return img_str
        
    except ImportError as e:
        # Se qrcode não estiver instalado, retornar None
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Biblioteca qrcode não instalada: {e}")
        logger.error("Execute: pip install qrcode[pil]")
        return None
    except Exception as e:
        # Log do erro mas não falhar
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Erro ao gerar QR Code: {e}", exc_info=True)
        return None

