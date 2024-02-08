# GraphQL Federation Mediator

The GraphQL Federation Mediator is an application designed to act as a mediator between the [GraphQL Federation Gateway](https://github.com/xlibb/graphql-federation-gateway) and the [GraphQL Federation Schema Registry](https://github.com/xlibb/graphql-schema-registry). Its primary function is to facilitate the communication and interaction between these two components in a GraphQL federation system.

The "GraphQL Federation Gateway" is responsible for generating a Ballerina service based on a Supergraph Schema provided as input. On the other hand, the "GraphQL Federation Schema Registry" stores and manages these Supergraph Schemas.

The mediator plays a crucial role in this ecosystem by continuously polling the Schema Registry for updates to the Supergraph Schema. When an updated Supergraph Schema is detected, the mediator fetches it from the Schema Registry and feeds it to the GraphQL Federation Gateway. Subsequently, the Gateway utilizes this updated schema to generate the Ballerina Service. Finally, the mediator starts up the newly generated Ballerina service.

## Features

- Polls the Schema Registry for updates to the Supergraph Schema
- Fetches and feeds updated Supergraph Schemas to the GraphQL Federation Gateway
- Starts up the newly generated Ballerina service
- Acts as an intermediary between the Schema Registry and the Gateway

## Prerequisites
- Java 17
- [Ballerina](https://ballerina.io/downloads/)

## Usage

To run the GraphQL Federation Mediator, you need to provide the following arguments:

- `-CgatewayServiceGeneratorPath`: Path to the `.jar` file of the GraphQL Federation Gateway.
- `-CschemaRegistry`: URL of the Schema Registry endpoint.
- `-CpollingInterval`: Polling interval in seconds (Default is 5 seconds).
- `-Cport`: Port to be used by the generated service (Default is `8000`).
- `-CsupergraphDirPath`: Directory path where the fetched supergraph schemas are stored. Optional; if not provided, it will create a directory named `supergraphs`.
- `-CgatewayServicePath`: Directory path where the gateway service project is generated. Optional; if not provided, it will create a directory named `generated_gateway`.

## Example Usage

```bash
java -jar graphql-federation-mediator.jar \
-CgatewayServiceGeneratorPath path/to/gateway.jar \
-CschemaRegistry http://schema-registry.com \
-CpollingInterval 10 \
-Cport 9000 \
-CsupergraphDirPath path/to/supergraphs \
-CgatewayServicePath path/to/generated_gateway
