/// Token
///
class Token;
var 
   TypeOfToken : Any;
   Lexeme      : String;
   Literal     : Any;
   LineNumber  : Integer;

begin
    constructor Init(TypeOfToken, Lexeme, Literal, LineNumber);
    begin
        this.TypeOfToken := TypeOfToken;
        this.Lexeme := Lexeme;
        this.Literal := Literal;
        this.LineNumber := LineNumber;
    end

    function ToString() : String;
    begin
       Exit Str(TypeOfToken) +  ' ' + Lexeme + ' ' + Literal;
    end
end

test 'New Token';
begin
    var TheToken := Token(TOKEN_STRING, 'ABC', nil, 1);
    
    AssertEqual(TOKEN_STRING, TheToken.TypeOfToken);
    AssertEqual('ABC', TheToken.Lexeme);
    AssertEqual(nil, TheToken.Literal);
    AssertEqual(1, TheToken.LineNumber); 
end

test 'Token ToString';
begin
    var TheToken := Token(TOKEN_STRING, 'ABC', nil, 1);
    
    AssertEqual('TOKEN_STRING ABC nil', TheToken.ToString());
end