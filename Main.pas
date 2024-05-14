uses AstPrinter;
uses Expr;
uses Parser;
uses Token;
uses TokenType;
uses Scanner;
uses Interpreter;
uses Stmt;
uses Environment;

/// Main
///
begin
    var TheScanner := Scanner(
        '
            var a = 0;
            var temp;

            for (var b = 1; a < 1000; b = temp + b) {
                print a;
                temp = a;
                a = b;
            }
        ');

    var Tokens := TheScanner.ScanTokens();
    var TheParser := Parser(Tokens);
    var TheInterpreter := Interpreter();

    var Stmts := TheParser.Parse();
    
    TheInterpreter.Interpret (Stmts);
end