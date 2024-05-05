
var  Keywords := [
    'and':TOKEN_AND, 'class':TOKEN_CLASS, 'else':TOKEN_ELSE, 'false':TOKEN_FALSE, 'for':TOKEN_FOR, 'fun':TOKEN_FUN,
    'if':TOKEN_IF, 'nil':TOKEN_NIL, 'or':TOKEN_OR, 'print':TOKEN_PRINT, 'return':TOKEN_RETURN, 'super':TOKEN_SUPER, 
    'this':TOKEN_THIS, 'true':TOKEN_TRUE, 'var':TOKEN_VAR, 'while':TOKEN_WHILE];

var HadError := False;
var LastError;

/// Scanner
///
class Scanner;
var 
    Source : String;
    Tokens : List; // of Token

    Current, Start, Line : Integer;

begin
    /// Creates a new Scanner
    ///
    constructor Init(Source);
    begin
        this.Source  := Source;
        this.Current := 0;
        this.Start   := 0;
        this.Line    := 1;

        this.Tokens := List();
    end

    /// Scans Tokens
    ///
    function ScanTokens() : List; // of Token
    begin
        while not IsAtEnd() do
        begin
           Start := Current;
           ScanToken();
        end

        Tokens.Add(Token(EOF, '', nil, Line));
        exit Tokens;
    end

    // Scan Token
    //
    procedure ScanToken();
    var 
        C : Char;

    begin
        C := Advance();   
        case C of
            '(' : AddToken(TOKEN_LEFT_PAREN);
            ')' : AddToken(TOKEN_RIGHT_PAREN);
            '{' : AddToken(TOKEN_LEFT_BRACE);
            '}' : AddToken(TOKEN_RIGHT_BRACE);
            ',' : AddToken(TOKEN_COMMA);
            '.' : AddToken(TOKEN_DOT);
            '-' : AddToken(TOKEN_MINUS);
            '+' : AddToken(TOKEN_PLUS);
            ';' : AddToken(TOKEN_SEMICOLON);
            '*' : AddToken(TOKEN_STAR);

            '!' : if Match('=') then AddToken(TOKEN_BANG_EQUAL); else AddToken(TOKEN_BANG);
            '=' : if Match('=') then AddToken(TOKEN_EQUAL_EQUAL); else AddToken(TOKEN_EQUAL);
            '<' : if Match('=') then AddToken(TOKEN_LESS_EQUAL); else AddToken(TOKEN_LESS);
            '>' : if Match('=') then AddToken(TOKEN_GREATER_EQUAL); else AddToken(TOKEN_GREATER);

            // Comments
            '/':
                if Match('/') then 
                   while Peek() <> #13 and not IsAtEnd() do Advance();
                else 
                   AddToken(TOKEN_SLASH);

            // Skip whitespace
            #9, #10, ' ' : Exit;

            #13 : 
                begin
                   Line := Line + 1;
                   Exit;
                end
            '"' : ScanString();
        else
            if IsAlpha(C) then
                ScanIdentifier();
            else if IsDigit(C) then
                ScanNumber();
            else 
                begin
                    HadError := True;
                    LastError := '[line ' + Line + '] Unrecognized character: ' + C + '.';
                end
        end  
    end

    // Scans an Identifier.
    //
    procedure ScanIdentifier();
    var 
       Text        : String;
       TypeOfToken : Any;  // TODO: TokenType

    begin
        while IsAlphaNumeric(Peek()) do Advance();

        Text := Copy(Source, Start, Current);   
        TypeOfToken := TOKEN_IDENTIFIER;

        if Keywords.Contains(Text) then
        begin
            TypeOfToken := Keywords.Get(Text); 
        end

        AddToken(TypeOfToken);        
    end

    // Scans a Number
    //
    procedure ScanNumber();
    begin
        while IsDigit(Peek()) do Advance();

        // look for a fractional part.
        if Peek() = '.' and IsDigit(PeekNext()) then Advance();

        while IsDigit(Peek()) do Advance();

        AddToken(TOKEN_NUMBER, Copy(Source, Start, Current));
    end

    // Scans a String
    //
    procedure ScanString();
    var 
       Value : String;

    begin
        while Peek() <> '"' and not IsAtEnd() do
        begin
            if Peek() = #13 then Line := Line + 1;
            Advance();
        end

        if IsAtEnd() then
        begin
            HadError := True;
            LastError := '[line ' + Line + '] Error : Unterminated string.';
            Exit;
        end
        Advance();

        // Trim the surrounding quotes
        Value := Copy(Source, Start + 1, Current - 1);

        AddToken(TOKEN_STRING, Value);
    end

    // Does the character match?  
    //
    function Match(Expected : Char) : Boolean;
    begin
        if IsAtEnd() then Exit False; 
        if Source[Current] <> Expected then Exit False;

        Current := Current + 1;
        Exit True;
    end

    // Returns the current character.
    //
    function Peek();
    begin
        if IsAtEnd() then exit #0;

        exit Source[Current];
    end

    // Returns the next character.
    //
    function PeekNext() : Char;
    begin
       if Current + 1 > Length(Source) then exit #0;
       
       exit Source[Current + 1];
    end

    // Adds a Token.
    //
    procedure AddToken(TypeOfToken : TokenType);
    begin
        AddToken(TypeOfToken, nil);
    end

    // Adds a Token.
    //
    procedure AddToken(TypeOfToken : TokenType, Literal : Any);
    var
       Text : String;

    begin
        Text := Copy(Source, Start, Current);
        Tokens.Add(Token(TypeOfToken, Text, Literal, Line));
    end

    // Is at the end?
    //
    function IsAtEnd();
    begin
        Exit Current >= Length(Source);
    end

    // Advance the current character.
    //
    function Advance() : Char;
    var 
       ReturnValue : Char;

    begin
        ReturnValue := Source[Current];
        Current := Current + 1;
        
        Exit ReturnValue;
    end

    // Is the character alphabetic?
    //
    function IsAlpha(C : Char) : Boolean;
    begin
        Exit (C >= 'a' and C <= 'z') or
             (C >= 'A' and C <= 'Z') or 
             (C = '_');
    end

    // Is the character alphanumeric?
    //
    function IsAlphaNumeric(C : Char) : Boolean;
    begin
        Exit IsAlpha(C) or IsDigit(C);
    end

    // Is the character a digit?
    //
    IsDigit(C : Char);
    begin
       Exit C >= '0' and C <= '9';
    end
end

// Scans each of the single character tokens, verifying the correct token types are returned, and ends
// with an EOF.
//
test 'Scan Tokens';
begin
    var Uut := Scanner('(){},.-+;*');

    Uut.ScanTokens();

    AssertEqual(TOKEN_LEFT_PAREN,  Uut.Tokens[0].TypeOfToken);
    AssertEqual(TOKEN_RIGHT_PAREN, Uut.Tokens[1].TypeOfToken);

    AssertEqual(TOKEN_LEFT_BRACE,  Uut.Tokens[2].TypeOfToken);
    AssertEqual(TOKEN_RIGHT_BRACE, Uut.Tokens[3].TypeOfToken);

    AssertEqual(TOKEN_COMMA, Uut.Tokens[4].TypeOfToken);
    AssertEqual(TOKEN_DOT,   Uut.Tokens[5].TypeOfToken);
    AssertEqual(TOKEN_MINUS, Uut.Tokens[6].TypeOfToken);
    AssertEqual(TOKEN_PLUS,  Uut.Tokens[7].TypeOfToken);

    AssertEqual(TOKEN_SEMICOLON,  Uut.Tokens[8].TypeOfToken);
    AssertEqual(TOKEN_STAR,       Uut.Tokens[9].TypeOfToken);

    AssertEqual(EOF,  Uut.Tokens[10].TypeOfToken);
end

// Scans the two character operators, verifying the correct token types are returned.  Also checks that 
// the individual characters continue to be scanned properly.  Implicitly checks that whitespace is ignored.
//
test 'Scan Operators';
begin
    var Uut := Scanner('! = < > != == <= >=');

    Uut.ScanTokens();

    AssertEqual(TOKEN_BANG,  Uut.Tokens[0].TypeOfToken);
    AssertEqual(TOKEN_EQUAL, Uut.Tokens[1].TypeOfToken);

    AssertEqual(TOKEN_LESS,    Uut.Tokens[2].TypeOfToken);
    AssertEqual(TOKEN_GREATER, Uut.Tokens[3].TypeOfToken);
    
    AssertEqual(TOKEN_BANG_EQUAL,    Uut.Tokens[4].TypeOfToken);
    AssertEqual(TOKEN_EQUAL_EQUAL,   Uut.Tokens[5].TypeOfToken);
    AssertEqual(TOKEN_LESS_EQUAL,    Uut.Tokens[6].TypeOfToken);
    AssertEqual(TOKEN_GREATER_EQUAL, Uut.Tokens[7].TypeOfToken);

    AssertEqual(EOF, Uut.Tokens[8].TypeOfToken);
end

// Tests that a comment is ignored until the end of a line.
//
test 'Scan Comment';
begin
    var Uut := Scanner('// This is a comment.');
    
    Uut.ScanTokens();

    AssertEqual(EOF, Uut.Tokens[0].TypeOfToken);
end

// Test that the line counter is increased when scanning an end-of-line character (\n).
//
test 'Scan Newline';
begin
    var Uut := Scanner('test ' + #13 +  'test2');
    
    Uut.ScanTokens();

    AssertEqual(1, Uut.Tokens[0].LineNumber);
    AssertEqual(2, Uut.Tokens[1].LineNumber);
end

// Test that quotation mark returns a String token type, with a lexeme including the quotation marks, and 
// the literal value a String object without them.
//
test 'Scan String';
begin
    var Uut := Scanner('"ABC"');
    
    Uut.ScanTokens();

    var Token := Uut.Tokens[0];

    AssertEqual(TOKEN_STRING, Token.TypeOfToken);
    AssertEqual('"ABC"', Token.Lexeme);
    AssertEqual('ABC', Token.Literal);
end

// If the end of the file is reached without a terminating quotation mark, an error should be sent to 
// Lox.
// 
test 'Scan Unterminated String';
begin
    var Uut := Scanner('"ABC');
    
    Uut.ScanTokens();

    AssertTrue(HadError);
    AssertEqual('[line 1] Error : Unterminated string.', LastError);
end

// Tests that scanning a series of numbers returns a Number object, with the String value in lexeme.
//
test 'Scan Number';
begin
    var Uut := Scanner('123');
    
    Uut.ScanTokens();

    var Token := Uut.Tokens[0];

    AssertEqual(TOKEN_NUMBER, Token.TypeOfToken);
    AssertEqual('123', Token.Lexeme);

    // FIXME
    AssertEqual('123', Token.Literal);
end

// If a period is encountered while scanning numbers, it should scan for additional numbers for a decimal
// value.  Returns a Number with the String value in lexeme.
//
test 'Scan Number Decimal';
begin
    var Uut := Scanner('3.14');
    
    Uut.ScanTokens();

    var Token := Uut.Tokens[0];

    AssertEqual(TOKEN_NUMBER, Token.TypeOfToken);
    AssertEqual('3.14', Token.Lexeme);

    // FIXME
    AssertEqual('3.14', Token.Literal);
end

// Test scanning an identifier.  The lexeme should contain the name, and the literal value should be None.
//
test 'Scan Identifier';
begin
    var Uut := Scanner('test');
    
    Uut.ScanTokens();

    var Token := Uut.Tokens[0];

    AssertEqual(TOKEN_IDENTIFIER, Token.TypeOfToken);
    AssertEqual('test', Token.Lexeme);

    // TODO: Add AssertNil
    AssertEqual(nil, Token.Literal);
end

// Tests that all of Lox's keywords are properly distinguished from identifiers.
//
test 'Scan Keywords';
begin
    var Uut := Scanner('and class else false for fun if nil or print return super this true var while');
    
    Uut.ScanTokens();

    AssertEqual(TOKEN_AND,    Uut.Tokens[0].TypeOfToken);
    AssertEqual(TOKEN_CLASS,  Uut.Tokens[1].TypeOfToken);
    AssertEqual(TOKEN_ELSE,   Uut.Tokens[2].TypeOfToken);
    AssertEqual(TOKEN_FALSE,  Uut.Tokens[3].TypeOfToken);
    AssertEqual(TOKEN_FOR,    Uut.Tokens[4].TypeOfToken);
    AssertEqual(TOKEN_FUN,    Uut.Tokens[5].TypeOfToken);
    AssertEqual(TOKEN_IF,     Uut.Tokens[6].TypeOfToken);
    AssertEqual(TOKEN_NIL,    Uut.Tokens[7].TypeOfToken);
    AssertEqual(TOKEN_OR,     Uut.Tokens[8].TypeOfToken);
    AssertEqual(TOKEN_PRINT,  Uut.Tokens[9].TypeOfToken);
    AssertEqual(TOKEN_RETURN, Uut.Tokens[10].TypeOfToken);
    AssertEqual(TOKEN_SUPER,  Uut.Tokens[11].TypeOfToken);
    AssertEqual(TOKEN_THIS,   Uut.Tokens[12].TypeOfToken);
    AssertEqual(TOKEN_TRUE,   Uut.Tokens[13].TypeOfToken);
    AssertEqual(TOKEN_VAR,    Uut.Tokens[14].TypeOfToken);
    AssertEqual(TOKEN_WHILE,  Uut.Tokens[15].TypeOfToken);
    AssertEqual(EOF,          Uut.Tokens[16].TypeOfToken);
end

// Should report an error to Lox if an unexpected character is scanned.
///
test 'Scan Unexpected String';
begin
    var Uut := Scanner(Str('%'));
    
    Uut.ScanTokens();

    AssertTrue(HadError);
    AssertEqual('[line 1] Unrecognized character: %.', LastError);
end