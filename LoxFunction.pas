/// Runtime function for Lox!
///
class LoxFunction;
var
    Declaration   : FunctionStmt;
    Closure       : Environment;
    IsInitializer : Boolean;

begin
    /// Creates a new instance.
    ///
    constructor Init (Declaration : FunctionStmt, Closure : Environment, IsInitializer : Boolean);
    begin
       this.Closure := Closure;
       this.Declaration := Declaration;
       this.IsInitializer := IsInitializer;
    end

    /// Binds this method to an instance.
    ///
    function Bind (Instance : LoxInstance) : LoxFunction;
    var
        Env : Environment;

    begin
        Env := Environment();
        Env.Enclosing := Closure;
        Env.Define ('this', Instance);

        Exit LoxFunction (Declaration, Env, IsInitializer);
    end

    /// Number of parameters in function signature.
    ///
    function Arity () : Integer;
    begin
        if Declaration.Params = Nil then Exit 0;
        
        Exit Declaration.Params.Length;
    end

    /// To String
    ///
    function ToString () : String;
    begin
        Exit '<fn ' + Declaration.Name.Lexeme + '>';
    end

    /// Runs the function.
    ///
    function Call (TheInterpreter, Arguments) : Any;
    var
        Env   : Environment;
        Count : Integer;

    begin
        Env := Environment();
        Env.Enclosing := Closure;

        for var I := 0; I < Declaration.Params.Length; I := I + 1 do
        begin
            Env.Define (Declaration.Params[I].Lexeme, Arguments[I]);
        end
        
        try 
           TheInterpreter.ExecuteBlock (Declaration.Body, Env);
        except
            on e : Return do
                begin
                    if IsInitializer then Exit Closure.GetAt (0, 'this');
                    Exit e.Value;
                end
        end

        if IsInitializer then Exit Closure.GetAt(0, 'this');
    end   
end