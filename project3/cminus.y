/****************************************************/
/* File: tiny.y                                     */
/* The TINY Yacc/Bison specification file           */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/
%{
#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *
char * savedName; /* for use in assignments */
int savedLineNo;  /* ditto */
static TreeNode * savedTree; /* stores syntax tree for later return */
static int yylex(void); // added 11/2/11 to ensure no conflict with lex
%}

%token IF ELSE WHILE RETURN INT VOID
%token ASSIGN EQ NE LT LE GT GE
%token PLUS MINUS TIMES OVER
%token LPAREN RPAREN LBRACE RBRACE LCURLY RCURLY
%token SEMI COMMA NUM ID ERROR

%left ELSE
%left EQ NE
%left LT LE GT GE
%left PLUS MINUS
%left TIMES OVER
%right ASSIGN

%% /* Grammar for TINY */

program
    : declaration_list { savedTree = $1; }
    ;

declaration_list
    : declaration_list declaration
        { YYSTYPE t = $1;
          if (t != NULL) {
              while (t->sibling != NULL) t = t->sibling;
              t->sibling = $2;
              $$ = $1;
          } else $$ = $2; }
    | declaration { $$ = $1; }
    ;

declaration
    : var_declaration
    | fun_declaration
    ;

var_declaration
    : type_specifier ID SEMI
        { $$ = newStmtNode(VarK);
          $$->attr.name = copyString(savedName);
          $$->type = $1->type;
          $$->lineno = lineno; }
    | type_specifier ID LBRACE size RBRACE SEMI
        { $$ = newStmtNode(VarK);
          $$->attr.name = copyString(savedName);
          $$->type = $1->type;
          $$->child[0] = newExpNode(ConstK);
          $$->child[0]->attr.val = $4->attr.val;
          $$->lineno = lineno; }
    ;
size : NUM {
          $$ = newExpNode(ConstK);
          $$->attr.val = atoi(tokenString);
          $$->lineno = savedLineNo;
          }
          ;
type_specifier
    : INT { $$ = newExpNode(ConstK); $$->type = Integer; }
    | VOID { $$ = newExpNode(ConstK); $$->type = Void; }
    ;

fun_declaration
    : type_specifier identifier LPAREN params RPAREN compound_stmt
        { $$ = newStmtNode(FuncK);
          $$->attr.name = $2->attr.name;
          $$->type = $1->type;
          $$->child[0] = $4;
          $$->child[1] = $6;
          $$->lineno = savedLineNo;
        }
    ;
identifier : ID {
        { $$ = newExpNode(IdK);
          $$->attr.name = copyString(savedName);
          $$->lineno = savedLineNo; }
        };
params
    : param_list
    ;

param_list
    : param_list COMMA param
        { YYSTYPE t = $1;
          if (t != NULL) {
              while (t->sibling != NULL) t = t->sibling;
              t->sibling = $3;
              $$ = $1;
          } else $$ = $3; }
    | param { $$ = $1; }
    ;

param
    : type_specifier ID
        { $$ = newStmtNode(ParamK);
          $$->attr.name = copyString(savedName);
          $$->type = $1->type;
          $$->lineno = savedLineNo; }
    | type_specifier ID LBRACE RBRACE
        { $$ = newStmtNode(ParamK);
          $$->attr.name = copyString(savedName);
          $$->type = $1->type; 
          $$->lineno = savedLineNo; }
    | VOID {$$ = newStmtNode(ParamK);
            $$->type = Void;    
            $$->lineno = savedLineNo;
        }
    ;

compound_stmt
    : LCURLY local_declarations statement_list RCURLY
        { $$ = newStmtNode(CompoundK);
          $$->child[0] = $2;
          $$->child[1] = $3;
          $$->lineno = savedLineNo; }
    ;

local_declarations
    : local_declarations var_declaration
        { YYSTYPE t = $1;
          if (t != NULL) {
              while (t->sibling != NULL) t = t->sibling;
              t->sibling = $2;
              $$ = $1;
          } else $$ = $2; }
    | { $$ = NULL; }
    ;

statement_list
    : statement_list statement
        { YYSTYPE t = $1;
          if (t != NULL) {
              while (t->sibling != NULL) t = t->sibling;
              t->sibling = $2;
              $$ = $1;
          } else $$ = $2; }
    | { $$ = NULL; }
    ;

statement
    : expression_stmt
    | compound_stmt
    | selection_stmt
    | iteration_stmt
    | return_stmt
    ;

expression_stmt
    : exp SEMI { $$ = $1; }
    | SEMI { $$ = NULL; }
    ;

selection_stmt
    : IF LPAREN exp RPAREN statement 
        { $$ = newStmtNode(IfK);
          $$->child[0] = $3;
          $$->child[1] = $5;
          $$->lineno = savedLineNo; }
    | IF LPAREN exp RPAREN statement ELSE statement
        { $$ = newStmtNode(IfK);
          $$->child[0] = $3;  
          $$->child[1] = $5; 
          $$->child[2] = $7;  
          $$->lineno = savedLineNo; } 
    ;

iteration_stmt
    : WHILE LPAREN exp RPAREN statement
        { $$ = newStmtNode(WhileK);
          $$->child[0] = $3;
          $$->child[1] = $5;
          $$->lineno = savedLineNo; }
    ;

return_stmt
    : RETURN SEMI
        { $$ = newStmtNode(ReturnK);
          $$->lineno = savedLineNo; }
    | RETURN exp SEMI
        { $$ = newStmtNode(ReturnK);
          $$->child[0] = $2;
          $$->lineno = savedLineNo; }
    ;
var
    : ID
        { $$ = newExpNode(IdK);
          $$->attr.name = copyString(savedName);
          $$->lineno = savedLineNo; }
    | ID LBRACE exp RBRACE
        { $$ = newExpNode(IdK);
          $$->attr.name = copyString(savedName);
          $$->attr.val = $3->attr.val;
          $$->child[0] = $3;
          $$->lineno = savedLineNo; }
    ;
exp
    : var ASSIGN exp
        { $$ = newStmtNode(AssignK);
          $$->child[0] = $1;
          $$->child[1] = $3;
          $$->lineno = savedLineNo; }
    | simple_expression { $$ = $1; }
    ;

simple_expression
    : additive_expression relop additive_expression
        { $$ = newExpNode(OpK);
          $$->child[0] = $1;
          $$->child[1] = $3;
          $$->attr.op = $2->attr.op;
          $$->lineno = savedLineNo; }
    | additive_expression { $$ = $1; }
    ;

relop
    : LT { $$ = newExpNode(OpK);
           $$->attr.op = LT; 
           $$->lineno = savedLineNo; }
    | LE { $$ = newExpNode(OpK);
           $$->attr.op = LE; 
           $$->lineno = savedLineNo; }
    | GT { $$ = newExpNode(OpK);
           $$->attr.op = GT; 
           $$->lineno = savedLineNo; }
    | GE { $$ = newExpNode(OpK);
           $$->attr.op = GE; 
           $$->lineno = savedLineNo; }
    | EQ { $$ = newExpNode(OpK);
           $$->attr.op = EQ; 
           $$->lineno = savedLineNo; }
    | NE { $$ = newExpNode(OpK);
           $$->attr.op = NE; 
           $$->lineno = savedLineNo; }
    ;

additive_expression
    : additive_expression addop term
        { $$ = newExpNode(OpK);
          $$->child[0] = $1;
          $$->child[1] = $3;
          $$->attr.op = $2->attr.op;
          $$->lineno = savedLineNo; }
    | term { $$ = $1; }
    ;

addop
    : PLUS  { $$ = newExpNode(OpK);
             $$->attr.op = PLUS;$$->lineno = savedLineNo; }
    | MINUS { $$ = newExpNode(OpK);
              $$->attr.op = MINUS;$$->lineno = savedLineNo; }
    ;

term
    : term mulop factor
        { $$ = newExpNode(OpK);
          $$->child[0] = $1;
          $$->child[1] = $3;
          $$->attr.op = $2->attr.op;
          $$->lineno = savedLineNo; }
    | factor { $$ = $1; }
    ;

mulop
    : TIMES { $$ = newExpNode(OpK);
              $$->attr.op = TIMES;$$->lineno = savedLineNo; }
    | OVER { $$ = newExpNode(OpK);
              $$->attr.op = OVER;$$->lineno = savedLineNo; }
    ;

factor
    : LPAREN exp RPAREN { $$ = $2; }
    | var { $$ = $1; }
    | call { $$ = $1; }
    | NUM
        { $$ = newExpNode(ConstK);
          $$->attr.val = atoi(tokenString);
          $$->lineno = savedLineNo; }
    ;

call
    : identifier LPAREN args RPAREN
        { $$ = newStmtNode(CallK);
          $$->attr.name = $1->attr.name;
          $$->child[0] = $3;
          $$->lineno = savedLineNo; 
        }
    ;

args
    : arg_list
    | { $$ = NULL; }
    ;

arg_list
    : arg_list COMMA exp
        { YYSTYPE t = $1;
          if (t != NULL) {
              while (t->sibling != NULL) t = t->sibling;
              t->sibling = $3;
              $$ = $1;
          } else $$ = $3; }
    | exp { $$ = $1; }
    ;


%%

int yyerror(char * message)
{ fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
  fprintf(listing,"Current token: ");
  printToken(yychar,tokenString);
  Error = TRUE;
  return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the TINY scanner
 */
static int yylex(void)
{ return getToken();}

TreeNode * parse(void)
{ yyparse();
  return savedTree;
}

