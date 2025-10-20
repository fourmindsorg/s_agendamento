from django import forms
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
import re


class CustomUserCreationForm(UserCreationForm):
    """Form personalizado para criação de usuários"""

    email = forms.EmailField(
        required=True,
        widget=forms.EmailInput(
            attrs={"class": "form-control", "placeholder": "Digite seu email"}
        ),
    )
    first_name = forms.CharField(
        max_length=30,
        required=True,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "Digite seu nome"}
        ),
    )
    last_name = forms.CharField(
        max_length=30,
        required=True,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "Digite seu sobrenome"}
        ),
    )

    class Meta:
        model = User
        fields = (
            "username",
            "first_name",
            "last_name",
            "email",
            "password1",
            "password2",
        )
        widgets = {
            "username": forms.TextInput(
                attrs={"class": "form-control", "placeholder": "Digite seu usuário"}
            ),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["password1"].widget.attrs.update(
            {"class": "form-control", "placeholder": "Digite sua senha"}
        )
        self.fields["password2"].widget.attrs.update(
            {"class": "form-control", "placeholder": "Confirme sua senha"}
        )

    def clean_username(self):
        """Validação personalizada para username"""
        username = self.cleaned_data.get("username")
        if username:
            # Verificar se username já existe
            if User.objects.filter(username=username).exists():
                raise ValidationError(
                    "Este nome de usuário já está em uso. Escolha outro."
                )

            # Verificar comprimento mínimo
            if len(username) < 3:
                raise ValidationError(
                    "O nome de usuário deve ter pelo menos 3 caracteres."
                )

            # Verificar caracteres permitidos
            if not re.match(r"^[a-zA-Z0-9_]+$", username):
                raise ValidationError(
                    "O nome de usuário pode conter apenas letras, números e underscore (_)."
                )

        return username

    def clean_email(self):
        """Validação personalizada para email"""
        email = self.cleaned_data.get("email")
        if email:
            # Verificar se email já existe
            if User.objects.filter(email=email).exists():
                raise ValidationError(
                    "Este email já está cadastrado. Use outro email ou faça login."
                )

            # Verificar formato do email
            email_regex = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
            if not re.match(email_regex, email):
                raise ValidationError("Digite um email válido.")

        return email

    def clean_first_name(self):
        """Validação personalizada para primeiro nome"""
        first_name = self.cleaned_data.get("first_name")
        if first_name:
            # Verificar comprimento mínimo
            if len(first_name.strip()) < 2:
                raise ValidationError("O nome deve ter pelo menos 2 caracteres.")

            # Verificar se contém apenas letras e espaços
            if not re.match(r"^[a-zA-ZÀ-ÿ\s]+$", first_name):
                raise ValidationError("O nome pode conter apenas letras e espaços.")

        return first_name.strip()

    def clean_last_name(self):
        """Validação personalizada para sobrenome"""
        last_name = self.cleaned_data.get("last_name")
        if last_name:
            # Verificar comprimento mínimo
            if len(last_name.strip()) < 2:
                raise ValidationError("O sobrenome deve ter pelo menos 2 caracteres.")

            # Verificar se contém apenas letras e espaços
            if not re.match(r"^[a-zA-ZÀ-ÿ\s]+$", last_name):
                raise ValidationError(
                    "O sobrenome pode conter apenas letras e espaços."
                )

        return last_name.strip()

    def clean_password2(self):
        """Validação personalizada para confirmação de senha"""
        password1 = self.cleaned_data.get("password1")
        password2 = self.cleaned_data.get("password2")

        if password1 and password2:
            if password1 != password2:
                raise ValidationError("As senhas não coincidem.")

            # Verificar força da senha
            if len(password1) < 8:
                raise ValidationError("A senha deve ter pelo menos 8 caracteres.")

            # Verificar se contém pelo menos uma letra e um número
            if not re.search(r"[A-Za-z]", password1):
                raise ValidationError("A senha deve conter pelo menos uma letra.")

            if not re.search(r"[0-9]", password1):
                raise ValidationError("A senha deve conter pelo menos um número.")

        return password2

    def clean(self):
        """Validação geral do formulário"""
        cleaned_data = super().clean()

        # Verificar se todos os campos obrigatórios estão preenchidos
        required_fields = [
            "username",
            "email",
            "first_name",
            "last_name",
            "password1",
            "password2",
        ]
        for field in required_fields:
            if not cleaned_data.get(field):
                raise ValidationError(f"O campo {field} é obrigatório.")

        return cleaned_data

    def save(self, commit=True):
        """Salva o usuário com validações adicionais"""
        try:
            user = super().save(commit=False)
            user.email = self.cleaned_data["email"]
            user.first_name = self.cleaned_data["first_name"]
            user.last_name = self.cleaned_data["last_name"]
            user.is_active = True  # Ativar usuário por padrão

            if commit:
                user.save()
            return user
        except Exception as e:
            raise ValidationError(f"Erro ao salvar usuário: {str(e)}")


class CustomUserChangeForm(UserChangeForm):
    """Form personalizado para edição de usuários"""

    password = None  # Remove o campo de senha

    class Meta:
        model = User
        fields = (
            "username",
            "first_name",
            "last_name",
            "email",
            "is_active",
            "is_staff",
        )
        widgets = {
            "username": forms.TextInput(attrs={"class": "form-control"}),
            "first_name": forms.TextInput(attrs={"class": "form-control"}),
            "last_name": forms.TextInput(attrs={"class": "form-control"}),
            "email": forms.EmailInput(attrs={"class": "form-control"}),
            "is_active": forms.CheckboxInput(attrs={"class": "form-check-input"}),
            "is_staff": forms.CheckboxInput(attrs={"class": "form-check-input"}),
        }


# ========================================
# FORMULÁRIOS DE PAGAMENTO
# ========================================


class PaymentMethodForm(forms.Form):
    """Formulário para seleção do método de pagamento"""

    METODO_CHOICES = [
        ("pix", "PIX"),
        ("cartao", "Cartão de Crédito"),
    ]

    metodo_pagamento = forms.ChoiceField(
        choices=METODO_CHOICES,
        widget=forms.RadioSelect(attrs={"class": "form-check-input"}),
        label="Método de Pagamento",
    )


class CreditCardForm(forms.Form):
    """Formulário para dados do cartão de crédito"""

    numero_cartao = forms.CharField(
        max_length=19,
        widget=forms.TextInput(
            attrs={
                "class": "form-control",
                "placeholder": "0000 0000 0000 0000",
                "maxlength": "19",
            }
        ),
        label="Número do Cartão",
    )

    nome_portador = forms.CharField(
        max_length=100,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "Nome como está no cartão"}
        ),
        label="Nome do Portador",
    )

    validade_mes = forms.ChoiceField(
        choices=[(i, f"{i:02d}") for i in range(1, 13)],
        widget=forms.Select(attrs={"class": "form-select"}),
        label="Mês",
    )

    validade_ano = forms.ChoiceField(
        choices=[(i, str(i)) for i in range(2024, 2035)],
        widget=forms.Select(attrs={"class": "form-select"}),
        label="Ano",
    )

    cvv = forms.CharField(
        max_length=4,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "123", "maxlength": "4"}
        ),
        label="CVV",
    )

    parcelas = forms.ChoiceField(
        choices=[(i, f"{i}x") for i in range(1, 13)],
        widget=forms.Select(attrs={"class": "form-select"}),
        label="Parcelas",
    )

    def clean_numero_cartao(self):
        """Validação do número do cartão"""
        numero = self.cleaned_data.get("numero_cartao", "").replace(" ", "")

        if not numero.isdigit():
            raise ValidationError("O número do cartão deve conter apenas dígitos.")

        if len(numero) < 13 or len(numero) > 19:
            raise ValidationError("O número do cartão deve ter entre 13 e 19 dígitos.")

        return numero

    def clean_cvv(self):
        """Validação do CVV"""
        cvv = self.cleaned_data.get("cvv", "")

        if not cvv.isdigit():
            raise ValidationError("O CVV deve conter apenas dígitos.")

        if len(cvv) < 3 or len(cvv) > 4:
            raise ValidationError("O CVV deve ter 3 ou 4 dígitos.")

        return cvv


class BillingInfoForm(forms.Form):
    """Formulário para dados de cobrança"""

    nome_completo = forms.CharField(
        max_length=200,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "Nome completo"}
        ),
        label="Nome Completo",
    )

    email = forms.EmailField(
        widget=forms.EmailInput(
            attrs={"class": "form-control", "placeholder": "seu@email.com"}
        ),
        label="E-mail",
    )

    telefone = forms.CharField(
        max_length=15,  # (11) 99999-9999 => 15 caracteres no formato
        widget=forms.TextInput(
            attrs={
                "class": "form-control",
                "placeholder": "(11) 99999-9999",
                "maxlength": "15",  # (11) 99999-9999 => 15 caracteres
                "inputmode": "numeric",
                "autocomplete": "tel",
            }
        ),
        label="Telefone",
    )

    cpf = forms.CharField(
        max_length=14,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "000.000.000-00"}
        ),
        label="CPF",
    )

    cep = forms.CharField(
        max_length=9,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "00000-000"}
        ),
        label="CEP",
    )

    endereco = forms.CharField(
        max_length=200,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "Rua, avenida, etc."}
        ),
        label="Logradouro",
    )

    numero = forms.CharField(
        max_length=20,
        widget=forms.TextInput(attrs={"class": "form-control", "placeholder": "123"}),
        label="Número",
    )

    complemento = forms.CharField(
        max_length=100,
        required=False,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "Apartamento, sala, etc."}
        ),
        label="Complemento",
    )

    cidade = forms.CharField(
        max_length=100,
        widget=forms.TextInput(
            attrs={"class": "form-control", "placeholder": "Cidade"}
        ),
        label="Cidade",
    )

    estado = forms.ChoiceField(
        choices=[
            ("AC", "Acre"),
            ("AL", "Alagoas"),
            ("AP", "Amapá"),
            ("AM", "Amazonas"),
            ("BA", "Bahia"),
            ("CE", "Ceará"),
            ("DF", "Distrito Federal"),
            ("ES", "Espírito Santo"),
            ("GO", "Goiás"),
            ("MA", "Maranhão"),
            ("MT", "Mato Grosso"),
            ("MS", "Mato Grosso do Sul"),
            ("MG", "Minas Gerais"),
            ("PA", "Pará"),
            ("PB", "Paraíba"),
            ("PR", "Paraná"),
            ("PE", "Pernambuco"),
            ("PI", "Piauí"),
            ("RJ", "Rio de Janeiro"),
            ("RN", "Rio Grande do Norte"),
            ("RS", "Rio Grande do Sul"),
            ("RO", "Rondônia"),
            ("RR", "Roraima"),
            ("SC", "Santa Catarina"),
            ("SP", "São Paulo"),
            ("SE", "Sergipe"),
            ("TO", "Tocantins"),
        ],
        widget=forms.Select(attrs={"class": "form-select"}),
        label="Estado",
    )

    def clean_cpf(self):
        """Validação completa do CPF"""
        cpf = self.cleaned_data.get("cpf", "").replace(".", "").replace("-", "")

        if not cpf.isdigit():
            raise ValidationError("O CPF deve conter apenas números.")

        if len(cpf) != 11:
            raise ValidationError("O CPF deve ter 11 dígitos.")

        # Validação básica do CPF - verificar se todos os dígitos são iguais
        if cpf == cpf[0] * 11:
            raise ValidationError("CPF inválido.")

        # Validação do algoritmo do CPF
        if not self._validar_cpf(cpf):
            raise ValidationError("CPF inválido.")

        return cpf

    def _validar_cpf(self, cpf):
        """Valida o CPF usando o algoritmo oficial"""
        # Remove caracteres não numéricos
        cpf = re.sub(r"[^0-9]", "", cpf)

        # Verifica se tem 11 dígitos
        if len(cpf) != 11:
            return False

        # Verifica se todos os dígitos são iguais
        if cpf == cpf[0] * 11:
            return False

        # Calcula o primeiro dígito verificador
        soma = 0
        for i in range(9):
            soma += int(cpf[i]) * (10 - i)
        resto = soma % 11
        digito1 = 0 if resto < 2 else 11 - resto

        # Verifica o primeiro dígito
        if int(cpf[9]) != digito1:
            return False

        # Calcula o segundo dígito verificador
        soma = 0
        for i in range(10):
            soma += int(cpf[i]) * (11 - i)
        resto = soma % 11
        digito2 = 0 if resto < 2 else 11 - resto

        # Verifica o segundo dígito
        if int(cpf[10]) != digito2:
            return False

        return True

    def clean_telefone(self):
        """Validação do telefone"""
        telefone = (
            self.cleaned_data.get("telefone", "")
            .replace("(", "")
            .replace(")", "")
            .replace("-", "")
            .replace(" ", "")
        )

        if not telefone.isdigit():
            raise ValidationError("O telefone deve conter apenas números.")

        if len(telefone) != 11:
            raise ValidationError("O telefone deve ter exatamente 11 dígitos.")

        return telefone

    def clean_cep(self):
        """Validação do CEP"""
        cep = self.cleaned_data.get("cep", "").replace("-", "")

        if not cep.isdigit():
            raise ValidationError("O CEP deve conter apenas números.")

        if len(cep) != 8:
            raise ValidationError("O CEP deve ter 8 dígitos.")

        return cep
