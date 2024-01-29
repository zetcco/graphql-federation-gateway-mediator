import ballerina/io;
import ballerina/file;
import ballerina/graphql;

class FetchSupergraphJob {
    // *task:Job;

    private final graphql:Client schemaRegistry;
    private final string supergraphFileName = "supergraph.graphql";
    private final string SUPERGRAPH_QUERY = string `
                                                query Supergraph {
                                                    supergraph {
                                                        schema
                                                        version
                                                    }
                                                }
                                            `;

    isolated function init() returns error? {
        self.schemaRegistry = check new (schemaRegistry);
    }

    public function execute() returns boolean {
        Supergraph|error? latestSupergraph = self.getCurrentSupergraph();
        if latestSupergraph is error {
            io:println(latestSupergraph.message());
            return false;
        }
        SupergraphResponse|error supergraphFetchResult = self.schemaRegistry->execute(self.SUPERGRAPH_QUERY);
        if supergraphFetchResult is error {
            io:println(supergraphFetchResult.message());
            return false;
        }
        record {| Supergraph supergraph; |}? supergraphData = supergraphFetchResult.data;
        if supergraphData is () {
            io:println("Fetched result is empty");
            return false;
        }
        Supergraph supergraph = supergraphData.supergraph;
        if latestSupergraph is Supergraph && supergraph.schema == latestSupergraph.schema {
            return false;
        }
        error? fileWriteError = io:fileWriteString(self.supergraphFileName, supergraph.schema);
        if fileWriteError is error {
            io:println(fileWriteError.message());
            return false;
        }
        io:println("Updated supergraph");
        return true;
    }

    function getCurrentSupergraph() returns Supergraph|error? {
        boolean isSupergraphFileExists = check file:test(self.supergraphFileName, file:EXISTS);
        if !isSupergraphFileExists {
            return ();
        }
        string schema = check io:fileReadString(self.supergraphFileName);
        return {
            schema,
            version: "0.0.0"
        };
    }
}