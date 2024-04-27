/// Token
///
class Token;
begin
    constructor Init(TypeOfToken, Lexeme, Literal, LineNumber);
    begin
        this.TypeOfToken := TypeOfToken;
        this.Lexeme := Lexeme;
        this.Literal := Literal;
        this.LineNumber := LineNumber;
    end

    function ToString();
    begin
       Exit Str(TypeOfToken) +  ' ' + Lexeme + ' ' + Literal;
    end
end

// Tests creating a new Token.
//
test 'New Token';
begin
    var TheToken := Token(TOKEN_STRING, 'ABC', nil, 1);
    
    AssertEqual(TOKEN_STRING, TheToken.TypeOfToken);
    AssertEqual('ABC', TheToken.Lexeme);
    AssertEqual(nil, TheToken.Literal);
    AssertEqual(1, TheToken.LineNumber); 
end

// Tests Token's ToString() method.
//
test 'Token ToString';
begin
    var TheToken := Token(TOKEN_STRING, 'ABC', nil, 1);
    
    AssertEqual('TOKEN_STRING ABC nil', TheToken.ToString());
end