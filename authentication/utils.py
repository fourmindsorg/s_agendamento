try:
    from .utils import get_client_ip, get_user_agent
except ImportError:
    def get_client_ip(request):
        """Obtém IP do cliente considerando cabeçalhos de proxy."""
        if not request:
            return None
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            return x_forwarded_for.split(",")[0].strip()
        return request.META.get("REMOTE_ADDR")


    def get_user_agent(request):
        """Retorna user agent limitado a 512 caracteres."""
        if not request:
            return ""
        return (request.META.get("HTTP_USER_AGENT") or "")[:512]

