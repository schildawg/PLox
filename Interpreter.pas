class Interpreter;
var 
    Env : Any;

begin
    constructor Init ();
    begin
        this.Env := Environment();
    end

    /// Interprets a list of statements
    ///
    procedure Interpret (Statements : Any);
    begin
        for var I : Integer := 0; I < Statements.Length; I := I + 1 do
        begin
           Execute (Statements[I]);     
        end 
    end

    /// Interprets a literal value.
    ///
    function VisitLiteral (TheExpr : LiteralExpr) : Any;
    begin
        Exit TheExpr.Value; 
    end

    /// Interprets a logical expression (and, or).
    ///
    function VisitLogical (TheExpr : LogicalExpr) : Any;
    var
        Left : Any;

    begin
        Left := Evaluate (TheExpr.Left);

        if TheExpr.Op.TypeOfToken = TOKEN_OR then
            begin
                if IsTruthy (Left) then Exit Left;
            end
        else
            if Not IsTruthy (Left) then Exit Left;
        
        Exit Evaluate(TheExpr.Right);
    end

    /// Interprets a grouping expression.
    ///
    function VisitGrouping (TheExpr : GroupingExpr) : Any;
    begin
        Exit Evaluate (TheExpr.Expression);
    end

    
    /// Interprets an unary expression.
    ///
    function VisitUnary (TheExpr : UnaryExpr);
    var
        Right : Any;

    begin
        Right := Evaluate (TheExpr.Right);

        case TheExpr.Op.TypeOfToken of
            TOKEN_MINUS : Exit -Right;
            TOKEN_BANG  : Exit Not IsTruthy(Right);
        end           
    end

    /// Interprets a variable expression.
    ///
    function VisitVariableExpr (TheExpr : VariableExpr);
    begin
        Exit Env.Get (TheExpr.Name);
    end

    /// Interprets a binary expression.
    ///
    function VisitBinary (TheExpr : BinaryExpr);
    var
        Left  : Any;
        Right : Any;

    begin
        Left  := Evaluate (TheExpr.Left);
        Right := Evaluate (TheExpr.Right);

        case TheExpr.Op.TypeOfToken of
           TOKEN_GREATER       : Exit Left > Right;
           TOKEN_GREATER_EQUAL : Exit Left >= Right;
           TOKEN_LESS          : Exit Left < Right;
           TOKEN_LESS_EQUAL    : Exit Left <= Right;
           
           TOKEN_BANG_EQUAL    : Exit Not IsEqual (Left, Right);
           TOKEN_EQUAL_EQUAL   : Exit IsEqual (Left, Right); 
           
           TOKEN_PLUS  : Exit Left + Right;
           TOKEN_MINUS : Exit Left - Right;
           TOKEN_SLASH : Exit Left / Right;
           TOKEN_STAR  : Exit Left * Right;
        end
    end

    // Is object truthy?
    //
    function IsTruthy (Obj : Any) : Boolean;
    begin
        If Obj = Nil or Obj = False then Exit False;

        Exit True; 
    end

    // Are objects equal?
    //
    function IsEqual (A : Any, B : Any) : Boolean;
    begin
       if A = Nil and B = Nil then Exit True;
       if A = Nil then Exit False;

       Exit A = B;
    end
    
    /// Performs double-dispatch evaluation of expression.
    ///
    function Evaluate(TheExpr : Any) : Any;   // TODO: Expr
    begin
        Exit TheExpr.Accept(this);
    end

    /// Runs a statment.
    ///
    procedure Execute (TheStmt : Any);
    begin
        TheStmt.Accept (this);
    end

    /// Runs a list of statements in a new environment scope.
    ///
    procedure ExecuteBlock (Statements : Any, NewEnv : Any);
    begin
        var PreviousEnv := this.Env;
        
        // try 
        NewEnv.Enclosing := this.Env;
        this.Env := NewEnv;

        for var I := 0; I < Statements.Length; I := I + 1 do
        begin
           Execute (Statements[I]);
        end
        
        // finally
        this.Env := PreviousEnv;
    end

    /// Runs a block statement.
    ///
    procedure VisitBlockStmt (TheStmt : BlockStmt);
    begin
        var NewEnv : Environment := Environment();
        NewEnv.Enclosing := Env;

        ExecuteBlock (TheStmt.Statements, NewEnv);
    end

    /// Runs an expression statment.
    ///
    procedure VisitExpressionStmt (Stmt : ExpressionStmt);
    begin
        Evaluate (Stmt.Expression);
    end

    /// Runs an if statment.
    ///
    procedure VisitIfStmt (Stmt : IfStmt);
    begin
        if IsTruthy (Evaluate (Stmt.Condition)) then
            Execute (Stmt.ThenBranch);
        else if Stmt.ElseBranch <> Nil then
            Execute (Stmt.ElseBranch);
    end

    /// Runs a while statment.
    ///
    procedure VisitWhileStmt (Stmt : WhileStmt);
    begin
        while IsTruthy (Evaluate (Stmt.Condition)) do
        begin
            Execute (Stmt.Body);
        end
    end

    /// Runs a print statement
    ///
    procedure VisitPrintStmt (Stmt : PrintStmt);
    var
        Value : Any;

    begin
        Value := Evaluate (Stmt.Expression);
        WriteLn (Value);
    end

    /// Runs a variable statement
    ///
    procedure VisitVarStmt (Stmt : VarStmt);
    var
        Value : Any;

    begin
        if Stmt.Initializer <> Nil then
        begin
            Value := Evaluate (Stmt.Initializer);
        end

        Env.Define (Stmt.Name.Lexeme, Value);
    end

    // Evaluates an assign expression.
    //
    function VisitAssignExpr (Expr : AssignExpr) : Any;
    var
        Value : Any;

    begin
        Value := Evaluate (Expr.Value);
        Env.Assign (Expr.Name, Value);
        Exit Value;
    end
end

// Evaluating a literal should return the value.
//
test 'Evaluate Literal';
begin
    // Arrange
    var TheInterpreter : Interpreter := Interpreter();

    var TheExpr : Expr := LiteralExpr(3.16);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(3.16, Value);
end

// Evaluating a grouping should return the value of the inside expression.
//
test 'Evaluate Grouping';
begin
    // Arrange
    var TheInterpreter : Interpreter := Interpreter();

    var TheExpr : Expr := LiteralExpr(3.16);
    TheExpr := GroupingExpr(TheExpr);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(3.16, Value);
end

// Evaluating an unary number with a minus operator should negate the number.
//
test 'Evaluate Unary Minus';
begin
    // Arrange
    var TheInterpreter : Interpreter := Interpreter();

    var TheExpr : Expr := LiteralExpr(3.16);
    TheExpr := UnaryExpr(Token(TOKEN_MINUS, '-', nil, 1), TheExpr);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(-3.16, Value);
end

// Should return a runtime error if expression of minus unary is not a number.
//
test 'Evaluate Unary Minus Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var TheExpr : Expr := LiteralExpr(True);
    TheExpr := UnaryExpr(Token(TOKEN_MINUS, '-', nil, 1), TheExpr);

    try 
        TheInterpreter.Evaluate(TheExpr);
        // FIXME
        //var Value := TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operand must be a number.', e);
               Exit;
           end
    end       
    Fail('No error raised');
end

// Unary expression with bang operator of boolean true should return false.
//
test 'Evaluate Unary Bang True';
begin
    // Arrange
    var TheInterpreter : Interpreter := Interpreter();

    var TheExpr : Expr := LiteralExpr(True);
    TheExpr := UnaryExpr(Token(TOKEN_BANG, '!', nil, 1), TheExpr);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(False, Value);
end


// Unary expression with bang operator of boolean false should return true.
//
test 'Evaluate Unary Bang False';
begin
    // Arrange
    var TheInterpreter : Interpreter := Interpreter();

    var TheExpr : Expr := LiteralExpr(False);
    TheExpr := UnaryExpr(Token(TOKEN_BANG, '!', nil, 1), TheExpr);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(True, Value);
end

// Unary expression with bang operand with nil value should return true.  (Nil has truthy value of false)
//
test 'Evaluate Unary Bang Nil';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var TheExpr : Expr := LiteralExpr(Nil);
    TheExpr := UnaryExpr(Token(TOKEN_BANG, '!', nil, 1), TheExpr);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(True, Value);
end

// Unary expression with bang operator with any other value should return false.  (Non-nil has truthy value of true)
//
test 'Evaluate Unary Bang Non-Nil';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var TheExpr : Expr := LiteralExpr('Hi');
    TheExpr := UnaryExpr(Token(TOKEN_BANG, '!', nil, 1), TheExpr);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(False, Value);
end

// Minus binary expression should return the left minus right.
//
test 'Evaluate Binary Minus';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Minus := Token(TOKEN_MINUS, '-', Nil, 1);
    var Left  := LiteralExpr(2.0);
    var Right := LiteralExpr(1.0);

    var TheExpr := BinaryExpr(Left, Minus, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(1.0, Value);
end

// Minus should return a runtime error if left expression is not a number.
//
test 'Evaluate Minus Left Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Minus := Token(TOKEN_MINUS, '-', Nil, 1);
    var Left  := LiteralExpr(True);
    var Right := LiteralExpr(1.0);

    var TheExpr := BinaryExpr(Left, Minus, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// Minus should return a runtime error if right expression is not a number.
//
test 'Evaluate Minus Right Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Minus := Token(TOKEN_MINUS, '-', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(False);

    var TheExpr := BinaryExpr(Left, Minus, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// Slash binary expression should return the left divided by right.
// 
test 'Evaluate Binary Slash';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Slash := Token(TOKEN_SLASH, '/', Nil, 1);
    var Left  := LiteralExpr(4.0);
    var Right := LiteralExpr(2.0);

    var TheExpr := BinaryExpr(Left, Slash, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(2.0, Value);
end

// Slash should return a runtime error if left expression is not a number.
//
test 'Evaluate Slash Left Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Slash := Token(TOKEN_SLASH, '-', Nil, 1);
    var Left  := LiteralExpr(True);
    var Right := LiteralExpr(1.0);

    var TheExpr := BinaryExpr(Left, Slash, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// Slash should return a runtime error if right expression is not a number.
//
test 'Evaluate Slash Right Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Slash := Token(TOKEN_SLASH, '/', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(False);

    var TheExpr := BinaryExpr(Left, Slash, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// Star binary expression should return the left divided by right.
// 
test 'Evaluate Binary Star';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Star := Token(TOKEN_STAR, '*', Nil, 1);
    var Left  := LiteralExpr(2.0);
    var Right := LiteralExpr(2.0);

    var TheExpr := BinaryExpr(Left, Star, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(4.0, Value);
end

// Star should return a runtime error if left expression is not a number.
//
test 'Evaluate Star Left Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Star := Token(TOKEN_STAR, '*', Nil, 1);
    var Left  := LiteralExpr(True);
    var Right := LiteralExpr(1.0);

    var TheExpr := BinaryExpr(Left, Star, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// Star should return a runtime error if right expression is not a number.
//
test 'Evaluate Star Right Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Star := Token(TOKEN_STAR, '*', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(False);

    var TheExpr := BinaryExpr(Left, Star, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// Plus should add two numbers.
//
test 'Evaluate Binary Plus Double';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Plus := Token(TOKEN_PLUS, '+', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, Plus, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(6.0, Value);
end

// Plus should concatenate two strings.
//
test 'Evaluate Binary Plus String';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Plus := Token(TOKEN_PLUS, '+', Nil, 1);
    var Left  := LiteralExpr('ABC');
    var Right := LiteralExpr('DEF');

    var TheExpr := BinaryExpr(Left, Plus, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual('ABCDEF', Value);
end

// Plus only supports two numbers and two strings.  Any other combination should return a runtime error.
//
test 'Evaluate Binary Plus Mixed';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Plus := Token(TOKEN_PLUS, '+', Nil, 1);
    var Left  := LiteralExpr(True);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, Plus, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be two numbers, or two strings.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// Test that Greater returns true if left is greater than right.
//
test 'Evaluate Binary Greater';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Greater := Token(TOKEN_GREATER, '>', Nil, 1);
    var Left  := LiteralExpr(4.0);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, Greater, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(True, Value);
end

// For Greater, if left is not a number a runtime error should be returned.
//
test 'Evaluate Binary Greater Left Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Greater := Token(TOKEN_GREATER, '>', Nil, 1);
    var Left  := LiteralExpr(True);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, Greater, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// For Greater, if left is not a number a runtime error should be returned.
//
test 'Evaluate Binary Greater Right Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Greater := Token(TOKEN_GREATER, '>', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(True);

    var TheExpr := BinaryExpr(Left, Greater, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end
   
// Test that >= returns true if left is greater than right.
//
test 'Evaluate Binary Greater Equal';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var GreaterEqual := Token(TOKEN_GREATER_EQUAL, '>=', Nil, 1);
    var Left  := LiteralExpr(4.0);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, GreaterEqual, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(True, Value);
end

// For >=, if left is not a number a runtime error should be returned.
//
test 'Evaluate Binary Greater Equal Left Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var GreaterEqual := Token(TOKEN_GREATER_EQUAL, '>=', Nil, 1);
    var Left  := LiteralExpr(True);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, GreaterEqual, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// For >=, if left is not a number a runtime error should be returned.
//
test 'Evaluate Binary Greater Equal Right Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var GreaterEqual := Token(TOKEN_GREATER_EQUAL, '>=', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(True);

    var TheExpr := BinaryExpr(Left, GreaterEqual, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// Tests that Less returns true if left is less than right.
//
test 'Evaluate Binary Less';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Less := Token(TOKEN_LESS, '<', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(4.0);

    var TheExpr := BinaryExpr(Left, Less, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(True, Value);
end

// For <, if left is not a number a runtime error should be returned.
//
test 'Evaluate Binary Less Left Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Less := Token(TOKEN_LESS, '<=', Nil, 1);
    var Left  := LiteralExpr(True);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, Less, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// For <, if left is not a number a runtime error should be returned.
//
test 'Evaluate Binary Less Right Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var Less := Token(TOKEN_LESS, '<', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(True);

    var TheExpr := BinaryExpr(Left, Less, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end


// Tests that <= returns true if left is less than right.
//
test 'Evaluate Binary Less Equal';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var LessEqual := Token(TOKEN_LESS_EQUAL, '<=', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(4.0);

    var TheExpr := BinaryExpr(Left, LessEqual, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(True, Value);
end

// For <=, if left is not a number a runtime error should be returned.
//
test 'Evaluate Binary Less Equal Left Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var LessEqual := Token(TOKEN_LESS_EQUAL, '<=', Nil, 1);
    var Left  := LiteralExpr(True);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, LessEqual, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// For <=, if left is not a number a runtime error should be returned.
//
test 'Evaluate Binary Less Equal Right Not Number';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var LessEqual := Token(TOKEN_LESS_EQUAL, '<=', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(True);

    var TheExpr := BinaryExpr(Left, LessEqual, Right);

    try 
        TheInterpreter.Evaluate(TheExpr);
    except
       on e : String do 
           begin 
               AssertEqual ('Operands must be numbers.', e);
               Exit;
           end
    end   
    Fail('No error raised');
end

// For != the values Nil and Nil value should return true.
//
test 'Evaluate Binary Bang Equal Nil';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var BangEqual := Token(TOKEN_BANG_EQUAL, '!=', Nil, 1);
    var Left  := LiteralExpr(Nil);
    var Right := LiteralExpr(Nil);

    var TheExpr := BinaryExpr(Left, BangEqual, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(False, Value);
end


// For != the values Nil and Some value should return true.
//
test 'Evaluate Binary Bang Equal Nil And Some';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var BangEqual := Token(TOKEN_BANG_EQUAL, '!=', Nil, 1);
    var Left  := LiteralExpr(Nil);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, BangEqual, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(True, Value);
end

// For != the values Nil and Some value should return true.
//
test 'Evaluate Binary Bang Equal Unequal Values';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var BangEqual := Token(TOKEN_BANG_EQUAL, '!=', Nil, 1);
    var Left  := LiteralExpr(True);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, BangEqual, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(True, Value);
end

/// For == equal values should return true.
//
test 'Evaluate Binary Equal Equal';
begin
    var TheInterpreter : Interpreter := Interpreter();

    var EqualEqual := Token(TOKEN_EQUAL_EQUAL, '==', Nil, 1);
    var Left  := LiteralExpr(3.0);
    var Right := LiteralExpr(3.0);

    var TheExpr := BinaryExpr(Left, EqualEqual, Right);

    // Act
    var Value := TheInterpreter.Evaluate(TheExpr);

    // Assert
    AssertEqual(True, Value);
end

// Print statements should display the expression to the console.  For now there are no side effects to test. 
//
test 'Execute Print Statement';
begin
    var TheScanner := Scanner ('print 123;');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    // TODO: Figure out how to assert.
end
   
// A variable declaration should define a variable in environment and allow a value to be assigned to it.
//
test 'Execute Expression Statement';
begin
    var TheScanner := Scanner ('var test = 1; test = 2;');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'test', nil, 1));
    
    AssertEqual(2.0, Value);    
end

// Verifies that a block can be executed.
//
test 'Execute Block Statement';
begin
    var TheScanner := Scanner ('var test = 1; {test = 5;}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'test', nil, 1));
    
    AssertEqual(5.0, Value);    
end

// Tests that if statement is executed when the expression evaluates to true.
//
test 'Execute If Statement';
begin
    var TheScanner := Scanner ('      
        var a = 0; 
        var test = true;  

        if (test) {
            a = 5;
        }  
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'a', nil, 1));
    
    AssertEqual(5.0, Value);    
end

// If an else clause exists, it should be executed when the expression evaluates to false.
//
test 'Execute Else Statement';
begin
    var TheScanner := Scanner ('      
        var test = false;  
        var a = 0;

        if (test) {
            a = 5;
        }
        else {
            a = 6;
        }
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'a', nil, 1));
    
    AssertEqual(6.0, Value);    
end

// Tests executing the logical or operator.
//
test 'Execute Logical Or';
begin
    var TheScanner := Scanner ('var test = true or false;');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'test', nil, 1));
    
    AssertEqual(True, Value);    
end

// Tests executing the logical and operator.
//
test 'Execute Logical And';
begin
    var TheScanner := Scanner ('var test = true and false;');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'test', nil, 1));
    
    AssertEqual(False, Value);    
end


// When evaluating logical operators values nil is treated as "truthy" false, and all other values as true.
//
test 'Execute Logical Truthy';
begin
    var TheScanner := Scanner ('var test = "hi" or 0 or false and nil;');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'test', nil, 1));
    
    AssertEqual('hi', Value);    
end

// Tests executing a while loop.
//
test 'Execute While Loop';
begin
    var TheScanner := Scanner ('
        var a = 0;
        var b = true;
        
        while (b) {
            b = false;
            a = 42;
        }   
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'a', nil, 1));
    
    AssertEqual(42.0, Value);    
end

// Tests executing a for loop.  For loops are not directly supported in the Interpreter, but are syntactic sugar
// in the parser creating a while loop to be run.  
test 'Execute For Loop';
begin
    var TheScanner := Scanner ('
        var a = 0;
        var temp;
        
        for (var b = 1; a < 5; b = temp + b) {
            temp = a;
            a = b;
        }  
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'a', nil, 1));
    
    AssertEqual(5.0, Value);    
end
