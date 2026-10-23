# Doroteia Lab API

API em Dart Frog com autenticação por e-mail e senha, persistência em MySQL e
respostas JSON padronizadas.

## Pré-requisitos

- Dart 3.11 ou superior (o projeto principal usa Dart 3.12.2 via FVM)
- Dart Frog CLI
- Docker com Docker Compose

Caso o Dart Frog CLI ainda não esteja instalado:

```bash
fvm dart pub global activate dart_frog_cli
```

## Instalação

Na pasta `api/`, instale as dependências:

```bash
fvm dart pub get
```

## Configuração do ambiente

Crie o arquivo local a partir do exemplo:

```bash
cp .env.example .env
```

Depois ajuste os valores de `.env`:

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=doroteia
DB_PASSWORD=doroteia123
DB_NAME=doroteia_lab
```

O arquivo `.env` está ignorado pelo Git. Variáveis definidas diretamente no
ambiente do processo têm precedência sobre os valores do arquivo.

## MySQL local com Docker

Na raiz do projeto `doroteia_lab`, suba o banco:

```bash
docker compose up -d mysql
```

O script `database/init.sql` cria a tabela `users` automaticamente na primeira
inicialização do volume. Para acompanhar o banco:

```bash
docker compose ps
docker compose logs -f mysql
```

A API abre conexões somente quando um repositório precisa acessar o banco.

## Executando a API

Na pasta `api/`, execute:

```bash
dart_frog dev
```

Por padrão, a API fica disponível em `http://localhost:8080`.

Rotas:

- `GET /`: status e versão da API
- `POST /auth/register`: cria uma conta
- `POST /auth/login`: valida as credenciais e retorna um token temporário

Exemplo de cadastro:

```json
{
  "email": "usuario@example.com",
  "password": "senha123",
  "name": "Usuário"
}
```

O token de login é um UUID temporário e ainda não representa uma sessão
persistente ou um JWT.

## Validação

```bash
fvm dart analyze
fvm dart test
```
