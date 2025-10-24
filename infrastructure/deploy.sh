sudo apt-get update -y 
sudo apt-get install -y python3 python3-pip python3-venv nginx git 
sudo mkdir -p /var/www/agendamento 
sudo chown -R ubuntu:ubuntu /var/www/agendamento 
cd /var/www/agendamento 
git clone https://github.com/fourmindsorg/s_agendamento.git . || true 
python3 -m venv venv 
source venv/bin/activate 
pip install --upgrade pip 
pip install -r requirements.txt gunicorn 
echo DEBUG=False > .env 
echo SECRET_KEY=django-insecure-4minds-agendamento-2025-super-secret-key >> .env 
echo ALLOWED_HOSTS=fourmindstech.com.br,www.fourmindstech.com.br,44.205.204.166 >> .env 
python manage.py migrate 
python manage.py collectstatic --noinput 
sudo systemctl restart nginx 
echo Deploy concluido! 
