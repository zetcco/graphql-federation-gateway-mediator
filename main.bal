import ballerina/task;
import ballerina/file;

configurable string supergraphDirPath = "supergraphs";
configurable string gatewayServicePath = "generated_gateway";
configurable string gatewayServiceGeneratorPath = "graphql_federation_gateway.jar";
configurable string schemaRegistry = "http://172.19.100.143:9090";
configurable decimal pollingInterval = 5.0;
configurable int port = 8000;

final GatewayServiceController gatewayJob = new(gatewayServicePath, gatewayServiceGeneratorPath, port);

service "supergraphObserver" on new file:Listener({ path: supergraphDirPath }) {
    remote function onModify(file:FileEvent fileEvent) {
        gatewayJob.execute(fileEvent.name);
    }
}

public function main() returns error? {
    SupergraphPollJob updateSupergraphJob = check new(schemaRegistry, supergraphDirPath);
    _ = check task:scheduleJobRecurByFrequency(updateSupergraphJob, pollingInterval);
}