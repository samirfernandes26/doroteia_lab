# Guia de execução para agentes de IA

Este arquivo é a referência operacional do repositório. Antes de alterar ou
executar o projeto, leia-o por completo e confirme se os arquivos citados ainda
correspondem ao código atual.

## Visão geral

O Doroteia Lab é composto por:

- um aplicativo Flutter na raiz do repositório;
- uma API Dart Frog em `api/`;
- um banco MySQL 8 executado pelo `docker-compose.yml` da raiz.

O aplicativo possui autenticação, calculadora de orçamento e catálogo de
produtos. Riverpod gerencia o estado, GoRouter gerencia as rotas e
SharedPreferences mantém a sessão e o catálogo localmente. A API persiste os
usuários no MySQL.

## Fontes de verdade

- Flutter fixado pelo FVM: `.fvmrc` (`3.44.7`).
- SDK Dart do app: `pubspec.yaml` (`^3.12.2`).
- SDK Dart da API: `api/pubspec.yaml` (`^3.11.0`).
- URL usada pelo app: `lib/features/auth/presentation/providers/auth_providers.dart`.
- Banco local: `docker-compose.yml` e `api/.env.example`.
- Esquema inicial: `api/database/init.sql`.

Há uma divergência conhecida no `api/README.md`: ele menciona a API na porta
`8080` e, em um exemplo, o MySQL na porta `3306`. Para a configuração atual do
repositório, use **API em `8081`** e **MySQL em `3307`**, como descrito abaixo.

## Pré-requisitos

- Git.
- Docker com Docker Compose v2 (`docker compose`).
- FVM disponível no `PATH`.
- Flutter `3.44.7`, instalado pelo FVM.
- Dart Frog CLI.
- Chrome para o caminho de execução mais simples.

Para executar em Android, também são necessários Android SDK, `adb` e um
emulador ou aparelho configurado. Para iOS, são necessários macOS e Xcode.

Se o FVM ainda não estiver instalado, mas houver um Dart funcional no sistema,
ele pode ser instalado com:

```bash
dart pub global activate fvm
```

Garanta que o diretório de executáveis globais do Pub esteja no `PATH` antes de
continuar.

## Preparação inicial

Execute a partir da raiz do repositório:

```bash
fvm install
fvm flutter pub get
cd api
fvm dart pub get
fvm dart pub global activate dart_frog_cli
cp .env.example .env
cd ..
```

O arquivo `api/.env` deve conter, para o Docker Compose deste repositório:

```env
DB_HOST=127.0.0.1
DB_PORT=3307
DB_USER=doroteia
DB_PASSWORD=doroteia123
DB_NAME=doroteia_lab
```

Não versionar `api/.env`. As credenciais acima são exclusivamente para o
ambiente local de desenvolvimento. Variáveis exportadas no processo têm
precedência sobre o arquivo `.env`.

## Inicialização completa

Use três terminais. Todos os caminhos abaixo partem da raiz do repositório.

### 1. Banco de dados

```bash
docker compose up -d mysql
docker compose ps
docker compose logs --tail=50 mysql
```

O container escuta em `3306`, mas o host acessa o banco pela porta `3307`. Na
primeira criação do volume `mysql_data`, o Docker executa
`api/database/init.sql` e cria a tabela `users`.

Antes de iniciar a API, confirme nos logs que o MySQL terminou a inicialização e
está aceitando conexões.

### 2. API

É importante entrar em `api/`, pois o carregamento padrão procura `.env` no
diretório de trabalho atual:

```bash
cd api
dart_frog dev --port 8081
```

Se o executável `dart_frog` não estiver no `PATH`, use:

```bash
cd api
fvm dart pub global run dart_frog_cli:dart_frog dev --port 8081
```

Valide a API antes de abrir o aplicativo:

```bash
curl http://localhost:8081/
```

A resposta deve indicar que a API Doroteia Lab está online. As rotas atuais
são:

- `GET /`: saúde e versão;
- `POST /auth/register`: cria um usuário;
- `POST /auth/login`: valida e-mail e senha.

Exemplo de cadastro:

```bash
curl -i -X POST http://localhost:8081/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"usuario@example.com","password":"senha123","name":"Usuário"}'
```

O token devolvido pelo login é temporário. Ele não é um JWT nem uma sessão
persistida no servidor. Atualmente o cliente salva apenas os dados do usuário
no SharedPreferences.

### 3. Aplicativo Flutter

O caminho recomendado é o Chrome, porque a URL configurada no app é
`http://localhost:8081`:

```bash
fvm flutter run -d chrome
```

Também é possível usar a configuração **Doroteia Lab (Web)** presente em
`.vscode/launch.json`.

## Execução em Android e iOS

No Android, `localhost` normalmente aponta para o próprio emulador ou aparelho,
e não para a máquina de desenvolvimento. Mantenha a API na porta `8081` e, com
o dispositivo conectado, encaminhe a porta antes de executar o app:

```bash
adb reverse tcp:8081 tcp:8081
fvm flutter run
```

Se o encaminhamento não estiver disponível, será necessário tornar a URL da API
configurável e usar `10.0.2.2:8081` no emulador Android ou o IP da máquina na
rede para um dispositivo físico. Não faça uma troca permanente do endereço sem
considerar Web, testes e demais plataformas.

No simulador iOS, teste primeiro `localhost:8081`. Em aparelho físico, use um
endereço alcançável na rede e confirme as regras de transporte e firewall. O
Android já declara acesso à internet e tráfego HTTP local; o iOS permite rede
local em `ios/Runner/Info.plist`.

## Testes e validação

Valide app e API separadamente. Os testes unitários atuais da API usam dublês e
não devem depender de um MySQL real.

Na raiz, para o Flutter:

```bash
fvm dart format --output=none --set-exit-if-changed lib test
fvm flutter analyze
fvm flutter test
```

Em `api/`, para o Dart Frog:

```bash
fvm dart format --output=none --set-exit-if-changed lib routes test
fvm dart analyze
fvm dart test
```

Ao alterar somente uma área, rode primeiro o teste específico e depois a suíte
correspondente. Não há código gerado por Riverpod no estado atual, portanto
`build_runner` não é necessário para executar o projeto.

## Mapa da arquitetura

```text
lib/
  core/                    tema e roteamento
  features/auth/           domínio, tela e estado de autenticação
  features/calculator/     cálculo e exportação do orçamento
  features/catalog/        produtos, persistência local e interface
  shared/data/             HTTP, sessão e modelos compartilhados
api/
  database/                esquema SQL
  lib/database/            cliente MySQL
  lib/repositories/        acesso aos usuários
  lib/http/ e lib/utils/   respostas e validações
  routes/                  endpoints e middlewares Dart Frog
  test/                    testes da API
test/                      testes do aplicativo Flutter
```

O roteador inicia em `/login`, envia usuários autenticados para `/home` e
protege `/home` e `/catalog`. Sessão e catálogo são persistidos localmente via
SharedPreferences. A calculadora usa estado descartável (`autoDispose`).

## Regras para alterações feitas por agentes

1. Verifique `git status --short` antes de editar e preserve alterações que já
   pertençam ao usuário.
2. Mantenha a separação por feature e as abstrações de repositório/storage já
   existentes.
3. Em testes, substitua providers e use mocks ou implementações em memória; não
   dependa de rede, banco ou preferências reais sem necessidade explícita.
4. Nunca versionar segredos, `api/.env`, `.dart_tool/`, `.fvm/`, `build/`,
   `api/build/` ou `api/.dart_frog/`.
5. Não force a inclusão de `api/pubspec.lock`: ele está ignorado pela
   configuração atual da API. O `pubspec.lock` da raiz é versionado.
6. Formate os arquivos Dart alterados e execute análise e testes proporcionais
   à mudança.
7. Se mudar portas, variáveis, comandos ou a URL da API, atualize este arquivo,
   `api/.env.example` e os READMEs afetados no mesmo conjunto de mudanças.
8. Não remova volumes (`docker compose down -v`) sem autorização: isso apaga os
   dados locais do MySQL. `init.sql` só é aplicado automaticamente na criação
   inicial do volume.

## Diagnóstico rápido

- **App não conecta à API:** confirme que a API usa `--port 8081`, valide com
  `curl` e verifique `authApiBaseUrl`.
- **Android não conecta:** execute `adb reverse tcp:8081 tcp:8081` e reinicie o
  app.
- **`dart_frog: command not found`:** ative a CLI ou use o comando completo com
  `fvm dart pub global run`.
- **Erro `database_configuration_error`:** execute a API dentro de `api/` e
  confira as cinco variáveis `DB_*`.
- **Erro `database_unavailable`:** confirme `docker compose ps`, a porta `3307`
  e os logs do serviço `mysql`.
- **Tabela ausente após alterar `init.sql`:** o volume existente não reaplica o
  script. Aplique uma migração manual; só recrie o volume se a perda dos dados
  tiver sido explicitamente autorizada.
- **Versão errada de Flutter/Dart:** prefixe comandos com `fvm` e confira
  `fvm flutter --version`.
- **Porta ocupada:** identifique o processo antes de encerrá-lo; não altere a
  porta isoladamente, pois app e API precisam continuar alinhados.

## Critério de pronto

Uma mudança está pronta quando os arquivos estão formatados, a análise estática
e os testes relevantes passam, nenhum segredo ou artefato gerado foi incluído e
o fluxo afetado foi validado na plataforma aplicável. Para mudanças de
integração, confirme no mínimo MySQL ativo, `GET /` em `8081`, cadastro/login e
abertura do app após autenticação.
