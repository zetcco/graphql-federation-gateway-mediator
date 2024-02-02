import ballerina/lang.runtime;
import ballerina/os;

configurable string supergraphDirPath = "supergraphs";
configurable string gatewayServicePath = "generated_gateway";
configurable string gatewayServiceGeneratorPath = "graphql_federation_gateway.jar";
configurable string schemaRegistry = "http://172.19.100.143:9090";
configurable decimal pollingInterval = 5.0;
configurable int port = 8000;

final boolean isWindows = os:getEnv("OS") != "";

public function main() returns error? {
    Mediator federationGatewayMediator = check new(gatewayServicePath, supergraphDirPath, gatewayServiceGeneratorPath, port, schemaRegistry, pollingInterval);
    check federationGatewayMediator.'start();
    runtime:onGracefulStop(federationGatewayMediator.stop);
}