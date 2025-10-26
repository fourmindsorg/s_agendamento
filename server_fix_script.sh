#!/bin/bash
echo "=== CORRIGINDO FRONTEND NO SERVIDOR ==="

# Parar serviços
sudo supervisorctl stop s-agendamento

# Ir para o diretório do projeto
cd /opt/s-agendamento

# Backup do template atual
sudo cp agendamentos/templates/agendamentos/home.html agendamentos/templates/agendamentos/home.html.backup

# Aplicar template corrigido
sudo -u django tee agendamentos/templates/agendamentos/home.html > /dev/null <<'TEMPLATE_EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AgendaFácil - Sistema de Agendamento</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --primary-color: #667eea;
            --secondary-color: #764ba2;
            --success-color: #28a745;
            --gradient-bg: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            --gradient-hero: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
        }

        body {
            font-family: 'Inter', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: var(--gradient-hero);
            min-height: 100vh;
            margin: 0;
            padding: 0;
        }

        .hero-container {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
        }

        .hero-content {
            position: relative;
            z-index: 2;
            text-align: center;
            color: white;
            max-width: 800px;
            padding: 2rem;
        }

        .hero-title {
            font-size: 4rem;
            font-weight: 900;
            margin-bottom: 1.5rem;
            text-shadow: 0 4px 8px rgba(0,0,0,0.1);
            line-height: 1.1;
        }

        .hero-subtitle {
            font-size: 1.5rem;
            margin-bottom: 2rem;
            opacity: 0.9;
            font-weight: 400;
        }

        .status-badge {
            display: inline-block;
            background: rgba(40, 167, 69, 0.9);
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 25px;
            font-weight: 600;
            margin-bottom: 2rem;
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255,255,255,0.2);
        }

        .action-buttons {
            display: flex;
            gap: 1rem;
            justify-content: center;
            flex-wrap: wrap;
            margin-top: 2rem;
        }

        .btn-action {
            padding: 1rem 2rem;
            font-size: 1.1rem;
            font-weight: 600;
            border-radius: 50px;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            border: none;
            cursor: pointer;
        }

        .btn-primary-action {
            background: rgba(255,255,255,0.9);
            color: var(--primary-color);
            backdrop-filter: blur(10px);
        }

        .btn-primary-action:hover {
            background: white;
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            color: var(--primary-color);
        }

        .btn-outline-action {
            background: transparent;
            color: white;
            border: 2px solid rgba(255,255,255,0.3);
            backdrop-filter: blur(10px);
        }

        .btn-outline-action:hover {
            background: rgba(255,255,255,0.1);
            border-color: white;
            transform: translateY(-3px);
            color: white;
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 2rem;
            margin-top: 3rem;
        }

        .feature-item {
            background: rgba(255,255,255,0.1);
            border-radius: 15px;
            padding: 1.5rem;
            text-align: center;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
            transition: all 0.3s ease;
        }

        .feature-item:hover {
            transform: translateY(-5px);
            background: rgba(255,255,255,0.15);
        }

        .feature-icon {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            color: rgba(255,255,255,0.9);
        }

        .feature-title {
            font-size: 1.2rem;
            font-weight: 600;
            margin-bottom: 0.5rem;
        }

        .feature-description {
            font-size: 0.9rem;
            opacity: 0.8;
        }

        .admin-link {
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(255,255,255,0.2);
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 25px;
            text-decoration: none;
            font-weight: 500;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.3);
            transition: all 0.3s ease;
        }

        .admin-link:hover {
            background: rgba(255,255,255,0.3);
            color: white;
            transform: translateY(-2px);
        }

        @media (max-width: 768px) {
            .hero-title { font-size: 2.5rem; }
            .hero-subtitle { font-size: 1.2rem; }
            .action-buttons { flex-direction: column; align-items: center; }
            .btn-action { width: 100%; max-width: 300px; justify-content: center; }
            .features-grid { grid-template-columns: 1fr; gap: 1rem; }
            .admin-link { position: relative; top: auto; right: auto; margin-bottom: 2rem; display: inline-block; }
        }
    </style>
</head>
<body>
    <a href="/admin/" class="admin-link">
        <i class="fas fa-cog"></i> Admin Django
    </a>

    <div class="hero-container">
        <div class="hero-content">
            <div class="status-badge">
                <i class="fas fa-check-circle"></i> Sistema funcionando perfeitamente!
            </div>
            
            <h1 class="hero-title">
                🚀 AgendaFácil
            </h1>
            
            <p class="hero-subtitle">
                Sistema de Agendamento - 4Minds
            </p>

            <div class="action-buttons">
                <a href="/admin/" class="btn-action btn-primary-action">
                    <i class="fas fa-cog"></i> Admin Django
                </a>
                <a href="/s_agendamentos/" class="btn-action btn-outline-action">
                    <i class="fas fa-calendar-check"></i> Agendamentos
                </a>
            </div>

            <div class="features-grid">
                <div class="feature-item">
                    <div class="feature-icon"><i class="fas fa-calendar-check"></i></div>
                    <h3 class="feature-title">Agendamentos</h3>
                    <p class="feature-description">Gerencie seus agendamentos de forma eficiente</p>
                </div>
                <div class="feature-item">
                    <div class="feature-icon"><i class="fas fa-users"></i></div>
                    <h3 class="feature-title">Gestão de Clientes</h3>
                    <p class="feature-description">Controle completo dos seus clientes</p>
                </div>
                <div class="feature-item">
                    <div class="feature-icon"><i class="fas fa-chart-line"></i></div>
                    <h3 class="feature-title">Controle Financeiro</h3>
                    <p class="feature-description">Acompanhe seu faturamento e relatórios</p>
                </div>
                <div class="feature-item">
                    <div class="feature-icon"><i class="fas fa-file-alt"></i></div>
                    <h3 class="feature-title">Relatórios</h3>
                    <p class="feature-description">Análises detalhadas do seu negócio</p>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
TEMPLATE_EOF

# Reiniciar serviços
sudo supervisorctl start s-agendamento
sudo systemctl reload nginx

echo "=== CORREÇÃO APLICADA ==="
