uses AstPrinter;

uses Token;
uses TokenType;

uses Expr;
uses Stmt;

uses Environment;
uses LoxFunction;
uses LoxClass;
uses LoxInstance;

uses Scanner;
uses Parser;
uses Resolver;
uses Interpreter;

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
            class Doughnut {
                cook() {
                    print "Fry until golden!";
                }
            }

            class BostonCream < Doughnut {
                cook() {
                    super.cook();
                    print "Pipe full of custard and coat with chocolate!";
                }
            }

            BostonCream().cook();
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