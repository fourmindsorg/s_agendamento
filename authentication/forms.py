from django import forms
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
import re

class CustomUserCreationForm(UserCreationForm):
    """Form personalizado para criação de usuários"""
    email = forms.EmailField(required=True, widget=forms.EmailInput(attrs={
        'class': 'form-control',
        'placeholder': 'Digite seu email'
    }))
    first_name = forms.CharField(max_length=30, required=True, widget=forms.TextInput(attrs={
        'class': 'form-control',
        'placeholder': 'Digite seu nome'
    }))
    last_name = forms.CharField(max_length=30, required=True, widget=forms.TextInput(attrs={
        'class': 'form-control',
        'placeholder': 'Digite seu sobrenome'
    }))

    class Meta:
        model = User
        fields = ('username', 'first_name', 'last_name', 'email', 'password1', 'password2')
        widgets = {
            'username': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Digite seu usuário'
            }),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['password1'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Digite sua senha'
        })
        self.fields['password2'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Confirme sua senha'
        })

    def clean_username(self):
        """Validação personalizada para username"""
        username = self.cleaned_data.get('username')
        if username:
            # Verificar se username já existe
            if User.objects.filter(username=username).exists():
                raise ValidationError('Este nome de usuário já está em uso. Escolha outro.')
            
            # Verificar comprimento mínimo
            if len(username) < 3:
                raise ValidationError('O nome de usuário deve ter pelo menos 3 caracteres.')
            
            # Verificar caracteres permitidos
            if not re.match(r'^[a-zA-Z0-9_]+$', username):
                raise ValidationError('O nome de usuário pode conter apenas letras, números e underscore (_).')
        
        return username

    def clean_email(self):
        """Validação personalizada para email"""
        email = self.cleaned_data.get('email')
        if email:
            # Verificar se email já existe
            if User.objects.filter(email=email).exists():
                raise ValidationError('Este email já está cadastrado. Use outro email ou faça login.')
            
            # Verificar formato do email
            email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
            if not re.match(email_regex, email):
                raise ValidationError('Digite um email válido.')
        
        return email

    def clean_first_name(self):
        """Validação personalizada para primeiro nome"""
        first_name = self.cleaned_data.get('first_name')
        if first_name:
            # Verificar comprimento mínimo
            if len(first_name.strip()) < 2:
                raise ValidationError('O nome deve ter pelo menos 2 caracteres.')
            
            # Verificar se contém apenas letras e espaços
            if not re.match(r'^[a-zA-ZÀ-ÿ\s]+$', first_name):
                raise ValidationError('O nome pode conter apenas letras e espaços.')
        
        return first_name.strip()

    def clean_last_name(self):
        """Validação personalizada para sobrenome"""
        last_name = self.cleaned_data.get('last_name')
        if last_name:
            # Verificar comprimento mínimo
            if len(last_name.strip()) < 2:
                raise ValidationError('O sobrenome deve ter pelo menos 2 caracteres.')
            
            # Verificar se contém apenas letras e espaços
            if not re.match(r'^[a-zA-ZÀ-ÿ\s]+$', last_name):
                raise ValidationError('O sobrenome pode conter apenas letras e espaços.')
        
        return last_name.strip()

    def clean_password2(self):
        """Validação personalizada para confirmação de senha"""
        password1 = self.cleaned_data.get('password1')
        password2 = self.cleaned_data.get('password2')
        
        if password1 and password2:
            if password1 != password2:
                raise ValidationError('As senhas não coincidem.')
            
            # Verificar força da senha
            if len(password1) < 8:
                raise ValidationError('A senha deve ter pelo menos 8 caracteres.')
            
            # Verificar se contém pelo menos uma letra e um número
            if not re.search(r'[A-Za-z]', password1):
                raise ValidationError('A senha deve conter pelo menos uma letra.')
            
            if not re.search(r'[0-9]', password1):
                raise ValidationError('A senha deve conter pelo menos um número.')
        
        return password2

    def clean(self):
        """Validação geral do formulário"""
        cleaned_data = super().clean()
        
        # Verificar se todos os campos obrigatórios estão preenchidos
        required_fields = ['username', 'email', 'first_name', 'last_name', 'password1', 'password2']
        for field in required_fields:
            if not cleaned_data.get(field):
                raise ValidationError(f'O campo {field} é obrigatório.')
        
        return cleaned_data

    def save(self, commit=True):
        """Salva o usuário com validações adicionais"""
        try:
            user = super().save(commit=False)
            user.email = self.cleaned_data['email']
            user.first_name = self.cleaned_data['first_name']
            user.last_name = self.cleaned_data['last_name']
            user.is_active = True  # Ativar usuário por padrão
            
            if commit:
                user.save()
            return user
        except Exception as e:
            raise ValidationError(f'Erro ao salvar usuário: {str(e)}')


class CustomUserChangeForm(UserChangeForm):
    """Form personalizado para edição de usuários"""
    password = None  # Remove o campo de senha
    
    class Meta:
        model = User
        fields = ('username', 'first_name', 'last_name', 'email', 'is_active', 'is_staff')
        widgets = {
            'username': forms.TextInput(attrs={'class': 'form-control'}),
            'first_name': forms.TextInput(attrs={'class': 'form-control'}),
            'last_name': forms.TextInput(attrs={'class': 'form-control'}),
            'email': forms.EmailInput(attrs={'class': 'form-control'}),
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'is_staff': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }