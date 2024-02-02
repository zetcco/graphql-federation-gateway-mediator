import ballerina/file;
import ballerina/os;
import ballerina/io;
import ballerina/log;

class GatewayServiceController {

    private os:Process? gatewayServiceProcess;
    private final string gatewayServicePath;
    private final string gatewayServiceGenerator;
    private final int port;

    public function init(string gatewayServicePath, string gatewayServiceGenerator, int port) returns error? {
        self.port = port;
        self.gatewayServiceProcess = ();
        self.gatewayServiceGenerator = gatewayServiceGenerator;
        self.gatewayServicePath = gatewayServicePath;
        if !(check file:test(self.gatewayServicePath, file:EXISTS)) {
            check file:createDir(self.gatewayServicePath);
        }
    }

    public function execute(string supergraphSchemaPath) {
        error? err = self.restartGateway(supergraphSchemaPath);
        if err is error {
            log:printError("Failed to start gateway", 'error = err);
        }
    }

    public function stopGatewayService() returns error? {
        os:Process? gatewayProcess = self.gatewayServiceProcess;
        if gatewayProcess is () {
            return error("No gateway service found");
        }
        gatewayProcess.exit();
        int exitStatus = check gatewayProcess.waitForExit();
        log:printInfo("Stopped Gateway service", exitStatus = exitStatus);

        check self.cleanupGatewayService();
    }

    function restartGateway(string supergraphSchemaPath) returns error? {
        if self.isGatewayServiceRunning() {
            check self.stopGatewayService();
        }
        check self.generateGatewayService(supergraphSchemaPath);
        check self.buildGatewayService();
        check self.startGatewayService();
    }

    function generateGatewayService(string supergraphSchemaPath) returns error? {
        check self.validateGatewayServiceGenerator();
        check self.validateGatewayServiceDirectory();
        check self.validateSupergraphSchema(supergraphSchemaPath);
        string[] configs = [
            string `-CsupergraphPath=${supergraphSchemaPath}`,
            string `-CoutputPath=${self.gatewayServicePath}`,
            string `-Cport=${self.port}`
        ];
        os:Command generateCommand = isWindows ? {
                                        value: "cmd.exe",
                                        arguments: [
                                            "/c",
                                            "bal",
                                            "run", 
                                            self.gatewayServiceGenerator,
                                            ...configs
                                    ]} : {
                                        value: "bal",
                                        arguments: [
                                            "run", 
                                            self.gatewayServiceGenerator,
                                            ...configs
                                    ]};
        os:Process exec = check os:exec(generateCommand);
        int status = check exec.waitForExit();
        if status != 0 {
            byte[] outputBytes = check exec.output(io:stdout);
            return error ExecError("Error generating Gateway service", output = check string:fromBytes(outputBytes));
        }
        log:printInfo("Generated Gateway Service code");
    }

    function buildGatewayService() returns error? {
        os:Command buildCommand = isWindows ? {
                                        value: "cmd.exe",
                                        arguments: [
                                            "/c",
                                            "bal",
                                            "build", 
                                            self.gatewayServicePath
                                    ]} : {
                                        value: "bal",
                                        arguments: [
                                            "build", 
                                            self.gatewayServicePath
                                    ]};
        os:Process exec = check os:exec(buildCommand);
        int status = check exec.waitForExit();
        if status != 0 {
            byte[] outputBytes = check exec.output(io:stdout);
            return error ExecError("Error building Gateway service", output = check string:fromBytes(outputBytes));
        }
        log:printInfo("Successfully built Gateway Service executable");
    }

    function startGatewayService() returns error? {
        string gatewayExecutablePath = check file:joinPath(self.gatewayServicePath, "target", "bin", "fedration_gateway.jar");
        os:Process exec = check os:exec({
            value: "java",
            arguments: [
                "-jar", 
                gatewayExecutablePath
        ]});
        self.gatewayServiceProcess = exec;
        log:printInfo("Started Gateway Service", port = self.port);
    }

    function cleanupGatewayService() returns error? {
        check file:remove(self.gatewayServicePath, file:RECURSIVE);
        check file:createDir(self.gatewayServicePath);
        log:printInfo("Cleaned up Gateway service");
    }

    function isGatewayServiceRunning() returns boolean {
        return self.gatewayServiceProcess is os:Process;
    }

    function validateGatewayServiceGenerator() returns error? {
        return check file:test(self.gatewayServiceGenerator, file:EXISTS) ? () : error("No Gateway service generator jar found");
    }

    function validateGatewayServiceDirectory() returns error? {
        return check file:test(self.gatewayServicePath, file:EXISTS) ? () : error("No Gateway service directory found");
    }

    function validateSupergraphSchema(string schemaPath) returns error? {
        return check file:test(schemaPath, file:EXISTS) ? () : error("No supergraph schema found");
    }
}