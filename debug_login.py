#!/usr/bin/env python3
"""
Script para debug do login em produção
"""
import os
import sys
import django
from django.conf import settings

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
django.setup()

from django.test import Client
from django.urls import reverse
import traceback

def test_login_view():
    """Testar a view de login"""
    try:
        client = Client()
        
        # Testar GET
        print("=== TESTANDO GET /authentication/login/ ===")
        response = client.get('/authentication/login/')
        print(f"Status GET: {response.status_code}")
        if response.status_code != 200:
            print(f"Conteúdo GET: {response.content.decode()[:500]}")
        
        # Testar POST com dados inválidos
        print("\n=== TESTANDO POST /authentication/login/ ===")
        response = client.post('/authentication/login/', {
            'username': 'test',
            'password': 'test'
        })
        print(f"Status POST: {response.status_code}")
        if response.status_code != 200:
            print(f"Conteúdo POST: {response.content.decode()[:500]}")
            
    except Exception as e:
        print(f"ERRO: {e}")
        traceback.print_exc()

if __name__ == '__main__':
    test_login_view()
