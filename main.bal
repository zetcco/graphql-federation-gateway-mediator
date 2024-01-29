import ballerina/io;
import ballerina/lang.runtime;

configurable string supergraphPath = "supergraph.graphql";
configurable string gatewayServicePath = "generated_gateway";
configurable string gatewayServiceGenerator = "graphql_federation_gateway.jar";
configurable string schemaRegistry = "http://localhost:9090";

public function main() returns error? {
    FetchSupergraphJob updateSupergraphJob = check new();
    GatewayJob gatewayJob = new();
    while (true) {
        boolean isSupergraphUpdated = updateSupergraphJob.execute(); 
        if isSupergraphUpdated {
            io:println("Supergraph schema updated");
        }
        if !isSupergraphUpdated && gatewayJob.isGatewayServiceRunning() {
            runtime:sleep(5);
            continue;
        }
        error? stopResponse = gatewayJob.stopGatewayService();
        if stopResponse is error {
            io:println(stopResponse.message());
        }
        check gatewayJob.execute();
        runtime:sleep(5);
    }
}