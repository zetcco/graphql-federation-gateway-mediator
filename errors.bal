public type Error distinct error;

public type ExecError distinct (Error & error<record {| string output; |}>);