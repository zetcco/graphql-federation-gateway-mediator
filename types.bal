type SupergraphResponse record {
    record {| Supergraph supergraph; |}? data;
    ErrorDetail[]? errors = ();
};

type ErrorDetail record {
    string message;
};

type Supergraph record {
    string schema;
    string version;
};

