uses AstPrinter;
uses Expr;
uses Parser;
uses Token;
uses TokenType;
uses Scanner;
uses Interpreter;

/// Main
///
begin
    var TheScanner := Scanner('!false');
    var Tokens := TheScanner.ScanTokens();
    var TheParser := Parser(Tokens);

    TheParser.Expression();
    
        
     for var I := 0; I < Tokens.Length; I := I + 1 do
     begin
         var TheToken := Tokens[I];
         var TheType := TheToken.TypeOfToken;
   
         if TheType = TOKEN_IDENTIFIER or TheType = TOKEN_NUMBER or TheType = TOKEN_STRING then
             WriteLn(TheType + ': ' + TheToken.Lexeme);
         else
            WriteLn(TheType);
     end
end