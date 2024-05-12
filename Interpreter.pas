class Interpreter;
begin
    /// Interprets a literal value.
    ///
    function VisitLiteral (TheExpr : LiteralExpr) : Any;
    begin
        Exit TheExpr.Value; 
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
