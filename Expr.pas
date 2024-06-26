class Expr;
begin
end

/// Binary Expression!
///
class BinaryExpr (Expr);
var
   Left  : Expr;
   Op    : Token;
   Right : Expr;
   
begin
    constructor Init(Left, Op, Right);
    begin
        this.Left := Left;
        this.Op := Op;
        this.Right := Right;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitBinary(this);
    end
end

/// Logical Expression!
///
class LogicalExpr (Expr);
var
   Left  : Expr;
   Op    : Token;
   Right : Expr;
   
begin
    constructor Init(Left, Op, Right);
    begin
        this.Left := Left;
        this.Op := Op;
        this.Right := Right;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitLogical(this);
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

/// Literal Expression!
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

/// Variable Expression!
///
class VariableExpr (Expr);
var
    Name : Token;
    
begin
    constructor Init(Name : Token);
    begin
        this.Name := Name;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitVariableExpr (this);
    end
end

/// Assign Expression!
///
class AssignExpr (Expr);
var
    Name  : Token;
    Value : Expr;
    
begin
    constructor Init(Name : Token, Value : Expr);
    begin
        this.Name := Name;
        this.Value := Value;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitAssignExpr (this);
    end
end

/// Unary Expression!
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

/// Call Expression!
///
class CallExpr (Expr);
var
    Callee     : Expr;
    Paren      : Token;
    Arguments  : List;

begin
    constructor Init(Callee : Expr, Paren : Token, Arguments : List);
    begin
        this.Callee := Callee;
        this.Paren := Paren;
        this.Arguments := Arguments;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitCall(this);
    end
end

/// Get Expression!
///
class GetExpr (Expr);
var
    Object : Expr;
    Name   : Token;

begin
    constructor Init(Object : Expr, Name : Token);
    begin
        this.Object := Object;
        this.Name := Name;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitGetExpr(this);
    end
end

/// Set Expression!
///
class SetExpr (Expr);
var
    Object : Expr;
    Name   : Token;
    Value  : Expr;  

begin
    constructor Init(Object : Expr, Name : Token, Value : Expr);
    begin
        this.Object := Object;
        this.Name := Name;
        this.Value := Value;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitSetExpr(this);
    end
end

/// This Expression!
///
class ThisExpr (Expr);
var
    Keyword : Token;
    
begin
    constructor Init(Keyword : Token);
    begin
        this.Keyword := Keyword;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitThisExpr (this);
    end
end

/// Super Expression!
///
class SuperExpr (Expr);
var
    Keyword : Token;
    Method  : Token;

begin
    constructor Init(Keyword : Token, Method : Token);
    begin
        this.Keyword := Keyword;
        this.Method := Method;
    end

    function Accept(Visitor);
    begin
       Exit Visitor.VisitSuperExpr (this);
    end
end
