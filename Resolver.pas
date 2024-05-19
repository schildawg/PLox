/// Function Type!!!
///
type FunctionType = (FUN_NONE, FUN_FUNCTION, FUN_METHOD, FUN_INITIALIZER);

/// Class Type!!!
type ClassType = (CLASS_NONE, CLASS_CLASS, CLASS_SUBCLASS);

/// Resolver.  Semantic analysis pass to resolve and bind variables for use in the Interpreter.
///
class Resolver;
var
   TheInterpreter  : Interpreter;
   Scopes          : Stack;
   CurrentFunction : FunctionType;
   CurrentClass    : ClassType;
   
begin
    /// Creates a Resolver.
    //
    constructor Init(TheInterpreter : Interpreter);
    begin
        this.TheInterpreter := TheInterpreter;
        this.Scopes := Stack();
        this.CurrentFunction := FUN_NONE;
        this.CurrentClass := CLASS_NONE;
    end

    // A block statement introduces a new scope for the statements it contains.
    //
    procedure VisitBlockStmt (Stmt : BlockStmt);
    begin
        BeginScope();
        Resolve(Stmt.Statements);
        EndScope();
    end

    // Defines and declares the name of the class.
    //
    // # Errors
    //
    // Raises an error if attempting to inherit from itself.
    //
    procedure VisitClassStmt (Stmt : ClassStmt);
    var
        EnclosingClass : ClassType;

    begin
        EnclosingClass := CurrentClass;
        CurrentClass := CLASS_CLASS;

        Declare (Stmt.Name);
        Define (Stmt.Name);

        if Stmt.Superclass <> Nil and Stmt.Name.Lexeme = Stmt.Superclass.Name.Lexeme then
        begin
            raise 'A class cannot inherit from itself.';
        end

        if Stmt.Superclass <> Nil then
        begin
            CurrentClass := CLASS_SUBCLASS;
            Resolve (Stmt.Superclass);
        end

        if Stmt.Superclass <> Nil then
        begin
           BeginScope();
           Scopes.Peek().Put('super', True);
        end

        BeginScope();
        Scopes.Peek().Put ('this', true);

        for var I := 0; I < Stmt.Methods.Length; I := I + 1 do
        begin
            var Declaration := FUN_FUNCTION;
            if Stmt.Methods[I].Name.Lexeme = 'init' then
            begin
                Declaration := FUN_INITIALIZER;
            end
            ResolveFunction (Stmt.Methods[I], Declaration);
        end

        EndScope();
        
        if Stmt.Superclass <> Nil then EndScope();

        CurrentClass := EnclosingClass;
    end

    // Traverses tree.
    //
    procedure VisitExpressionStmt (Stmt : ExpressionStmt);
    begin
        Resolve (Stmt.Expression);
    end

    // Traverses tree.
    //
    procedure VisitIfStmt (Stmt : IfStmt);
    begin
        Resolve (Stmt.Condition);
        Resolve (Stmt.ThenBranch);
        if (Stmt.ElseBranch <> Nil) then Resolve (Stmt.ElseBranch);
    end

    // Traverses tree.
    //
    procedure VisitPrintStmt (Stmt : PrintStmt);
    begin
        Resolve (Stmt.Expression);
    end

    /// Runs a return statement
    ///
    /// # Errors
    ///
    /// Raises an error if at top level.
    ///
    procedure VisitReturnStmt (Stmt : ReturnStmt);
    begin
        if CurrentFunction = FUN_NONE then
        begin
            raise 'Cannot return from top-level code.';
        end

        if (Stmt.Value <> Nil) then 
        begin
            if CurrentFunction = FUN_INITIALIZER then
            begin
                raise 'Cannot return a value from an initializer.';
            end

            Resolve (Stmt.Value);
        end
    end

    // Traverses tree.
    //
    procedure VisitWhileStmt (Stmt : WhileStmt);
    begin
        Resolve (Stmt.Condition);
        Resolve (Stmt.Body);
    end

    // A function declaration introduces a new scope for its body, and binds its parameters to that scope.  Binds its name early
    // to enable recursion.
    //  
    procedure VisitFunctionStmt (Stmt : FunctionStmt);
    begin
        Declare (Stmt.Name);
        Define (Stmt.Name);

        ResolveFunction (Stmt, FUN_FUNCTION);
    end

    // A variable declaration adds a new variable to the current scope.
    //
    procedure VisitVarStmt (Stmt : VarStmt);
    begin
        Declare (Stmt.Name);
        if (Stmt.Initializer <> Nil) then
        begin
            Resolve (Stmt.Initializer);
        end
        Define (Stmt.Name);
    end

    // Assignment expressions need to have their variables resolved.
    //
    procedure VisitAssignExpr (TheExpr : AssignExpr);
    begin
        Resolve (TheExpr.Value);
        ResolveLocal (TheExpr, TheExpr.Name);
    end

    // Traverses tree.
    //
    procedure VisitBinary (TheExpr : BinaryExpr);
    begin
        Resolve (TheExpr.Left);
        Resolve (TheExpr.Right);
    end

    // Traverses tree.
    //
    procedure VisitLogical (TheExpr : LogicalExpr);
    begin
        Resolve (TheExpr.Left);
        Resolve (TheExpr.Right);
    end

    // Traverses tree.
    //
    procedure VisitUnary (TheExpr : UnaryExpr);
    begin
        Resolve (TheExpr.Right);
    end

    // Traverses tree.
    //
    procedure VisitCall (TheExpr : CallExpr);
    begin
        Resolve (TheExpr.Callee);
        for var I := 0; I < TheExpr.Arguments.Length; I := I + 1 do
        begin
            Resolve(TheExpr.Arguments[I]);
        end
    end

    // Traverses tree.
    //
    procedure VisitGetExpr (TheExpr : GetExpr);
    begin
        Resolve(TheExpr.Object);
    end

    // Traverses tree.
    //
    procedure VisitSetExpr (TheExpr : SetExpr);
    begin
        Resolve(TheExpr.Value);
        Resolve(TheExpr.Object);
    end

    // Traverses tree.
    //
    procedure VisitSuperExpr (TheExpr : SuperExpr);
    begin
        if CurrentClass = CLASS_NONE then
           raise 'Cannot use "super" outside of a class.';
        else if CurrentClass <> CLASS_SUBCLASS then
           raise 'Cannot use "super" in a class with no subclass.';

        ResolveLocal(TheExpr, TheExpr.Keyword);
    end

    // Resolves "this".
    //
    // # Errors
    //
    // Raises an error if invoking "this" outside of a class.
    //
    procedure VisitThisExpr (TheExpr : ThisExpr);
    begin
        if CurrentClass = CLASS_NONE then
        begin
            raise 'Cannot use "this" outside of a class.';
        end

        ResolveLocal (TheExpr, TheExpr.Keyword);
    end

    // Traverses tree.
    //
    procedure VisitGrouping (TheExpr : GroupingExpr);
    begin
        Resolve (TheExpr.Expression);
    end

    // Traverses tree.
    //
    procedure VisitLiteral (TheExpr : LiteralExpr);
    begin
    end

    // Variable expressions need to have their variables resolved.
    //
    // # Errors
    // 
    // Raises an error if attmepting to initialize variable with itself.
    //
    function VisitVariableExpr (TheExpr : VariableExpr);
    begin
        if Not Scopes.IsEmpty () and Scopes.Peek().Get(TheExpr.Name.Lexeme) = False then
        begin
           raise 'Cannot read local variable in its own initializer.';
        end

        ResolveLocal (TheExpr, TheExpr.Name);
    end

    /// Resolves a list of statements.
    ///
    procedure Resolve (Statements : List);
    begin
        for var I := 0; I < Statements.Length; I := I + 1 do
        begin
            Resolve(Statements[I]);
        end
    end

    // Resolves statements and expressions.
    //
    procedure Resolve (TheExpr : Any);
    begin
        TheExpr.Accept (this);
    end

    // A function declaration introduces a new scope for its body, and binds its parameters to that scope.
    //
    procedure ResolveFunction (TheFunction : FunctionStmt, TypeOfFunction : FunctionType);
    var
       EnclosingFunction : FunctionType;

    begin
        EnclosingFunction := CurrentFunction;
        CurrentFunction := TypeOfFunction as FunctionType;

        BeginScope ();
        for var I := 0; I < TheFunction.Params.Length; I := I + 1 do
        begin
            var Param  := TheFunction.Params[I];
            Declare (Param);
            Define (Param);
        end
        Resolve (TheFunction.Body);
        EndScope();

        CurrentFunction := EnclosingFunction;
    end

    // Begins a new scope.
    //
    procedure BeginScope ();
    begin
        Scopes.Push (Map());
    end

    // Ends the current scope.
    //
    procedure EndScope ();
    begin
        Scopes.Pop ();
    end

    // Declares a variable.
    //
    // # Exception
    //
    // Raises an error if variable already exists in scope.
    //
    procedure Declare (Name : Token);
    var
       Scope : Map;

    begin
        if Scopes.IsEmpty() then Exit;

        Scope := Scopes.Peek() as Map;
        if Scope.Contains (Name.Lexeme) then 
        begin
           raise 'Already a variable with this name in this scope.';
        end

        Scope.Put (Name.Lexeme, False);
    end

    // Defines a variable.
    //
    procedure Define (Name : Token);
    var
       Scope : Map;

    begin
        if Scopes.IsEmpty() then Exit;
        
        Scope := Scopes.Peek() as Map;
        Scope.Put (Name.Lexeme, True);
    end
    
    procedure ResolveLocal (TheExpr : Expr, Name : Token);
    begin
        for var I : Integer := Scopes.Length - 1; I >= 0; I := I - 1 do
        begin
            if Scopes[I].Contains (Name.Lexeme) then
            begin
                TheInterpreter.Resolve (TheExpr, Scopes.Length - 1 - I);
                Exit;
            end
        end
    end
end

// Resolver should have zero hops if defined and used in same scope.
//
test 'Resolve Same Level';
begin
    var TheScanner := Scanner ('var test = true; print test;');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    var Result := TheInterpreter.Locals.Get (Statements[1].Expression);
    AssertTrue (Result = Nil);
end


// Resolver should have zero hops if defined and used in same scope.  Trying it two levels deep.
//
test 'Resolve Same Level Two Deep';
begin
    var TheScanner := Scanner ('{ var test = true; print test;}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    // FIXME
    //var Key : VariableExpr := Statements[0].Statements[1].Expression;

    var Result := TheInterpreter.Locals.Get (Statements[0].Statements[1].Expression);
    AssertEqual (0, Result);
end

// Usage of variable in nested scope should have one hop.
//
test 'Resolve One Hop';
begin
    var TheScanner := Scanner ('{var test = true; {print test;}}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    var Result := TheInterpreter.Locals.Get (Statements[0].Statements[1].Statements[0].Expression);
    AssertEqual (1, Result);
end

// Testing two hops.
//
test 'Resolve Two Hops';
begin
    var TheScanner := Scanner ('{var test = true; {{print test;}}}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    var Result := TheInterpreter.Locals.Get (Statements[0].Statements[1].Statements[0].Statements[0].Expression);
    AssertEqual (2, Result);
end

// Testing assignment resolves locals.
//
test 'Resolve Assignment';
begin
    var TheScanner := Scanner ('{var test = true; {test = false;}}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    var Result := TheInterpreter.Locals.Get (Statements[0].Statements[1].Statements[0].Expression);
    AssertEqual (1, Result);
end

// Testing logical resolves locals.
//
test 'Resolve Logical';
begin
    var TheScanner := Scanner ('{var test = true; {test = false or true;}}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    var Result := TheInterpreter.Locals.Get (Statements[0].Statements[1].Statements[0].Expression);
    AssertEqual (1, Result);
end


// Testing unary resolves locals.
//
test 'Resolve Unary';
begin
    var TheScanner := Scanner ('{var test = true; var test2 = !test;}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);
end


// Testing binary resolves locals.
//
test 'Resolve Binary';
begin
    var TheScanner := Scanner ('{var test = true; {test = 1 > 2;}}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    var Result := TheInterpreter.Locals.Get (Statements[0].Statements[1].Statements[0].Expression);
    AssertEqual (1, Result);
end


// Testing grouping resolves locals.
//
test 'Resolve Grouping';
begin
    var TheScanner := Scanner ('{var test = true; var test2 = (test);}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);
end


// Tests resolving function and call.
//
test 'Resolve Function and Call';
begin
    var TheScanner := Scanner ('
       {
            fun abc(a, b, c) {
                 test = 1 > 2;
            }
            abc(1, 2, 3);
        }
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    AssertEqual('{VariableExpr instance=0}', Str(TheInterpreter.Locals));
end

// Tests resolving if statements
//
test 'Resolve If';
begin
    var TheScanner := Scanner ('
       {
            var test = 1;
            if (test == 1) {
                test = 2;
            }
            else {
                test = 3;
            }
        }
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    //AssertEqual('{AssignExpr instance=1, VariableExpr instance=0, AssignExpr instance=1}', Str(TheInterpreter.Locals));
end

// Tests resolving while statements
//
test 'Resolve While';
begin
    var TheScanner := Scanner ('
       {
            var test = 1;

            while (test < 10) {
                test = test + 1;
            }
        }
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();
    
    TheResolver.Resolve(Statements);

    //AssertEqual('{VariableExpr instance=1, AssignExpr instance=1, VariableExpr instance=0}', Str(TheInterpreter.Locals));
end


// The resolver should report an error to Lox if a local variable is used in its own initializer.
//
test 'Resolve Local Variable Is Own Initializer';
begin
    var TheScanner := Scanner ('{{ var test = test; }}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();

    try    
        TheResolver.Resolve(Statements);
    except
       on e : String do
            begin
               AssertEqual('Cannot read local variable in its own initializer.', e);
               Exit;
            end
    end
    Fail('No exception thrown.');
end

// The resolver should report an error to Lox if a local variable is declared twice in same scope.
//
test 'Resolve Duplicate Variable';
begin
    var TheScanner := Scanner ('
        fun bad() {
            var a = "first";
            var a = "second";
        } 
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();

    try    
        TheResolver.Resolve(Statements);
    except
       on e : String do
            begin
               AssertEqual('Already a variable with this name in this scope.', e);
               Exit;
            end
    end
    Fail('No exception thrown.');
end

// The resolver should report an error to Lox if a return value is not in a function block.
//
test 'Invalid Return';
begin
    var TheScanner := Scanner ('
        return \"not at top level\"; 
    ');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();

    try    
        TheResolver.Resolve(Statements);
    except
       on e : String do
            begin
               AssertEqual('Cannot return from top-level code.', e);
               Exit;
            end
    end
    Fail('No exception thrown.');
end

 
// The resolver should report an error to Lox if a class tries to inherit from itself.
//
test 'Inherit From Self';
begin
    var TheScanner := Scanner ('class Pie < Pie {}');
    var TheParser := Parser (TheScanner.ScanTokens());
    var TheInterpreter := Interpreter();
    var TheResolver := Resolver(TheInterpreter);

    var Statements := TheParser.Parse();

    try    
        TheResolver.Resolve(Statements);
    except
       on e : String do
            begin
               AssertEqual('A class cannot inherit from itself.', e);
               Exit;
            end
    end
    Fail('No exception thrown.');
end