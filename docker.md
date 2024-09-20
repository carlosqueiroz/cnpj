Claro! Vou guiá-lo passo a passo sobre como utilizar o projeto **Receita Federal do Brasil - Dados Públicos CNPJ** utilizando Docker e Docker Compose. Isso inclui configurar o PostgreSQL, preparar o ambiente Python, definir variáveis de ambiente e executar o processo ETL.

### **Passo 1: Pré-requisitos**

Antes de começar, certifique-se de ter instalado em sua máquina:

1. **Docker**: [Instalação do Docker](https://docs.docker.com/get-docker/)
2. **Docker Compose**: Geralmente já vem com o Docker Desktop, mas você pode verificar a instalação com `docker-compose --version`.
3. **Git**: Para clonar o repositório. [Instalação do Git](https://git-scm.com/downloads)

### **Passo 2: Clonar o Repositório**

Clone o repositório do GitHub para sua máquina local:

```bash
git clone https://github.com/aphonsoar/Receita_Federal_do_Brasil_-_Dados_Publicos_CNPJ.git
cd Receita_Federal_do_Brasil_-_Dados_Publicos_CNPJ
```

### **Passo 3: Estrutura do Projeto**

Certifique-se de que a estrutura do seu projeto esteja organizada conforme abaixo:

```
.
├── code/                       # Código Python
│   ├── ETL_coletar_dados_e_gravar_BD.py
│   ├── requirements.txt
│   └── .env_template
├── docker-compose.yml
├── Dockerfile
├── banco_de_dados.sql
└── ...
```

### **Passo 4: Configurar o `docker-compose.yml`**

Crie ou ajuste o arquivo `docker-compose.yml` na raiz do projeto com o seguinte conteúdo:

```yaml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    container_name: postgres_container
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: Dados_RFB
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./banco_de_dados.sql:/docker-entrypoint-initdb.d/banco_de_dados.sql
    networks:
      - cnpj_network

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: python_container
    volumes:
      - ./code:/usr/src/app
      - ./output:/usr/src/app/output
      - ./extracted:/usr/src/app/extracted
    depends_on:
      - db
    environment:
      OUTPUT_FILES_PATH: /usr/src/app/output
      EXTRACTED_FILES_PATH: /usr/src/app/extracted
      DB_USER: postgres
      DB_PASSWORD: password
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: Dados_RFB
    networks:
      - cnpj_network

volumes:
  postgres_data:

networks:
  cnpj_network:
```

### **Passo 5: Criar o `Dockerfile`**

Crie um arquivo chamado `Dockerfile` na raiz do projeto com o seguinte conteúdo:

```dockerfile
# Usa uma imagem Python como base
FROM python:3.9-slim

# Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho
WORKDIR /usr/src/app

# Copia o arquivo de requisitos para o container
COPY code/requirements.txt ./

# Instala as dependências do Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia o restante do código da aplicação
COPY code/ .

# Comando padrão: pode ser sobrescrito no docker-compose.yml
CMD ["python", "ETL_coletar_dados_e_gravar_BD.py"]
```

### **Passo 6: Configurar Variáveis de Ambiente**

Dentro do diretório `code`, você encontrará um arquivo `.env_template`. Siga os passos abaixo para configurar as variáveis de ambiente:

1. **Renomeie o arquivo**:

   ```bash
   cd code
   cp .env_template .env
   cd ..
   ```

2. **Edite o arquivo `.env`** conforme suas necessidades. Por exemplo:

   ```env
   OUTPUT_FILES_PATH=/usr/src/app/output
   EXTRACTED_FILES_PATH=/usr/src/app/extracted
   DB_USER=postgres
   DB_PASSWORD=password
   DB_HOST=db
   DB_PORT=5432
   DB_NAME=Dados_RFB
   ```

   > **Nota**: No `docker-compose.yml`, já definimos as variáveis de ambiente para o serviço `app`, mas certifique-se de que o arquivo `.env` dentro de `code/` esteja alinhado com essas configurações.

### **Passo 7: Configurar o Banco de Dados**

O `docker-compose.yml` está configurado para inicializar o banco de dados PostgreSQL e executar o script `banco_de_dados.sql` na primeira vez que o container for iniciado. Certifique-se de que o arquivo `banco_de_dados.sql` esteja na raiz do projeto.

> **Observação**: Se o banco de dados já estiver configurado e os dados já estiverem importados, você pode ignorar este passo.

### **Passo 8: Construir e Iniciar os Containers**

No diretório raiz do projeto, execute o seguinte comando para construir e iniciar os containers:

```bash
docker-compose up --build
```

Este comando fará o seguinte:

- **db**: Inicializará o container PostgreSQL com as credenciais e banco de dados especificados. Se `banco_de_dados.sql` estiver presente, ele será executado automaticamente para configurar o banco de dados.
- **app**: Construirá a imagem Python, instalará as dependências e iniciará o script ETL.

> **Dica**: Para rodar os containers em segundo plano (detached mode), use `-d`:
>
> ```bash
> docker-compose up --build -d
> ```

### **Passo 9: Executar o Processo ETL**

O serviço `app` no `docker-compose.yml` está configurado para executar o script `ETL_coletar_dados_e_gravar_BD.py` automaticamente ao iniciar. Portanto, ao rodar `docker-compose up --build`, o processo ETL será iniciado.

> **Aguarde**: Dependendo do volume de dados e dos recursos da sua máquina, o processo pode levar várias horas para ser concluído.

### **Passo 10: Acessar os Logs e Monitorar o Processo**

Para monitorar o andamento do processo ETL, você pode visualizar os logs do serviço `app`:

```bash
docker-compose logs -f app
```

Isso permitirá que você veja o que está acontecendo em tempo real.

### **Passo 11: Após a Conclusão**

Após a finalização do processo ETL:

- **Dados no PostgreSQL**: As tabelas especificadas (empresa, estabelecimento, socios, etc.) estarão disponíveis no banco de dados `Dados_RFB`.
- **Arquivos de Saída**: Os diretórios `output` e `extracted` dentro da pasta `code/` serão mapeados para pastas no host, permitindo acessar os arquivos baixados e extraídos diretamente.

### **Passo 12: Acessar o Banco de Dados**

Você pode acessar o banco de dados PostgreSQL usando uma ferramenta como **pgAdmin**, **DBeaver** ou mesmo via linha de comando. Use as seguintes credenciais:

- **Host**: `localhost`
- **Porta**: `5432`
- **Usuário**: `postgres`
- **Senha**: `password`
- **Banco de Dados**: `Dados_RFB`

> **Exemplo com psql**:

```bash
psql -h localhost -p 5432 -U postgres -d Dados_RFB
```

### **Passo 13: Parar os Containers**

Após finalizar o uso, você pode parar os containers com:

```bash
docker-compose down
```

### **Considerações Finais**

- **Volumes Persistentes**: O volume `postgres_data` garante que os dados do PostgreSQL sejam preservados mesmo após parar os containers.
- **Ajustes nas Variáveis de Ambiente**: Se necessário, ajuste as variáveis de ambiente no `docker-compose.yml` e no arquivo `.env` conforme as especificidades do seu ambiente.
- **Atualizações do Projeto**: Sempre verifique o repositório original para atualizações ou mudanças que possam afetar a configuração.

Com esses passos, você deverá conseguir configurar e utilizar o projeto **Receita Federal do Brasil - Dados Públicos CNPJ** de forma eficiente utilizando Docker e Docker Compose. Se encontrar algum problema ou tiver dúvidas adicionais, sinta-se à vontade para perguntar!
