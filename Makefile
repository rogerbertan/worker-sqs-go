QUEUE_NAME  ?= my-queue
ENDPOINT    ?= http://localhost:4566
AWS_REGION  ?= us-east-1
QUEUE_URL   ?= $(ENDPOINT)/000000000000/$(QUEUE_NAME)
MESSAGE     ?= hello from make

AWS := AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=$(AWS_REGION) aws --endpoint-url=$(ENDPOINT)

.PHONY: help up down clean logs queue send purge attrs run dev

.DEFAULT_GOAL := help

## help: lista os alvos disponíveis
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'

## up: sobe o LocalStack e cria a fila
up:
	docker compose up -d --wait
	$(MAKE) queue

## down: derruba o LocalStack preservando o volume
down:
	docker compose down

## clean: derruba o LocalStack e apaga o volume
clean:
	docker compose down -v

## logs: acompanha os logs do LocalStack
logs:
	docker compose logs -f localstack

## queue: cria a fila no LocalStack (idempotente)
queue:
	$(AWS) sqs create-queue --queue-name $(QUEUE_NAME)

## send: publica uma mensagem na fila (MESSAGE=texto)
send:
	$(AWS) sqs send-message --queue-url $(QUEUE_URL) --message-body "$(MESSAGE)"

## purge: descarta todas as mensagens pendentes na fila
purge:
	$(AWS) sqs purge-queue --queue-url $(QUEUE_URL)

## attrs: mostra a contagem de mensagens da fila
attrs:
	$(AWS) sqs get-queue-attributes --queue-url $(QUEUE_URL) --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible

## run: executa o worker
run:
	go run ./cmd/worker

## dev: sobe a infra e executa o worker
dev: up run