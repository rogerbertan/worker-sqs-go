package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
)

const QueueURL = "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/my-queue"

func main() {
	ctx := context.Background()
	cfg, err := config.LoadDefaultConfig(
		ctx,
		config.WithRegion("us-east-1"),
		config.WithBaseEndpoint("http://localhost:4566"),
	)
	if err != nil {
		log.Fatal("unable to load SDK config", err)
	}

	svc := sqs.NewFromConfig(cfg)

	signalCh := make(chan os.Signal, 1)
	signal.Notify(signalCh, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)

	for {
		select {
		case <-signalCh:
			fmt.Println("Exiting...")
			return
		default:
			receiveParams := sqs.ReceiveMessageInput{
				QueueUrl:            aws.String(QueueURL),
				WaitTimeSeconds:     *aws.Int32(20),
				MaxNumberOfMessages: *aws.Int32(1),
			}

			result, err := svc.ReceiveMessage(ctx, &receiveParams)
			if err != nil {
				fmt.Println("error receiving message", err)
				time.Sleep(1 * time.Second)
				continue
			}

			for _, msg := range result.Messages {
				fmt.Printf("Message received: %s\n", *msg.Body)

				deleteParams := &sqs.DeleteMessageInput{
					QueueUrl:      aws.String(QueueURL),
					ReceiptHandle: msg.ReceiptHandle,
				}

				_, err = svc.DeleteMessage(ctx, deleteParams)
				if err != nil {
					fmt.Println("error deleting message", err)
					continue
				}
			}
		}
	}

}
