 /// Prints an Abstract Syntax Tree!!!
 //
 class AstPrinter;
 begin
    function DoPrint(Expr);
    begin
        Exit Expr.Accept(this);
    end

    function VisitBinary(Expr);
    begin
       var Exprs := List();
       Exprs.Add(Expr.Left);
       Exprs.Add(Expr.Right);

       Exit Parenthesize(Expr.Op.Lexeme, Exprs);
    end

    function VisitGrouping(Expr);
    begin
       var Exprs := List();
       Exprs.Add(Expr.Expr);

       Exit Parenthesize('group', Exprs);
    end

    function VisitLiteral(Expr);
    begin
       if Expr.Value = nil then Exit nil;
       Exit Str(Expr.Value);
    end

    function VisitUnary(Expr);
    begin
       var Exprs := List();
       Exprs.Add(Expr.Value);

       Exit Parenthesize(Expr.Op.Lexeme, Exprs);
    end

// private
    function Parenthesize(Name, Exprs);
    begin
        var Builder := Str('(') + Name;
        for var I := 0; I < Exprs.Length; I := I + 1 do
        begin
            Builder := Builder + ' ';
            Builder := Builder + Exprs[I].Accept(this);
        end
        Builder := Builder + ')';

        Exit Builder;
    end   
 end

 test 'Test AST Printer';
 begin
     var Expression := 
        BinaryExpr(
            UnaryExpr(
                Token(TOKEN_MINUS, '-', nil, 1), 
                LiteralExpr(123)),
            Token(TOKEN_STAR, '*', nil, 1),
            GroupingExpr(
                LiteralExpr(45.67)));

    var Printer := AstPrinter();

    AssertEqual('(* (- 123) (group 45.67))', Printer.DoPrint(Expression));
end
