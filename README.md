# worker-sqs-go

Worker em Go que consome mensagens de uma fila SQS, imprime o conteúdo e apaga a mensagem.
A fila roda no [LocalStack](https://localstack.cloud), então nada toca a AWS de verdade.

Projeto de estudo.

## Pré-requisitos

- [Go](https://go.dev/dl/) 1.26+
- [Docker](https://docs.docker.com/get-docker/) com Docker Compose
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (usada pelo Makefile para criar a fila e enviar mensagens)
- `make`
- Um auth token do LocalStack (veja abaixo)

Não é preciso ter conta na AWS nem credenciais válidas: o Makefile usa credenciais
fictícias (`test`/`test`), que é o que o LocalStack espera.

## Configurando o token do LocalStack

As versões recentes do LocalStack pedem um auth token mesmo na edição Community.
Crie uma conta gratuita em [app.localstack.cloud](https://app.localstack.cloud) e
copie o token para um arquivo `.env`:

```bash
cp .env.example .env
```

Depois abra o `.env` e preencha o `LOCALSTACK_AUTH_TOKEN`. O `.env` está no
`.gitignore` e não deve ser commitado.

## Simulação em 3 passos

Em um terminal, suba a infra e o worker:

```bash
make dev
```

Isso sobe o LocalStack, espera ficar saudável, cria a fila `my-queue` e deixa o worker
em loop aguardando mensagens.

Em **outro terminal**, publique uma mensagem:

```bash
make send
make send MESSAGE="qualquer texto aqui"
```

No terminal do worker você verá:

```
Message received: hello from make
Message received: qualquer texto aqui
```

Para encerrar: `Ctrl+C` no worker e depois `make down`.

## Comandos

`make help` lista tudo. Os principais:

| Comando | O que faz |
| --- | --- |
| `make dev` | Sobe a infra e executa o worker |
| `make up` | Sobe o LocalStack e cria a fila |
| `make run` | Executa apenas o worker |
| `make send` | Publica uma mensagem (`MESSAGE=texto` para customizar) |
| `make attrs` | Mostra quantas mensagens estão pendentes na fila |
| `make purge` | Descarta as mensagens pendentes |
| `make logs` | Acompanha os logs do LocalStack |
| `make down` | Derruba o LocalStack preservando o volume |
| `make clean` | Derruba o LocalStack e apaga o volume |

## Configuração

As variáveis do Makefile podem ser sobrescritas na linha de comando:

```bash
make send QUEUE_NAME=outra-fila MESSAGE="oi"
```

| Variável | Padrão |
| --- | --- |
| `QUEUE_NAME` | `my-queue` |
| `ENDPOINT` | `http://localhost:4566` |
| `AWS_REGION` | `us-east-1` |
| `MESSAGE` | `hello from make` |

## Como funciona

O worker (`cmd/worker/main.go`) faz long polling na fila com `WaitTimeSeconds: 20`,
ou seja, cada chamada fica até 20 segundos aguardando antes de retornar vazia. Para
cada mensagem recebida ele imprime o corpo e chama `DeleteMessage`. Sem esse delete
a mensagem voltaria à fila depois do visibility timeout e seria processada de novo.

O loop escuta `SIGINT`, `SIGTERM` e `SIGQUIT` para sair de forma limpa.