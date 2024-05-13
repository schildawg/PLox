class Stmt;
begin
end

class PrintStmt (Stmt);
var
    Expression : Expr;

begin
    constructor Init (Expression : Expr);
    begin
        this.Expression := Expression;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitPrintStmt(this);
    end   
end

class BlockStmt (Stmt);
var
    Statements : List of Statement;

begin
    constructor Init (Statements : List);
    begin
        this.Statements := Statements;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitBlockStmt(this);
    end   
end

class ExpressionStmt (Stmt);
var
    Expression : Expr;

begin
    constructor Init (Expression : Expr);
    begin
        this.Expression := Expression;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitExpressionStmt(this);
    end   
end

class VarStmt (Stmt);
var
    Name        : Token;
    Initializer : Expr; 

begin
    constructor Init (Name : Token, Initializer : Expr);
    begin
        this.Name := Name;
        this.Initializer := Initializer;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitVarStmt(this);
    end   
end