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
        var a = 1;
        a = 2;

        var b = 2;

        {
            print "================"; 
            print a + b; 
        }

        ');

    var Tokens := TheScanner.ScanTokens();
    var TheParser := Parser(Tokens);
    var TheInterpreter := Interpreter();

    var Stmts := TheParser.Parse();
    
    TheInterpreter.Interpret (Stmts);
end