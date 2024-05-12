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
var
    Expression : Expr;

begin
    constructor Init(Expression : Expr);
    begin
        this.Expression := Expression;
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
    Value : Expr;
    
begin
    constructor Init(Value : Expr);
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
var
   Op    : Token;
   Right : Expr;

begin
    constructor Init(Op : Token, Right : Expr);
    begin
        this.Op := Op;
        this.Right := Right;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitUnary(this);
    end
end

test 'Test Literals' ;
begin
   
end
  