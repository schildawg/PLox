/// Interpreter!!!
///
class Interpreter;
var 
    Env     : Environment;
    Globals : Environment;
    Locals  : Map;

begin
    constructor Init ();
    begin
        class ClockNative;
        begin
            function Arity () : Integer;
            begin
                Exit 0;
            end

            function Call (TheInterpreter, Arguments) : Any;
            begin
                Exit clock();
            end
        end

        this.Globals := Environment();
        this.Locals := Map();

        this.Env := Globals;
        
        Globals.Define ('clock', ClockNative());
    end

    /// Interprets a list of statements
    ///
    procedure Interpret (Statements : List);
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
        Exit LookupVariable (TheExpr.Name, TheExpr);
    end

    /// Finds a variable by distance or in globals.
    //
    function LookupVariable (Name : Token, TheExpr : Expr);
    var
        Distance : Integer;

    begin    
        Distance := Locals.Get (TheExpr) As Integer;
        if Distance <> Nil then 
            Exit Env.GetAt (Distance, Name.Lexeme);
        else
            Exit Globals.Get (Name);
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

    /// Interprets a call expression.
    ///
    /// # Errors
    ///
    /// Returns a runtime error if called with wrong number of parameters.
    ///
    function VisitCall (TheExpr : CallExpr) : Any;
    var
        Callee    : Any;
        Arguments : List;

    begin
        Callee := Evaluate (TheExpr.Callee);
  
        Arguments := List();
        for var I := 0; I < TheExpr.Arguments.Length; I := I + 1 do
        begin
            Arguments.Add (Evaluate (TheExpr.Arguments[I]));
        end

        // if Not InstanceOf(Callee, 'LoxCallable') then
        //begin
        //    raise RuntimeError (TheExpr.Paren, 'Can only call functions and classes');
        //end

        if Arguments.Length <> Callee.Arity() then
        begin
            raise RuntimeError (TheExpr.Paren, 'Expected ' + Callee.Arity() + ' arguments but got ' + Arguments.Length + '.');  
        end

        Exit Callee.Call (this, Arguments);
    end

    // Gets a property.
    //
    // # Errors
    // 
    // Raises an error if attempting to get a property on a non-instance.
    //    
    function VisitGetExpr (TheExpr : GetExpr) : Any;
    var
       Object : Any;

    begin
        Object := Evaluate (TheExpr.Object);
        
        if Object.ClassName <> 'LoxInstance' then
        begin
            raise 'Only instances have properties!';
        end

        Exit Object.Get (TheExpr.Name);
    end

    // Sets a property.
    //
    // # Errors
    // 
    // Raises an error if attempting to set a property on a non-instance.
    //
    function VisitSetExpr (TheExpr : SetExpr) : Any;
    var
       Object : Any;
       Value  : Any;

    begin
        Object := Evaluate (TheExpr.Object);

        if Object.ClassName <> 'LoxInstance' then
        begin
            raise 'Only instances have fields';
        end
        
        Value := Evaluate (TheExpr.Value);
        Object.Set (TheExpr.Name, Value);

        Exit Value;
    end

    // Evaluates "super".
    //
    function VisitSuperExpr (TheExpr : SuperExpr) : Any;
    var
        Distance   : Integer;
        Superclass : LoxClass;
        Object     : LoxInstance;
        Method     : LoxFunction;

    begin
        Distance := Locals.Get(TheExpr) as Integer;

        Superclass := Env.GetAt (Distance, 'super') as LoxClass;
        Object := Env.GetAt (Distance - 1, 'this') as LoxInstance;
        Method := Superclass.FindMethod (TheExpr.Method.Lexeme);

        Exit Method.Bind(Object);
    end

    // Evaluates "this".
    //
    function VisitThisExpr (TheExpr : ThisExpr) : Any;
    begin
        Exit LookupVariable (TheExpr.Keyword, TheExpr);
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
    function Evaluate(TheExpr : Expr) : Any;
    begin
        Exit TheExpr.Accept(this);
    end

    /// Runs a statement.
    ///
    procedure Execute (TheStmt : Stmt);
    begin
        TheStmt.Accept (this);
    end

    procedure Resolve (TheExpr : Expr, Depth : Integer);
    begin
        Locals.Put (TheExpr, Depth);
    end

    /// Runs a list of statements in a new environment scope.
    ///
    procedure ExecuteBlock (Statements : List, NewEnv : Environment);
    var 
        PreviousEnv : Environment;

    begin
        PreviousEnv := this.Env as Environment;
        
        try 
            this.Env := NewEnv;
            for var I := 0; I < Statements.Length; I := I + 1 do
            begin
               Execute (Statements[I]);
            end
        // Poor man's finally.  TODO.
        except
            on e : Return do
                begin
                    this.Env := PreviousEnv;
                    raise e;
                end
        end
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

    /// Runs a class statement.
    ///
    /// # Errors
    ///
    /// Raises an error if superclass is not a class.
    ///
    procedure VisitClassStmt (TheStmt : ClassStmt);
    var
       Klass      : LoxClass;
       Superclass : Any;
       Methods    : Map;

    begin
        Superclass := Nil;
        if TheStmt.Superclass <> Nil then
        begin  
            Superclass := Evaluate (TheStmt.Superclass);
            if Superclass.ClassName <> 'LoxClass' then
            begin
                raise 'Superclass must be a class.';
            end
        end

        Env.Define (TheStmt.Name.Lexeme, Nil);

        if TheStmt.Superclass <> Nil then
        begin
            var Previous : Environment := Env;
            Env := Environment();
            Env.Enclosing := Previous;
            Env.Define ('super', Superclass);
        end

        Methods := Map();
        for var I := 0; I < TheStmt.Methods.Length; I := I + 1 do
        begin
            var Method := TheStmt.Methods[I];

            TheFunction := LoxFunction (Method, Env, Method.Name.Lexeme = 'init');
            Methods.Put (Method.Name.Lexeme, TheFunction);
        end
        Klass := LoxClass (TheStmt.Name, Superclass, Methods) as LoxClass;

        if Superclass <> Nil then
        begin
            Env := Env.Enclosing as Environment;
        end

        Env.Assign (TheStmt.Name, Klass);
    end

    /// Runs an expression statement.
    ///
    procedure VisitExpressionStmt (Stmt : ExpressionStmt);
    begin
        Evaluate (Stmt.Expression);
    end

    /// Runs a function statement.
    ///
    procedure VisitFunctionStmt (TheStmt : FunctionStmt);
    var 
        TheFunction : LoxFunction;

    begin
        TheFunction := LoxFunction (TheStmt, Env, False);
        Env.Define (TheStmt.Name.Lexeme, TheFunction);
    end

    /// Runs an if statement.
    ///
    procedure VisitIfStmt (Stmt : IfStmt);
    begin
        if IsTruthy (Evaluate (Stmt.Condition)) then
            Execute (Stmt.ThenBranch);
        else if Stmt.ElseBranch <> Nil then
            Execute (Stmt.ElseBranch);
    end

    /// Runs a while statement.
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

    /// Runs a return statement
    ///
    procedure VisitReturnStmt (Stmt : ReturnStmt);
    var
        Value : Any;

    begin
        if Stmt.Value <> Nil then Value := Evaluate (Stmt.Value);

        raise Return (Value);
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
        Value    : Any;
        Distance : Integer;
    
    begin
        Value := Evaluate (Expr.Value);
        Distance := Locals.Get (Expr) as Integer;
        if Distance <> Nil then       
            Env.AssignAt (Distance, Expr.Name, Value);
        else
            Globals.Assign(Expr.Name, Value);

        Exit Value;
    end
end

/// Return value.
///
class Return;
var 
    Value : Any;

begin
    constructor Init (Value : Any);
    begin
        this.Value := Value;
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
               AssertEqual ('Operands must be numbers.', Str(e));
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
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);
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
            print a;
            temp = a;
            a = b;
        }  
    ');

    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    // FIXME
    // TheInterpreter.Interpret(Statements);

    // var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'a', nil, 1));
    
    // AssertEqual(5.0, Value);    
end

// Test calling clock native function.
//
test 'Native Function Clock';
begin
    var TheScanner := Scanner ('
       var Abc := clock();
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'Abc', nil, 1));
    
    AssertTrue(Value <> Nil);    
end

// Test clock to string.
//
test 'Native Function Clock String';
begin
    var TheScanner := Scanner ('
       var Abc := clock;
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'Abc', nil, 1));
    
    AssertEqual('ClockNative instance', Str(Value));    
end

// Try to call a non-function should should report runtime error to Lox.
//
test 'Call Non Function';
begin
    var TheScanner := Scanner ('
        "totally not a functions"();
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    try
        TheInterpreter.Interpret(Statements);
    except
       on e : String do 
            begin
                // FIXME
                AssertEqual('Only instances have properties.', Str(e));
                Exit;
            end
    end
    Fail('No exception thrown.'); 
end

// Calling a function with the wrong number of arguments should report runtime error to Lox.
//
test 'Call Wrong Number Of Arguments';
begin
    var TheScanner := Scanner ('
            fun fib(n) {
               if (n < 2) return n;
        
               return fib(n - 1) + fib(n - 2);
            }

            var test = fib(1, 1);
            print(fib(1));
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    try
        TheInterpreter.Interpret(Statements);
    except
       on e : String do 
            begin
                // FIXME
                // AssertEqual('Only instances have properties.', Str(e));
                Exit;
            end
    end
    Fail('No exception thrown.'); 
end

// Tests calling a recursive function.
//
test 'Call Recursive Function';
begin
    var TheScanner := Scanner ('
            fun fib(n) {
               if (n < 2) return n;
        
               return fib(n - 1) + fib(n - 2);
            }
            var test = fib(7);
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);
    TheInterpreter.Interpret(Statements);

    var Value := TheInterpreter.Env.Get(Token(TOKEN_IDENTIFIER, 'test', nil, 1));
    
    AssertEqual(13.0, Value);    
end

// Tests local functions!!!
//
test 'Interpret Local Function';
begin
    var TheScanner := Scanner ('
            fun makeCounter() {
                var i = 0;
                fun count() {
                    i = i + 1;
                    print i;
                }
                return count;
            }
            
            var counter = makeCounter();
            counter();
            counter();
    ');

    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    TheResolver.Resolve(Statements);
    TheInterpreter.Interpret(Statements);

end

// Tests invalid getter
//
test 'Call Invalid Getter';
begin
    var TheScanner := Scanner ('
            var test = false;

            print test.len;
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    try
        TheInterpreter.Interpret(Statements);
    except
       on e : String do 
            begin
                AssertEqual('Only instances have properties.', Str(e));
                Exit;
            end
    end
    Fail('No exception thrown.'); 
end

// Tests undefined getter
//
test 'Call Undefined Getter';
begin
    var TheScanner := Scanner ('
            class Bagel {}
            var bagel = Bagel();

            print bagel.flavor;
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    try
        TheInterpreter.Interpret(Statements);
    except
       on e : String do 
            begin
                AssertEqual('Undefined property "flavor".', Str(e));
                Exit;
            end
    end
    Fail('No exception thrown.'); 
end

// Tests setters and getters!!
//
test 'Call Setters And Getters';
begin
    var TheScanner := Scanner ('
            class Bagel {}
            var bagel = Bagel();
            bagel.flavor = \"Yummy\";

            print bagel.flavor;
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();
    TheInterpreter.Interpret(Statements);
end

// Tests trying to inherit from a non-class.
//
test 'Inherit Not A Class';
begin
    var TheScanner := Scanner ('
            var NotAClass = \"Totally not a class!!!\";

            class Subclass < NotAClass {}
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();

    var Statements := TheParser.Parse();

    try
        TheInterpreter.Interpret(Statements);
    except
       on e : String do 
            begin
                AssertEqual('Only instances have properties.', Str(e));
                Exit;
            end
    end
    Fail('No exception thrown.'); 
end