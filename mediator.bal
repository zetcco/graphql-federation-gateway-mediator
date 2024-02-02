import ballerina/lang.runtime;
import ballerina/task;
import ballerina/file;

class Mediator {
    private final SupergraphPollJob pollJob;
    private final GatewayServiceController gatewayController;
    private final decimal pollingInterval;
    private final string supergraphDirPath;

    public function init(string gatewayServicePath, string supergraphDirPath, string gatewayServiceGenerator, int port, string schemaRegistry, decimal pollingInterval) returns error? {
        self.supergraphDirPath = supergraphDirPath;
        self.pollJob = check new(schemaRegistry, self.supergraphDirPath);
        self.gatewayController = check new(gatewayServicePath, gatewayServiceGeneratorPath, port);
        self.pollingInterval = pollingInterval;
    }

    public function 'start() returns error? {
        check self.startPolling();
        check self.startGatewayService();
    }

    public function stop() returns error? {
        check self.stopGatewayService();
    }

    private function startPolling() returns error? {
        _ = check task:scheduleJobRecurByFrequency(self.pollJob, self.pollingInterval);
    }

    private function startGatewayService() returns error? {
        file:Listener fileObserverListener = check new file:Listener({ path: self.supergraphDirPath });
        check fileObserverListener.attach(getSupergraphFileObserver(self.gatewayController), "supergraphObserver");
        check fileObserverListener.'start();
        runtime:registerListener(fileObserverListener);
    }

    private function stopGatewayService() returns error? {
        check self.gatewayController.stopGatewayService();
    }
}

function getSupergraphFileObserver(GatewayServiceController gatewayController) returns file:Service {
    file:Service fileObserverService = service object {
        remote function onModify(file:FileEvent fileEvent) {
            string fileName = fileEvent.name;
            gatewayController.execute(fileName);
        }
    };
    return fileObserverService;
}
