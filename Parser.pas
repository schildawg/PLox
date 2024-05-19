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
    function Statement () : Stmt;
    begin
        if Match (TOKEN_IF) then Exit IfStatement();
        if Match (TOKEN_WHILE) then Exit WhileStatement();
        if Match (TOKEN_FOR) then Exit ForStatement();
        if Match (TOKEN_RETURN) then Exit ReturnStatement();
        if Match (TOKEN_PRINT) then Exit PrintStatment();
        if Match (TOKEN_LEFT_BRACE) then Exit BlockStmt (Block());

        Exit ExpressionStatement ();
    end

    /// Parses an if statement
    ///
    /// # Errors
    ///
    /// Raises an error if no opening parenthesis after if.
    /// Raises an error if no closing parenthesis after condition.
    ///
    function IfStatement () : Stmt;
    var
        Condition  : Expr;
        ThenBranch : Stmt;
        ElseBranch : Stmt;

    begin
        Consume (TOKEN_LEFT_PAREN, 'Expect "(" after if.');
        Condition := Expression();
        Consume (TOKEN_RIGHT_PAREN, 'Expect ")" after if condition.');

        ThenBranch := Statement ();
        if Match (TOKEN_ELSE) then
        begin
            ElseBranch := Statement ();
        end

        Exit IfStmt (Condition, ThenBranch, ElseBranch);
    end

    /// Parses a for statement
    ///
    /// # Errors
    ///
    /// Raise an error if no opening parenthesis after for.
    /// Raise an error if no semicolon after loop condition.
    /// Raise an error if no closing parenthesis after for clauses.
    ///
    function ForStatement () : Stmt;
    var
        Initializer : Stmt;
        Increment   : Expr;
        Condition   : Expr;
        Body        : Stmt;
        
        StmtList    : List of Stmt;
        WhileList   : List of Stmt;

    begin
        Consume (TOKEN_LEFT_PAREN, 'Expect "(" after for.');

        if Match (TOKEN_SEMICOLON) then
            Initializer := Initializer;   // Yeah, should be Nil
        else if Match (TOKEN_VAR) then
            Initializer := VarDeclaration ();
        else 
            Initializer := ExpressionStatement();

        if Not Check (TOKEN_SEMICOLON) then
        begin
           Condition := Expression ();
        end
        Consume (TOKEN_SEMICOLON, 'Expect ";" after loop condition.'); 

        if Not Check (TOKEN_RIGHT_PAREN) then
        begin
           Increment := Expression ();
        end
        Consume (TOKEN_RIGHT_PAREN, 'Expect ")" after for clauses.');  

        Body := Statement ();
        
        if Increment <> Nil then
        begin
            StmtList := List();
            StmtList.Add (Body);
            StmtList.Add (ExpressionStmt (Increment));

            Body := BlockStmt (StmtList);
        end

        if Condition = Nil then Condition := LiteralExpr (True);
        Body := WhileStmt(Condition, Body);

        if Initializer <> Nil then
        begin
            WhileList := List();
            WhileList.Add (Initializer);
            WhileList.Add (Body);

            Body := BlockStmt (WhileList);
        end

        Exit Body;
    end

    /// Parses a while statement
    ///
    /// # Errors
    ///
    /// Raises an error if no opening parenthesis after while.
    /// Raises an error if no closing parenthesis after condition.
    ///
    function WhileStatement () : Stmt;
    var
        Condition : Expr;
        Body      : Stmt;

    begin
        Consume (TOKEN_LEFT_PAREN, 'Expect "(" after while.');
        Condition := Expression();
        Consume (TOKEN_RIGHT_PAREN, 'Expect ")" after condition.');

        Body := Statement ();

        Exit WhileStmt (Condition, Body);
    end

    /// Parses a print statement
    /// 
    /// # Errors
    ///
    /// Raises an error if no semicolon after value.
    ///
    function PrintStatment () : Stmt;
    var
        Value : Expr;
    
    begin
        Value := Expression();
        Consume (TOKEN_SEMICOLON, 'Expect ";" after value.');
        
        Exit PrintStmt (Value);
    end
 
    /// Parses a return statement.
    ///
    ///
    /// # Errors
    ///
    /// Raises an error if no semicolon after value.
    ///
    function ReturnStatement () : Stmt;
    var
        Keyword : Token;
        Value   : Expr;

    begin
        Keyword := Previous();

        if Not Check(TOKEN_SEMICOLON) then
        begin
            Value := Expression();
        end

        Consume(TOKEN_SEMICOLON, 'Expect ";" after return value.');
        Exit ReturnStmt(Keyword, Value);
    end

    /// Parses a var declaration.
    ///
    /// # Errors
    /// 
    /// Raises an error if no variable name.
    /// Raises an error if no semicolon after variable declaration.
    ///
    function VarDeclaration () : Stmt;
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
    /// # Errors
    /// 
    /// Raises an error if no semicolon after expression.
    ///
    function ExpressionStatement () : Stmt;
    var
       TheExpr : Expr;
    
    begin
        TheExpr := Expression();
        Consume(TOKEN_SEMICOLON, 'Expect ";" after expression.');

        Exit ExpressionStmt (TheExpr);
    end

    // Parse a function statement.
    //
    // # Errors
    //
    // Raises an error if no function name.
    // Raises an error if no parenthesis after name.
    // Raises an error if missing parameter name.
    // Raises an error if more than 255 parameters.
    // Raises an error if no closing parenthesis after parameters.
    // Raises an error if no opening brace before body.
    // 
    function ParseFunction (Kind : String) : Stmt;
    var
        Name   : Token;
        Params : List of Token;
        Body   : List of Stmt;

    begin
        Name := Consume (TOKEN_IDENTIFIER, 'Expect ' + Kind + ' name.');
        Consume (TOKEN_LEFT_PAREN, 'Expect "(" after ' + Kind + ' name.');
        Params := List();
        if Not Check (TOKEN_RIGHT_PAREN) then
        begin
            Params.Add (Consume (TOKEN_IDENTIFIER, 'Expect parameter name.'));
            while Match (TOKEN_COMMA) do
            begin
                if Params.Length >= 255 then
                begin
                    raise 'Cannot have more than 255 parameters.';
                    //Error (Peek(), 'Cannot have more than 255 parameters.');
                end
                Params.Add (Consume (TOKEN_IDENTIFIER, 'Expect parameter name.'));              
            end
        end
        Consume (TOKEN_RIGHT_PAREN, 'Expect ")" after parameters.');
        Consume (TOKEN_LEFT_BRACE, 'Expect "{" before ' + Kind + ' body.');
        Body := Block ();

        Exit FunctionStmt (Name, Params, Body);
    end
    
    // Parses a block of statements.
    //
    // Raises an error if no semicolon after block.
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
    // # Errors
    //
    // Raises an error if invalid assignment target.
    //
    function Assignment () : Expr;
    var
       TheExpr : Expr;
       Equals  : Token;
       Value   : Expr;
    
    begin
        TheExpr := ParseOr ();

        if Match (TOKEN_EQUAL) then
        begin
            Equals := Previous ();
            Value  := Assignment ();

            if TheExpr.ClassName = 'VariableExpr' then
                Exit AssignExpr (TheExpr.Name, Value);
            else if TheExpr.ClassName = 'GetExpr' then
                Exit SetExpr (TheExpr.Object, TheExpr.Name, Value);

            raise 'Invalid assignment target.';
        end
        Exit TheExpr;
    end

    // Parses an or expression.
    //
    function ParseOr () : Expr;
    var
       TheExpr : Expr;
       Op      : Token;
       Right   : Expr;

    begin
        TheExpr := ParseAnd ();

        while Match (TOKEN_OR) do
        begin
            Op := Previous ();
            Right := ParseAnd ();
            TheExpr := LogicalExpr (TheExpr, Op, Right);
        end
       
        Exit TheExpr;
    end

     // Parses an and expression.
    //
    function ParseAnd () : Expr;
    var
       TheExpr : Expr;
       Op      : Token;
       Right   : Expr;

    begin
        TheExpr := Equality ();

        while Match (TOKEN_AND) do
        begin
            Op := Previous ();
            Right := Equality ();
            TheExpr := LogicalExpr (TheExpr, Op, Right);
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
            if Match (TOKEN_CLASS) then Exit ClassDeclaration ();
            if Match (TOKEN_FUN) then Exit ParseFunction ('function');
            if Match (TOKEN_VAR) then Exit VarDeclaration ();
            Exit Statement ();
        //except
        //    on e : String do 
        //        begin
        //           Synchronize ();
        //        end
        //end
    end

    function ClassDeclaration ();
    var
        Name       : Token;
        Methods    : List;
        Superclass : VariableExpr;

    begin
        Name := Consume (TOKEN_IDENTIFIER, 'Expect class name.');
        Superclass := Nil as VariableExpr;
        if Match (TOKEN_LESS) then
        begin
           Consume (TOKEN_IDENTIFIER, 'Expect superclass name.');
           Superclass := VariableExpr (Previous ());    
        end

        Consume (TOKEN_LEFT_BRACE, 'Expect "{" before class body.');

        Methods := List();
        while Not Check (TOKEN_RIGHT_BRACE) and Not IsAtEnd () do
        begin
            Methods.Add (ParseFunction ('method'));
        end

        Consume (TOKEN_RIGHT_BRACE, 'Expect "}" after class body.');

        Exit ClassStmt (Name, Superclass, Methods);
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
        Exit Call();
    end

    // Parses a call expression.
    //
    function Call () : Expr;
    var
       TheExpr : Expr;
       Name    : Token;

    begin
        TheExpr := Primary();
      
        while True do
        begin
            if Match (TOKEN_LEFT_PAREN) then
                TheExpr := FinishCall (TheExpr);
            else if Match (TOKEN_DOT) then
                begin
                    Name := Consume (TOKEN_IDENTIFIER, 'Expect property name after ".".');
                    TheExpr := GetExpr (TheExpr, Name);
                end
            else  
                Break;
        end
        Exit TheExpr;
    end

    // Finishes parsing a call.
    //
    // # Errors
    //
    // Raises an error if more than 255 arguments.
    // Raises an error if no closing parenthesis after arguments.
    //
    function FinishCall (Callee : Expr) : Expr;
    var
        Arguments : List of Expr;
        Paren     : Token;

    begin
        Arguments := List();
        if Not Check (TOKEN_RIGHT_PAREN) then
        begin
            Arguments.Add (Expression ());
            while Match (TOKEN_COMMA) do
            begin
                if Arguments.Length >= 255 then 
                    //Error (Peek(), 'Cannot have more than 255 arguments.');
                    raise 'Cannot have more than 255 arguments.';

                Arguments.Add (Expression ());
            end
        end
        Paren := Consume(TOKEN_RIGHT_PAREN, 'Expect ")" after arguments.');

        Exit CallExpr (Callee, Paren, Arguments);
    end

    // Parses a primary expression:  True, False, Nil, Number, String or Grouping.
    //
    // # Errors
    // 
    // Raises an error if grouping has no closing parenthesis.
    // Raises an error if no dot after "super".
    // Raises an error if no superclass method name.
    // Raises an error if no expression matched.
    //
    function Primary() : Expr;
    var 
        TheExpr : Expr;
        Keyword : Token;

    begin
        if Match (TOKEN_FALSE) then Exit LiteralExpr(False);
        if Match (TOKEN_TRUE) then Exit LiteralExpr(True);
        if Match (TOKEN_NIL) then Exit LiteralExpr(nil);

        if Match (TOKEN_NUMBER) or Match (TOKEN_STRING) then
        begin
            Exit LiteralExpr (Previous().Literal);
        end

        if Match (TOKEN_SUPER) then
        begin
           Keyword := Previous();
           Consume (TOKEN_DOT, 'Expect "." after "super".');  
           Method := Consume (TOKEN_IDENTIFIER, 'Expect supercalss method name.');
           Exit SuperExpr (Keyword, Method);  
        end

        if Match (TOKEN_THIS) then Exit ThisExpr (Previous());

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
    function Error(TheToken: Token, Message : String) : Any;
    begin
        Exit Message;
        
        // if TheToken.TypeOfToken = EOF then 
        //    Exit TheToken.LineNumber + ' at end: ' + Message;
        // else 
        //    Exit TheToken.LineNumber + ' at ' + TheToken.Lexeme + ': ' + Message;
    end

    // If current token matches a type then advance, otherwise throw an error.
    //
    // # Errors
    //
    // Raises an error if token not matched.
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

// Test parsing an or expression.
//
test 'Parse Or';
begin
    var TheScanner := Scanner ('true or false');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.ParseOr();

    AssertEqual('LogicalExpr', Result.ClassName);
end

// Test parsing an and expression.
//
test 'Parse And';
begin
    var TheScanner := Scanner ('true and false');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.ParseOr();

    AssertEqual('LogicalExpr', Result.ClassName);
end

// Test parsing an if statement.
//
test 'Parse If Statement';
begin
    var TheScanner := Scanner ('if (true) print true; else print false;');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Statement();

    AssertEqual('IfStmt', Result.ClassName);
end  

// Parsing an if statement without an opening paren should return a parse error.
// 
test 'Parse If Expect Opening Parenthesis';
begin
    var TheScanner := Scanner ('if true) print true; else print false;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect "(" after if.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end  

// Parsing an if statement without a closing paren should return a parse error.
//
test 'Parse If Expect Closing Parenthesis';
begin
    var TheScanner := Scanner ('if (true print true; else print false;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect ")" after if condition.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end  

// Test parsing a while statement.
//
test 'Parse While Statement';
begin
    var TheScanner := Scanner ('while (true) print true;');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Statement();

    AssertEqual('WhileStmt', Result.ClassName);
end  

// A while statement missing a left paren should return a parse error.
//
test 'Parse While Expect Opening Parenthesis';
begin
    var TheScanner := Scanner ('while true) print true;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect "(" after while.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end  

// A while statement missing the right paren should return a parse error.
//
test 'Parse While Expect Closing Parenthesis';
begin
    var TheScanner := Scanner ('while (true print true;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect ")" after condition.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end  

// A for statement should return an elaborate while statement.
//
test 'Parse For Statement';
begin
    var TheScanner := Scanner ('for (var i = 0; i < 10; i = i + 1) print true;');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Statement();

    AssertEqual('BlockStmt', Result.ClassName);
end  

// For statement missing opening paren should return a parse error.
//
test 'Parse For Expect Opening Parenthesis';
begin
    var TheScanner := Scanner ('for var i = 0; i < 10; i = i + 1) print true;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect "(" after for.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end  

// For statement missing closing paren should return a parse error.
//
test 'Parse For Expect Closing Parenthesis';
begin
    var TheScanner := Scanner ('for (var i = 0; i < 10; i = i + 1 print true;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect ")" after for clauses.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end  

// For statement missing a semicolon after the initializer should return a parse error.
//
test 'Parse For Expect Semicolon';
begin
    var TheScanner := Scanner ('for (var i = 0) print true;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect ";" after variable declaration.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Tests parsing a function call
//
test 'Parse Function Call';
begin
    var TheScanner := Scanner ('test(1, 2);');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Statement();

    AssertEqual('ExpressionStmt', Result.ClassName);
end  
    
// Parsing should accept multiple parenthesis.
//
test 'Parse Function Call Multiple Parenthesis';
begin
    var TheScanner := Scanner ('test(1, 2)();');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Statement();

    AssertEqual('ExpressionStmt', Result.ClassName);
end  

// Should return a parse error if arguments are not followed by a close paren.
//
test 'Parse Call Expect Closing Parenthesis';
begin
    var TheScanner := Scanner ('test(1, 2;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect ")" after arguments.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Should return a parse error if more than 255 arguments.
//
test 'Parse Call More Than 255';
begin
    var text := 'test(';
    for var I := 1; I < 300; I := I + 1 do
    begin
       text := text + I + ', ';
    end
    text := text + '300);';

    var TheScanner := Scanner (text);
    var TheParser := Parser (TheScanner.ScanTokens() as List);

    try
        TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Cannot have more than 255 arguments.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Tests parsing a function.
//
test 'Parse Function';
begin
    var TheScanner := Scanner ('fun test(a, b) {}');
    var TheParser := Parser (TheScanner.ScanTokens());

    var Result := TheParser.Declaration();

    AssertEqual('FunctionStmt', Result.ClassName);
end  

// Should return a parse error if no opening parenthesis
//
test 'Parse Function No Open Parenthesis';
begin
    var TheScanner := Scanner ('fun test;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
                AssertEqual('Expect "(" after function name.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Should return a parse error if more than 255 parameters
//
test 'Parse Function More Than 255 Parameters';
begin
    var text := 'fun test(';
    for var I := 1; I < 300; I := I + 1 do
    begin
       text := text + 'param' + I + ', ';
    end
    text := text + 'param300) {}';

    var TheScanner := Scanner (text);
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
                AssertEqual('Cannot have more than 255 parameters.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Should return a parse error if parameter is not an identifier.
//
test 'Parse Function Parameter Not Identifier';
begin
    var TheScanner := Scanner ('fun test(1, 2, 3) {}');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
                AssertEqual('Expect parameter name.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Should return a parse error if no closing parenthesis.
//
test 'Parse Function No Close Parenthesis';
begin
    var TheScanner := Scanner ('fun test(a, b;');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
                AssertEqual('Expect ")" after parameters.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Should return a parse error if no opening brace.
//
test 'Parse Function No Open Brace';
begin
    var TheScanner := Scanner ('fun test(a, b)');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
                AssertEqual('Expect "{" before function body.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Tests parsing a class!!
//
test 'Parse Class Declaration';
begin
    var TheScanner := Scanner ('
        class Breakfast {
            cook() {
                print \"Egg a-frying!\";
            } 

            serve(who) {
                print \"Enjoy your breakfast, \" + who + \".\";
            }
        }
    ');
    var TheParser := Parser (TheScanner.ScanTokens());

    TheParser.Declaration();
end

// Should return a parse error when there's no identifier.
//
test 'Parse Class No Identifier';
begin
    var TheScanner := Scanner ('class 123 {}');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
                AssertEqual('Expect class name.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Should return a parse error when there's no opening brace.
//
test 'Parse Class No Opening Brace';
begin
    var TheScanner := Scanner ('class Breakfast');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
                AssertEqual('Expect "{" before class body.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Should return a parse error when there's no closing brace.
//
test 'Parse Class No Closing Brace';
begin
    var TheScanner := Scanner ('class Breakfast {');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
                AssertEqual('Expect "}" after class body.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Should return a parse error when parses < but no superclass name.
//
test 'Parse Class No Superclass';
begin
    var TheScanner := Scanner ('
        class Breakfast < 123 {
        cook() {
            print \"Egg a-frying!\";
        } 
    ');
    var TheParser := Parser (TheScanner.ScanTokens());

    try
        TheParser.Declaration();
    except
        on e : String do
            begin
                AssertEqual('Expect superclass name.', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end

// Class getter should have a valid property name.
//
test 'Parse Getter Valid Property Name';
begin
    var TheScanner := Scanner ('print bagel.123;');

    var TheParser := Parser (TheScanner.ScanTokens());

    try
         TheParser.Statement();
    except
        on e : String do
            begin
                AssertEqual('Expect property name after ".".', e);
                Exit;
            end
    end
    Fail('No exception thrown.');
end
  

// Tests getters!!
//
test 'Parse Getter';
begin
    var TheScanner := Scanner ('print egg.scramble(3).with(cheddar);');

    var TheParser := Parser (TheScanner.ScanTokens());
    TheParser.Statement();
end

// Tests setters!!
//
test 'Parse Setter';
begin
    var TheScanner := Scanner ('print eggs.count = 42;');

    var TheParser := Parser (TheScanner.ScanTokens());
    TheParser.Statement();
end