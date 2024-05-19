class Stmt;
begin
end

/// Print Statement!
///
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

///  Block Statement!
///
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

/// Expression Statement
///
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

/// Variable Statement!
//
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

/// If Statement!
///
class IfStmt (Stmt);
var
    Condition   : Expr;
    ThenBranch  : Expr; 
    ElseBranch  : Expr; 

begin
    constructor Init (Condition : Expr, ThenBranch : Expr, ElseBranch : Expr);
    begin
        this.Condition := Condition;
        this.ThenBranch := ThenBranch;
        this.ElseBranch := ElseBranch;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitIfStmt(this);
    end   
end

/// While Statement!
///
class WhileStmt (Stmt);
var
    Condition : Expr;
    Body      : Stmt; 

begin
    constructor Init (Condition : Expr, Body : Stmt);
    begin
        this.Condition := Condition;
        this.Body := Body;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitWhileStmt(this);
    end   
end

/// Function Statement!
///
class FunctionStmt (Stmt);
var
    Name   : Token;
    Params : List; 
    Body   : List;

begin
    constructor Init (Name : Token, Params : List, Body : List);
    begin
        this.Name := Name;
        this.Params := Params;
        this.Body := Body;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitFunctionStmt(this);
    end   
end

/// Return Statement!
///
class ReturnStmt (Stmt);
var
    Keyword : Token;
    Value   : Expr; 

begin
    constructor Init (Keyword : Token, Value : Expr);
    begin
        this.Keyword := Keyword;
        this.Value := Value;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitReturnStmt(this);
    end   
end

/// Class Statement!
///
class ClassStmt (Stmt);
var
    Name       : Token;
    Superclass : VariableExpr;
    Methods    : List; 

begin
    constructor Init (Name : Token, Superclass : VariableExpr, Methods : List);
    begin
        this.Name := Name;
        this.Superclass := Superclass;
        this.Methods := Methods;
    end

    function Accept (Visitor);
    begin
       Exit Visitor.VisitClassStmt(this);
    end   
end