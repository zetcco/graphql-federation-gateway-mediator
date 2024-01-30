import ballerina/io;
import ballerina/file;
import ballerina/graphql;
import ballerina/task;
import ballerina/log;

class SupergraphPollJob {
    *task:Job;

    private final graphql:Client schemaRegistry;
    private final string supergraphDirPath;
    private final string SUPERGRAPH_QUERY = string `
                                                query Supergraph {
                                                    supergraph {
                                                        schema
                                                        version
                                                    }
                                                }
                                            `;

    isolated function init(string schemaRegistry, string supergraphDirPath) returns error? {
        self.schemaRegistry = check new (schemaRegistry);
        self.supergraphDirPath = supergraphDirPath;
    }

    public function execute() {
        SupergraphResponse|error supergraphFetchResult = self.schemaRegistry->execute(self.SUPERGRAPH_QUERY);
        if supergraphFetchResult is error {
            log:printError("Failed to send Query to Schema Registry", 'error = supergraphFetchResult);
            return;
        }

        record {| Supergraph supergraph; |}? supergraphData = supergraphFetchResult.data;
        if supergraphData is () {
            log:printWarn("Schema Registry Error", errors = supergraphFetchResult.errors);
            return;
        }

        Supergraph supergraph = supergraphData.supergraph;
        Supergraph|error? latestSupergraph = self.getPreviousSupergraphIfExists(supergraph.version);
        if latestSupergraph is error {
            log:printError("Failed to get previous Supergraph", 'error = latestSupergraph);
            return;
        }
        if latestSupergraph is Supergraph && supergraph.schema == latestSupergraph.schema {
            return;
        }

        error? schemaWriteError = self.writeSupergraphSchema(supergraph);
        if schemaWriteError is error {
            log:printError("Schema write error.", 'error = schemaWriteError);
            return;
        }
        log:printDebug(string `Completed writing Supergraph v${supergraph.version}`);
    }

    function getPreviousSupergraphIfExists(string version) returns Supergraph|error? {
        string supergraphSchemaPath = check self.getSupergraphSchemaPathFromVersion(version);
        boolean isSupergraphFileExists = check file:test(supergraphSchemaPath, file:EXISTS);
        if !isSupergraphFileExists {
            return ();
        }
        string schema = check io:fileReadString(supergraphSchemaPath);
        return {
            schema,
            version: version
        };
    }

    function writeSupergraphSchema(Supergraph supergraph) returns error? {
        string supergraphSchemaPath = check self.getSupergraphSchemaPathFromVersion(supergraph.version);
        error? fileWriteError = io:fileWriteString(supergraphSchemaPath, supergraph.schema);
        if fileWriteError is error {
            io:println(fileWriteError.message());
            return;
        }
    }

    function getSupergraphSchemaPathFromVersion(string version) returns string|error {
        return check file:joinPath(self.supergraphDirPath, string `${version}.graphql`);
    }
}