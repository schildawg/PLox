/// Runtime function for Lox!
///
class LoxFunction;
var
    Declaration : FunctionStmt;
    Closure     : Environment;

begin
    /// Creates a new instance.
    ///
    constructor Init (Declaration : FunctionStmt, Closure : Environment);
    begin
       this.Closure := Closure;
       this.Declaration := Declaration;
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
                    Exit e.Value;
                end
        end
    end   
end