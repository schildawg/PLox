/// Environment!
///
class Environment;
begin
    constructor Init ();
    begin
       this.Values := Map();
       this.Enclosing := Nil;
    end

    /// Defines a variable at the local scope.
    ///
    procedure Define (Name : String, Value : Any);
    begin
        Values.Put (Str(Name), Value);
    end

    /// Assigns a value to an existing variable.  Walks up the enclosing Environments until it finds the variable defined.
    ///
    /// # Errors
    ///
    /// Returns a runtime error if reaches the top-level environment (Enclosing is Nil) and does not find the variable.
    ///
    procedure Assign (Name : Token, Value : Any);
    begin
        if Values.Contains(Name.Lexeme) then
        begin
            Values.Put (Str(Name.Lexeme), Value);
            Exit;
        end
        if Enclosing <> Nil then 
        begin
            Enclosing.Assign(Name, Value);
            Exit;
        end

        raise 'Undefined variable "' + Name.Lexeme + '".';
    end

    /// Gets a variable from the local scope, or looks in the enclosing environment.
    ///
    /// # Errors
    ///
    /// Returns a runtime error if reaches the top-level environment and does not find the variable.
    ///
    function Get (Name : Token) : Any;
    begin
        if Values.Contains( Str(Name.Lexeme)) then
        begin
            Exit Values.Get (Str(Name.Lexeme));
        end
        if Enclosing <> Nil then Exit Enclosing.Get(Name);

        raise 'Undefined variable "' + Name.Lexeme + '".'; 
    end
end

// Tests creating an environment, defining a variable and retrieving it.
//
test 'Test Environment';
begin
    var Env := Environment();

    Env.Define ('test', 1.0);

    var TheToken := Token(TOKEN_IDENTIFIER, 'test', Nil, 0);

    var Result := Env.Get (TheToken);
    AssertEqual(1.0, Result);
end

// A variable defined in an environment should be able to be accessed from a lower scope.
//
test 'Test Environment Two Deep';
begin
    var Globals := Environment();
    Globals.Define ('test', 1.0);

    var Env := Environment();
    Env.Enclosing := Globals;
    Env.Define ('test', 2.0);

    var TheToken := Token(TOKEN_IDENTIFIER, 'test', Nil, 0);

    AssertEqual(2.0, Env.Get (TheToken));
    AssertEqual(1.0, Globals.Get (TheToken));
end


// Too often something goes wrong at 3 :)  So we are checking that a variable can be accessed from a scope three
// levels deep.
test 'Test Environment Three Deep';
begin
    var Globals := Environment();
    Globals.Define ('test', 1.0);

    var Env := Environment();
    Env.Enclosing := Globals;

    var InnerEnv := Environment();
    InnerEnv.Enclosing := Env;

    var TheToken := Token(TOKEN_IDENTIFIER, 'test', Nil, 0);

    AssertEqual(1.0, InnerEnv.Get (TheToken));
end

// Assigning a value to a defined variable should change the value returned from Get().
//
test 'Test Environment Assign';
begin
    var Globals := Environment();
    Globals.Define ('test', 1.0);

    var Env := Environment();
    Env.Enclosing := Globals;

    var TheToken := Token(TOKEN_IDENTIFIER, 'test', Nil, 0);

    Env.Assign(TheToken, 2.0);

    AssertEqual(2.0, Env.Get (TheToken));
end

// Attempting to assign a value to an identifier with no variable defined should return a runtime error.
//
test 'Test Environment Assign Not Defined';
begin
    var Env := Environment();
    var TheToken := Token(TOKEN_IDENTIFIER, 'test', Nil, 0);
    try
        Env.Assign(TheToken, 2.0);
    except
        on e : String do
            begin
                AssertEqual('Undefined variable "test".', e);
                Exit;
            end
    end
    Fail ('No exception thrown.');
end

// Attempting to get a value that is not defined should return a runtime error.
//
test 'Test Environment Get Not Defined';
begin
    var Env := Environment();
    var TheToken := Token(TOKEN_IDENTIFIER, 'test', Nil, 0);
    
    try
        Env.Get(TheToken);
    except
        on e : String do
            begin
                AssertEqual('Undefined variable "test".', e);
                Exit;
            end
    end
    Fail ('No exception thrown.');
end