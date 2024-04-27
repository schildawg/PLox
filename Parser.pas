class Parser;
begin
    constructor Init(Tokens);
    begin
       this.Tokens := Tokens;
       this.Current := 0;
    end

    function Expression();
    begin
       WriteLn('Hello Wisconsin!!!');
    end
end