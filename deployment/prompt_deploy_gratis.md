---
titulo: "Prompt de Pesquisa: Deploy em Produção com Despesas Gratuitas"
descricao: "Use este prompt para investigar opções de deploy 100% gratuito do sistema s_agendamento."
---

Objetivo: você é um especialista DevOps/Cloud de 2025. Preciso de um plano para colocar em produção o meu sistema de agendamentos (repo/projeto: s_agendamento) com custo recorrente zero, aceitando eventuais limitações de planos gratuitos (cold start, limites de requisições, etc.). Entregue comparação de opções e um guia acionável passo a passo para chegar ao deploy em até 1 dia de trabalho.

Contexto do sistema (ajuste conforme necessário, caso não detecte via repo):
- Tipo: sistema web de agendamento (front + API + banco de dados).
- Requisitos mínimos:
  - HTTPS, domínio/subdomínio gratuito.
  - Banco de dados gerenciado gratuito (PostgreSQL ou equivalente).
  - Build e deploy automatizados a cada push na main.
  - Logs e monitoramento básico (uptime e erros) gratuitamente.
  - Rotinas agendadas (cron) se possível.
  - Envio de e-mails transacionais via plano gratuito (ex.: Resend, Brevo).
  
Stack do sistema (detectado no repositório):
- Linguagem/Back-end: Python + Django 5.2.x (WSGI/ASGI via Gunicorn).
- Banco de dados: PostgreSQL (driver `psycopg2-binary`).
- Servidor estático: WhiteNoise para servir arquivos estáticos em produção.
- Configuração: `.env` via `python-dotenv`; possibilidade de cache Redis (`django-redis`).
- Opcional/Integrações: `django-storages` + `boto3` para S3; geração de QRCode (`qrcode[pil]`).
- Testes: `pytest`, `pytest-django`, `pytest-cov`.

O que preciso que você pesquise e compare (inclua prós, contras, limites, e recomendação final):
1) Hospedagem de front-end estático/SSR:
   - Vercel (free), Netlify (free), Cloudflare Pages (free).
2) Hospedagem de back-end/API:
   - Render (free), Railway (free), Fly.io (free), Deta Space (free), Cloudflare Workers/Pages Functions (free).
   - Considerar cold start, limites de horas/CPU, sleep/idle, acesso a rede/banco.
3) Banco de dados gerenciado gratuito:
   - Neon (Postgres free), Supabase (Postgres free), PlanetScale (MySQL free), MongoDB Atlas (free).
   - Incluir: limites de conexões, storage, backup/export, políticas de retenção.
4) Filas/Jobs/Cron gratuitos:
   - Cloudflare Workers Cron Triggers, GitHub Actions cron (free), serviços nativos dos provedores acima.
5) Domínio/SSL e DNS:
   - Cloudflare (free) com subdomínio gratuito, SSL automático, e proxy.
6) E-mail transacional gratuito:
   - Resend (free tier), Brevo (free tier), Postmark trial, Mailgun trial (avaliar limitações).
7) Logs, monitoramento e alertas:
   - UptimeRobot (free), Better Stack (free), Sentry (free), Logtail (free), Grafana Cloud (free).
8) CI/CD gratuito:
   - GitHub Actions (free) com caches, secrets e matrizes simples.

Formato de saída desejado:
- Visão geral executiva (3-5 linhas) com a RECOMENDAÇÃO FINAL para stack 100% free.
- Tabela comparativa com: provedor, uso (front/back/db/cron), limites principais, complexidade, risco de lock-in.
- Arquitetura sugerida (diagrama textual curto) mostrando front, API, DB, DNS/SSL, CI/CD e monitoramento.
- Passo a passo completo (copy/paste) para a stack recomendada incluindo:
  1. Criação/Configuração das contas.
  2. Setup de DNS/SSL (Cloudflare).
  3. Deploy do front (ex.: Vercel/Cloudflare Pages).
  4. Deploy da API (ex.: Render/Railway/Fly.io/Cloudflare Workers).
  5. Provisionamento do DB (ex.: Neon/Supabase) + migrações.
  6. Configuração de variáveis de ambiente e secrets (URL do DB, chaves).
  7. Setup de CI/CD (GitHub Actions) com workflows YAML.
  8. Configuração de e-mails transacionais (ex.: Resend) e verificação de domínios.
  9. Criação de cron jobs gratuitos (se necessário).
  10. Observabilidade: uptime + erros + logs (ferramentas free).
- Entregar exemplos:
  - Arquivo de workflow GitHub Actions para API Django (YAML) incluindo steps de collectstatic e migrações.
  - Exemplo de `dockerfile`/`vercel.json`/`netlify.toml`/`fly.toml`/`wrangler.toml` conforme stack escolhida.
  - Exemplo de `Procfile` (quando aplicável) com comando `web: gunicorn <nome_do_projeto>.wsgi:application`.
  - Template de `.env.example` com todas as variáveis necessárias.
  - Comandos de migração (ex.: Prisma/Knex/TypeORM, se aplicável).
  - Snippets para health-check endpoint e log básico (se não existir).
- Riscos e mitigação:
  - Quais limites podem derrubar o serviço? Como contornar?
  - Estratégia de backup/export do banco free (cron + dump para storage gratuito, se possível).
  - Plano de rollback simples.

Critérios de escolha (ordem de prioridade):
1. Custo zero real no plano gratuito (sem cartão/sem “trial” obrigatório).
2. Simplicidade do setup e manutenção (dev solo).
3. Confiabilidade (uptime aceitável e poucos cold starts).
4. Facilidade de migração futura para plano pago ou outro provedor.

Personalização final:
- Antes de concluir, valide automaticamente o stack recomendado contra o repo do projeto. Já detectado: Python + Django + PostgreSQL. Ajuste o passo a passo para: coletar estáticos (`collectstatic`), aplicar migrações (`migrate`), configurar `ALLOWED_HOSTS`, `STATIC_ROOT`, variáveis do Postgres, e comando de execução via Gunicorn.
- Caso identifique componentes adicionais (ex.: Redis, S3), inclua instruções de configuração específicas nos provedores gratuitos (ex.: Redis gratuito do provedor escolhido; storage estático opcional ou servir via WhiteNoise).

Entrega final: um guia pronto para eu seguir e publicar no README do projeto, com todos os comandos necessários, arquivos de configuração e links de referência oficiais.


