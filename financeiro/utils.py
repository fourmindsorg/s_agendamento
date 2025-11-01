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
    try:
        import qrcode
        from PIL import Image
        
        # Criar QR Code
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=size,
            border=4,
        )
        qr.add_data(payload)
        qr.make(fit=True)
        
        # Criar imagem
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Converter para base64
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        img_str = base64.b64encode(buffer.getvalue()).decode()
        
        return img_str
        
    except ImportError:
        # Se qrcode não estiver instalado, retornar None
        return None
    except Exception as e:
        # Log do erro mas não falhar
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Erro ao gerar QR Code: {e}")
        return None

