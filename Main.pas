uses AstPrinter;
uses Expr;
uses Parser;
uses Token;
uses TokenType;
uses Scanner;
uses Interpreter;
uses Stmt;
uses Environment;
uses LoxFunction;

/// Main
///
begin
    var TheScanner := Scanner(
        '
            fun fib(n) {
               if (n < 2) return n;
        
               return fib(n - 1) + fib(n - 2);
            }
            var test = fib(7);
            print test;
        ');

    var Tokens := TheScanner.ScanTokens();
    var TheParser := Parser(Tokens);
    var TheInterpreter := Interpreter();

    var Stmts := TheParser.Parse();
    
    TheInterpreter.Interpret (Stmts);
end