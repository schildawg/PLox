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
uses Resolver;

procedure Main;
var 
   TheScanner     : Scanner;
   TheParser      : Parser;
   TheResolver    : Resolver;
   TheInterpreter : Interpreter;
   
   Tokens : List;
   Stmts  : List;

begin
    TheScanner := Scanner(
        '
            fun fib(nn) {
               if (nn < 2) return nn;
        
               return fib(nn - 1) + fib(nn - 2);
            }

            var test = fib(7);
            print test;
        ');

    Tokens := TheScanner.ScanTokens();
    TheParser := Parser(Tokens);
    TheInterpreter := Interpreter();

    Stmts := TheParser.Parse();
    
    TheResolver := Resolver(TheInterpreter);
    TheResolver.Resolve(Stmts);

    TheInterpreter.Interpret (Stmts);
end

Main();