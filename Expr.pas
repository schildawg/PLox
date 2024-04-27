/// Binary!
///
class BinaryExpr;
begin
    constructor Init(Left, Op, Right);
    begin
        this.Left := Left;
        this.Op := Op;
        this.Right := Right;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitBinary(this);
    end
end

/// Grouping!
///
class GroupingExpr;
begin
    constructor Init(Expr);
    begin
        this.Expr := Expr;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitGrouping(this);
    end
end

/// Literal!
///
class LiteralExpr;
begin
    constructor Init(Value);
    begin
        this.Value := Value;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitLiteral(this);
    end
end

/// Unary!
///
class UnaryExpr;
begin
    constructor Init(Op, Value);
    begin
        this.Op := Op;
        this.Value := Value;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitUnary(this);
    end
end

test 'Test Literals' ;
begin
   
end
  