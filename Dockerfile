# Usa uma imagem Python como base
FROM python:3.9-slim

# Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho
WORKDIR /usr/src/app

# Copia o arquivo de requisitos para o container
COPY requirements.txt ./

# Instala as dependências do Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia o restante do código da aplicação
COPY code/ .

# Comando padrão: pode ser sobrescrito no docker-compose.yml
CMD ["python", "ETL_coletar_dados_e_gravar_BD.py"]
