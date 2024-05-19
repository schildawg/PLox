/// LoxClass
///
class LoxClass;
var
    Name       : String;
    Methods    : Map;
    Superclass : LoxClass;

begin
    /// Creates a new instance.
    ///
    constructor Init (Name : String, Superclass : LoxClass, Methods : Map);
    begin
       this.Name := Name;
       this.Methods := Methods;
       this.Superclass := Superclass;
    end

    /// Finds a method.
    ///
    function FindMethod (Name : String) : LoxFunction;
    begin
        if Methods.Contains (Name) then
        begin
            Exit Methods.Get (Name) as LoxFunction;
        end

        if Superclass <> Nil then
        begin
            Exit Superclass.FindMethod(Name);
        end
    end

    /// Number of parameters in function signature.
    ///
    function Arity () : Integer;
    begin
        Initializer := FindMethod('init');
        if Initializer = Nil then Exit 0;

        Exit Initializer.Arity() as Integer;
    end

    /// To String
    ///
    function ToString () : String;
    begin
        Exit Name;
    end

    /// Creates an instance of the class.
    ///
    function Call (TheInterpreter, Arguments) : Any;
    var
       Instance    : LoxInstance;
       Initializer : LoxFunction;

    begin
        Instance := LoxInstance (this) as LoxInstance;
        Initializer := FindMethod('init');
        if Initializer <> Nil then
        begin
            Initializer.Bind(Instance).Call(Interpreter, Arguments);
        end

        Exit Instance;     
    end  
end