class Expr;
begin
end

/// Binary!
///
class BinaryExpr (Expr);
var
   Left  : Any;
   Op    : Any;
   Right : Any;
   
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
class GroupingExpr (Expr);
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
class LiteralExpr (Expr);
var
    Value : Any;
    
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
class UnaryExpr (Expr);
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
  