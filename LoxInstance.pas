/// LoxInstance
///
class LoxInstance;
var
    Klass  : LoxClass;
    Fields : Map;

begin
    /// Creates a new instance.
    ///
    constructor Init (Klass : LoxClass);
    begin
       this.Klass := Klass;
       this.Fields := Map();
    end

    function Get (Name : Token) : Any;
    var
        Method : LoxFunction;

    begin
        if Fields.Contains (Name.Lexeme) then
        begin
           Exit Fields.Get (Name.Lexeme);
        end

        Method := Klass.FindMethod (Name.Lexeme);
        if Method <> Nil then Exit Method.Bind(this);

        raise 'Undefined property "' + Name.Lexeme + '".';
    end

    procedure Set (Name : Token, Value : Any);
    begin
        Fields.Put (Name.Lexeme, Value);
    end

    /// To String
    ///
    function ToString () : String;
    begin
        Exit Klass.Name + ' instance';
    end
end