import ballerina/file;
import ballerina/os;
import ballerina/io;

class GatewayJob {

    private os:Process? gatewayServiceProcess;

    public function init() {
        self.gatewayServiceProcess = ();
    }

    public function execute() returns error? {
        check self.generateGatewayService();
        check self.startGatewayService();
    }

    function generateGatewayService() returns error? {
        check self.validateGatewayServiceGenerator();
        check self.validateGatewayServiceDirectory();
        check self.validateSupergraphSchema();
        os:Process exec = check os:exec({
            value: "bal",
            arguments: [
                "run", 
                gatewayServiceGenerator,
                string `-CsupergraphPath=${supergraphPath}`,
                string `-CoutputPath=${gatewayServicePath}`
        ]});
        int status = check exec.waitForExit();
        byte[] output = check exec.output(io:stdout);
        io:println(string `Gateway Service Code Generation: (Status:${status}, Output:${check string:fromBytes(output)})`);
    }

    function validateGatewayServiceGenerator() returns error? {
        return check file:test(gatewayServiceGenerator, file:EXISTS) ? () : error("No Gateway service generator jar found");
    }

    function validateGatewayServiceDirectory() returns error? {
        return check file:test(gatewayServicePath, file:EXISTS) ? () : error("No Gateway service directory found");
    }

    function validateSupergraphSchema() returns error? {
        return check file:test(supergraphPath, file:EXISTS) ? () : error("No supergraph schema found");
    }

    function startGatewayService() returns error? {
         os:Process exec = check os:exec({
            value: "bal",
            arguments: [
                "run",
                gatewayServicePath
            ]
        });
        io:println("Starting Gateway Service in a child process");
        self.gatewayServiceProcess = exec;
    }

    function stopGatewayService() returns error? {
        os:Process? gatewayProcess = self.gatewayServiceProcess;
        if gatewayProcess is () {
            return error("No gateway service found");
        }
        gatewayProcess.exit();
        check file:remove(gatewayServicePath, file:RECURSIVE);
        check file:createDir(gatewayServicePath);
        io:println("Stopped gateway service");
    }

    function isGatewayServiceRunning() returns boolean {
        return self.gatewayServiceProcess is os:Process;
    }
}