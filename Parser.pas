/// Parses a list of tokens, creating a list of statements.
///
/// # Example
/// 
/// var TheScanner:= Scanner ('3.14');
/// var TheParser := Parser (TheScanner.ScanTokens());
///
/// var Result := TheParser.Primary();
///
/// AssertEqual(3.14, Result.Value);
/// 
class Parser;
var 
   Tokens :  List of Token;
   Current : Integer;

begin
    /// Creates a new Parser.
    ///
    constructor Init(Tokens : List);
    begin
       this.Tokens := Tokens;
       this.Current := 0;
    end

    /// Parses a list of statements.
    ///
    function Parse () : List;
    var 
        Statements : List of Stmt;

    begin
        Statements := List();
        while Not IsAtEnd () do
        begin
            Statements.Add (Declaration ());
        end  
        Exit Statements;
    end

    /// Parses a statement.
    ///
    function Statement ();
    begin
        if Match (TOKEN_PRINT) then Exit PrintStatment();
        if Match (TOKEN_LEFT_BRACE) then Exit BlockStmt (Block());

        Exit ExpressionStatement ();
    end

    /// Parses a print statement
    /// 
    function PrintStatment () : Stmt;
    var
        Value : Expr;
    
    begin
        Value := Expression();
        Consume (TOKEN_SEMICOLON, 'Expect ";" after value.');
        
        Exit PrintStmt (Value);
    end
 
    /// Parses a var declaration.
    ///
    function VarDeclaration ();
    var 
       Name : Token;
       Initializer : Expr;

    begin
        Name := Consume (TOKEN_IDENTIFIER, 'Expect variable name.');
        
        // TODO: Nil shouldn't make type mismatch.
        // Initializer := Nil;
        if Match (TOKEN_EQUAL) then
        begin
            Initializer := Expression();
        end 

        Consume (TOKEN_SEMICOLON, 'Expect ";" after variable declaration.');
        Exit VarStmt (Name, Initializer);
    end

    /// Parses an expression statement
    ///
    function ExpressionStatement () : Stmt;
    var
       TheExpr : Expr;
    
    begin
        TheExpr := Expression();
        Consume(TOKEN_SEMICOLON, 'Expect ";" after expression.');

        Exit ExpressionStmt (TheExpr);
    end

    // Parses a block of statements.
    //
    function Block () : List;
    var
       Statements : List of Statement;

    begin
        Statements := List();

        while Not Check (TOKEN_RIGHT_BRACE) do
        begin
            Statements.Add (Declaration ());
        end 
        
        Consume (TOKEN_RIGHT_BRACE, 'Expect "}" after block.');
        Exit Statements;
    end

    // Parses an assignment.
    //
    function Assignment () : Expr;
    var
       TheExpr : Expr;
       Equals  : Token;
       Value   : Expr;
    
    begin
        TheExpr := Equality();

        if Match (TOKEN_EQUAL) then
        begin
            Equals := Previous ();
            Value  := Assignment ();

            if TheExpr.ClassName = 'VariableExpr' then
            begin
                Exit AssignExpr (TheExpr.Name, Value);
            end
            raise 'Invalid assignment target.';
        end
        Exit TheExpr;
    end

    // Parses an expression.  Calls Equality.
    function Expression() : Expr;
    begin
       Exit Assignment ();
    end

    
    // Parses a declaration.
    //
    function Declaration();
    begin
        //try 
            if Match (TOKEN_VAR) then Exit VarDeclaration();
            Exit Statement ();
        //except
        //    on e : String do 
        //        begin
        //           WriteLn (e);
                   // Synchronize ();
        //        end
        //end
    end

    // Parses an equality (!= ==).  Calls Comparison if no match.
    //
    function Equality() : Expr;
    var 
       TheExpr  : Expr;
       Operator : Token;
       Right    : Expr;
       
    begin
       TheExpr := Comparison();

       while Match (TOKEN_BANG_EQUAL) or Match (TOKEN_EQUAL_EQUAL) do
       begin
           Operator := Previous();
           Right := Comparison();

           TheExpr := BinaryExpr(TheExpr, Operator, Right); 
       end

       Exit TheExpr;
    end

    // Parses a comparison (> >= < <=).  Calls Term if no match.
    //
    function Comparison() : Expr;
    var
        TheExpr : Expr;
        Operator : Token;

    begin
        TheExpr := Term();
       
        while Match (TOKEN_GREATER) or Match (TOKEN_GREATER_EQUAL) or 
              Match (TOKEN_LESS)    or Match (TOKEN_LESS_EQUAL) do
        begin
            Operator := Previous();
            Right := Term();
            TheExpr := BinaryExpr(TheExpr, Operator, Right);
        end
        Exit TheExpr;
    end

    // Parses a term (- +).  Calls Factor if no match.
    //
    function Term() : Expr;
    var
        TheExpr : Expr;
        Operator : Token;

    begin
        TheExpr := Factor();
       
        while Match (TOKEN_MINUS) or Match (TOKEN_PLUS) do
        begin
            Operator := Previous();
            Right := Term();
            TheExpr := BinaryExpr(TheExpr, Operator, Right);
        end
        Exit TheExpr;
    end

    // Parses a term expression (/ *).  Calls Unary if no match.
    //
    function Factor() : Expr;
    var
        TheExpr  : Expr;
        Operator : Token;
        Right    : Expr;

    begin
        TheExpr := Unary();
        while Match(TOKEN_SLASH) or Match(TOKEN_STAR) do
        begin
            Operator := Previous();
            Right := Unary();
            
            Exit BinaryExpr(TheExpr, Operator, Right);
        end
        Exit TheExpr;
    end

    // Parses an unary expression (! -).  Calls Primary if no match.
    //
    function Unary() : Expr;
    var
       Operator : Token;
       Right    : Expr;

    begin
        if Match (TOKEN_BANG) or Match (TOKEN_MINUS) then
        begin
            Operator := Previous();
            Right    := Unary();

            Exit UnaryExpr(Operator, Right);
        end
        Exit Primary();
    end

    // Parses a primary expression:  True, False, Nil, Number, String or Grouping.
    //
    // # Execeptions
    // 
    // Throws an exception if grouping has no closing parenthesis.
    // Throws an exception if no expression matched.
    //
    function Primary() : Expr;
    var 
        TheExpr : Expr;

    begin
        if Match (TOKEN_FALSE) then Exit LiteralExpr(False);
        if Match (TOKEN_TRUE) then Exit LiteralExpr(True);
        if Match (TOKEN_NIL) then Exit LiteralExpr(nil);

        if Match (TOKEN_NUMBER) or Match (TOKEN_STRING) then
        begin
            Exit LiteralExpr (Previous().Literal);
        end

        if Match (TOKEN_IDENTIFIER) then
        begin
           Exit VariableExpr (Previous());
        end

        if Match (TOKEN_LEFT_PAREN) then
        begin
            TheExpr := Expression();
            Consume (TOKEN_RIGHT_PAREN, 'Expect ")" after expression.');
        
            Exit GroupingExpr (TheExpr);
        end
        raise 'Expect expression!';
    end

    // If token type matches, advances and returns True, otherwise False.
    //
    function Match(TheType : TokenType) : Boolean;
    begin
        if Check (TheType) then
        begin
            Advance();
            Exit True;
        end
        Exit False;
    end

    // Returns an error.
    //
    function Error(TheToken: Token, Message : Any) : Any;
    begin
        Exit Message;
        
        // if TheToken.TypeOfToken = EOF then 
        //    Exit TheToken.LineNumber + ' at end: ' + Message;
        // else 
        //    Exit TheToken.LineNumber + ' at ' + TheToken.Lexeme + ': ' + Message;
    end

    // If current token matches a type then advance, otherwise throw an error.
    //
    function Consume (TypeOfToken : TokenType, Message : String) : Token;
    begin
        if Check (TypeOfToken) then Exit Advance();

        raise Error (Peek(), Message);
    end

    // Checks if current token matches a type.
    //
    function Check(TheType : TokenType) : Boolean;
    begin
       if IsAtEnd() then Exit False;
       
       Exit Peek().TypeOfToken = TheType;
    end

    // Returns the current token, and moves to next.
    //
    function Advance() : Token;
    begin
       if Not IsAtEnd() then Current := Current + 1;

       Exit Previous();
    end

    // Is at end of source?
    //
    function IsAtEnd() : Boolean;
    begin
       Exit Peek().TypeOfToken = EOF;
    end

    // Gets the current token.
    //
    function Peek() : Token;
    begin
       Exit Tokens[Current];
    end

    // Gets the previous token.
    //
    function Previous() : Token;
    begin
       Exit Tokens[Current - 1];
    end
end

// Parsing a false token should return a false literal.
//
test 'Parse False';
begin
    var TheScanner := Scanner ('false');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Primary();

    AssertEqual(False, Result.Value);
end

// Parsing a true token should return a true literal.
//
test 'Parse True';
begin
    var TheScanner := Scanner ('true');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Primary();

    AssertEqual(True, Result.Value);
end

// Parsing a nil token should return a literal of nil.
//
test 'Parse Nil';
begin
    var TheScanner:= Scanner ('nil');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Primary();

    AssertEqual(Nil, Result.Value);
end


// Parsing a number token should return a number literal
//
test 'Parse Number';
begin
    var TheScanner:= Scanner ('3.14');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Primary();

    AssertEqual(3.14, Result.Value);
end

// Parsing a string token should return a String literal.
//
test 'Parse String';
begin
    var TheScanner:= Scanner ('"ABC"');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Primary();

    AssertEqual('ABC', Result.Value);
end

// Parsing a token of paranthesis should return a Grouping expression.
//
test 'Parse Parenthesis';
begin
    var TheScanner:= Scanner ('(1)');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Primary();

    AssertEqual(1.0, Result.Expression.Value);
end

// When parsing parenthesis, primary should return an error when there is an unmatched closing parenthesis.
// 
test 'Parse Parenthesis Error';
begin
    var TheScanner:= Scanner ('(1');
    var TheParser := Parser (TheScanner.ScanTokens());

    try 
       TheParser.Primary();
    except
        on e : String do 
            begin 
               AssertEqual ('Expect ")" after expression.', e);
               Exit;
            end
    end       
    Fail('No error raised');
end

// Should fail if reaches the end and a valid primary expression is not matched.
// 
test 'Parse Primary Error';
begin
    var TheScanner:= Scanner ('-1');
    var TheParser := Parser (TheScanner.ScanTokens());

    try 
       TheParser.Primary();
    except
        on e : String do 
            begin 
                AssertEqual ('Expect expression!', e);
                Exit;
            end
    end       
    Fail('No error raised');
end

// Negative numbers should return a unary with token type of Minus.
//
test 'Parse Unary Minus';
begin
    var TheScanner := Scanner ('-1');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Unary();

    AssertEqual(TOKEN_MINUS, Result.Op.TypeOfToken);
    AssertEqual(1.0, Result.Right.Value);
end

// Parsing ! should return a Unary
//
test 'Parse Unary Bang';
begin
    var TheScanner := Scanner ('!true');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Unary();

    AssertEqual(TOKEN_BANG, Result.Op.TypeOfToken);
    AssertEqual(True, Result.Right.Value);
end

// Parsing != should return a Binary expression.
//
test 'Parse Comparison Bang Equal';
begin
    var TheScanner := Scanner ('1 != 2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Equality();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_BANG_EQUAL, Result.Op.TypeOfToken);
end

// Parsing == should return a Binary expression.
//
test 'Parse Comparison Equal Equal';
begin
    var TheScanner := Scanner ('1 == 2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Equality();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_EQUAL_EQUAL, Result.Op.TypeOfToken);
end

    
// Parsing / should return a Binary.
//
test 'Parse Factor Slash';
begin
    var TheScanner := Scanner ('1/2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Factor();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_SLASH, Result.Op.TypeOfToken);
end

// Parsing * should return a Binary.
//
test 'Parse Factor Star';
begin
    var TheScanner := Scanner ('1*2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Factor();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_STAR, Result.Op.TypeOfToken);
end

// Parsing + should return a Binary.
//
test 'Parse Term Plus';
begin
    var TheScanner := Scanner ('1+2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Term();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_PLUS, Result.Op.TypeOfToken);
end

// Parsing - should return a Binary.
//
test 'Parse Term Minus';
begin
    var TheScanner := Scanner ('1-2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Term();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_MINUS, Result.Op.TypeOfToken);
end

// Parsing > should return a Binary.
//
test 'Parse Comparison Greater';
begin
    var TheScanner := Scanner ('1 > 2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Comparison();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_GREATER, Result.Op.TypeOfToken);
end

// Parsing >= should return a Binary.
//
test 'Parse Comparison Greater Equal';
begin
    var TheScanner := Scanner ('1 >= 2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Comparison();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_GREATER_EQUAL, Result.Op.TypeOfToken);
end

// Parsing < should return a Binary.
//
test 'Parse Comparison Less';
begin
    var TheScanner := Scanner ('1 < 2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Comparison();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_LESS, Result.Op.TypeOfToken);
end

// Parsing <= should return a Binary.
//
test 'Parse Comparison Less Equal';
begin
    var TheScanner := Scanner ('1 <= 2');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Comparison();

    AssertEqual(1.0, Result.Left.Value);
    AssertEqual(2.0, Result.Right.Value);
    AssertEqual(TOKEN_LESS_EQUAL, Result.Op.TypeOfToken);
end

// Tests parsing a print statement.
//
test 'Parse Print Statement';
begin
    var TheScanner := Scanner ('print 123;');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Statement();

    AssertEqual('PrintStmt', Result.ClassName);
end

// Print statement should end with a semicolon.
//
test 'Parse Print Expect Semicolon';
begin
    var TheScanner := Scanner ('print 123');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect ";" after value.', e);
                Exit;
            end
    end
    Fail('No exception raised.');
end

// Test parsing an expression statement.
//
test 'Parse Expression Statement';
begin
    var TheScanner := Scanner ('a = 1;');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Statement();

    AssertEqual('ExpressionStmt', Result.ClassName);
end

// Should not be able to assign to a rvalue.
//
test 'Parse Expression Invalid Assignment';
begin
    var TheScanner := Scanner ('1 = 1;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
               AssertEqual('Invalid assignment target.', e);
               Exit;
            end
    end
    Fail('No exception thrown.');
end

// Expression statement should end with a semicolon.
//
test 'Parse Expression Expect Semicolon';
begin
    var TheScanner := Scanner ('a = 1');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
               AssertEqual('Expect ";" after expression.', e);
               Exit;
            end
    end
    Fail('No exception thrown.');
end

// Tests parsing a declaration (var statement).
//
test 'Parse Var Statement';
begin
    var TheScanner := Scanner ('var a = 1;');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Declaration();

    AssertEqual('VarStmt', Result.ClassName);
end

// The left expression of a declaration should be a variable.
//
test 'Parse Var Expect Variable Name';
begin
    var TheScanner := Scanner ('var true = 1;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
               AssertEqual('Expect variable name.', e);
               Exit;
            end
    end
    Fail('No exception thrown.');
end

// A declaration should end with a semicolon.
//
test 'Parse Var Expect Semicolon';
begin
    var TheScanner := Scanner ('var a = 1');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
               AssertEqual('Expect ";" after variable declaration.', e);
               Exit;
            end
    end
    Fail('No exception thrown.');
end

// Verify that block statements are parsed successfully.
//
test 'Parse Block Statement';
begin
    var TheScanner := Scanner ('{var a = 1;}');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Declaration();

    AssertEqual('BlockStmt', Result.ClassName);
end

// Parsing a block should return a parse error if it is does not have a closing brace.
//
test 'Parse Block Expect Close';
begin
    var TheScanner := Scanner ('{ var a = 1;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
               AssertEqual('Expect expression!', e);
               Exit;
            end
    end
    Fail('No exception thrown.');
end