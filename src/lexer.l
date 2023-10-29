%option noyywrap
%option nounput
%option noinput
%top{
    #include <stdarg.h>
    #include "common.h"

    #include <stack>
    #include <string>
    #include <ostream>
    #include <fstream>
    #include <malloc.h>
    #include <unordered_map>
    using namespace std;
}
%{
    extern dump_type_t dump_type;

    inline void dump_tokens(const char* format, ...){
        va_list args;
        va_start(args, format);
        if (dump_type == TOKENS)
            vfprintf(yyout, format, args);
        va_end(args);
    }

    /* Your code here, if desired (lab3). */ 
    
    char* temp_type;
    int valid;
    int yycolumn = 1;

    typedef struct 
    {
        char* name;
        char* type;
        int scope; // 定义域
    } SymbolTableEntry;

    #define MAX_ENTRIES 1000
    SymbolTableEntry symbolTable[MAX_ENTRIES];
    int currentScope = 0;


    typedef struct {
        SymbolTableEntry symbolTable[MAX_ENTRIES];
        int tableIndex;
    } SymbolTable;


    #define MAX_STACK_SIZE 100
    SymbolTable* symbolTableStack[MAX_STACK_SIZE];
    int stackTop = -1;

    void pushSymbolTable() {
        SymbolTable* newSymbolTable = (SymbolTable*)malloc(sizeof(SymbolTable));
        newSymbolTable->tableIndex = 0;
        symbolTableStack[++stackTop] = newSymbolTable;
    }

    void popSymbolTable() {
        free(symbolTableStack[stackTop--]);
    }
%}

%x COMMENT

/* definitions section */


DECIMIAL ((-?)[1-9][0-9]*|0)
ID [[:alpha:]_][[:alpha:][:digit:]_]*
EOL (\r\n|\n|\r)
WHITE [\t ]

/*  Your code here (lab3). */

SINGLE_COMMENT (\/\/[^\n]*\n)
START_COMMENT "\/\*"
END_COMMENT "\*\/"

FLOAT ((-?)[0-9]+\.[0-9]+)
OCTAL ((-?)0[0-7]+)
HEX ((-?)0[x|X][0-9a-fA-F]+)

%%
    /* rules section */

"int" {
    dump_tokens("INT\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 1;
    yycolumn+=3;
}

"void" {
    dump_tokens("VOID\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 1;
    yycolumn+=4;
}

"if" {
    dump_tokens("IF\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn+=2;
}

"else" {
    dump_tokens("ELSE\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn+=4;
}

"while" {
    dump_tokens("WHILE\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn+=5;
}

"const" {
    dump_tokens("CONST\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn+=5;
}

"return" {
    dump_tokens("RETURN\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn+=6;
}

"=" {
    dump_tokens("ASSIGN\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn++;
}

"<" {
    dump_tokens("LESS\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn++;
}

">" {
    dump_tokens("MORE\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn++;
}

"+" {
    dump_tokens("ADD\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn++;
}

"-" {
    dump_tokens("SUB\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn++;
}

"*" {
    dump_tokens("MUL\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    yycolumn++;
}

"/" {
    dump_tokens("DIV\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    yycolumn++;
}

"||" {
    dump_tokens("OR\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn+=2;
}

"&&" {
    dump_tokens("AND\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn+=2;
}

"!" {
    dump_tokens("NOT\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn++;
}

";" {
    dump_tokens("SEMICOLON\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    yycolumn++;
    valid = 0;
}

"(" {
    dump_tokens("LPAREN\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    yycolumn++;
    valid = 0;
}

"[" {
    dump_tokens("LSPAREN\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn++;
}

"]" {
    dump_tokens("RSPAREN\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn++;
}

")" {
    dump_tokens("RPAREN\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    yycolumn++;
    valid = 0;
}

"{" {
    pushSymbolTable(); // 进入新作用域，创建新符号表并推入栈中
    currentScope++;
    dump_tokens("LBRACE\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    yycolumn++;
    valid = 0;
}

"}" {
    popSymbolTable(); // 退出作用域，从栈中弹出符号表
    currentScope--;
    dump_tokens("RBRACE\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    yycolumn++;
    valid = 0;
}

"," {
    dump_tokens("COMMA\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    yycolumn++;
}

"==" {
    dump_tokens("EQUAL\t %s \t %d \t %d \t \n", yytext, yylineno, yycolumn);
    valid = 0;
    yycolumn+=2;
}


{DECIMIAL} {
    int decimal;
    decimal = atoi(yytext);
    dump_tokens("DECIMAL\t%s \t%d \t%d \t%d \n",yytext, yylineno, yycolumn, decimal);
    temp_type = strdup(yytext);
    valid = 0;
    yycolumn+=strlen(yytext);
}

{ID} {


    char* identifier = yytext;
    int i = stackTop;
    printf("%d\n", i);
    for (; i >= 0; i--) {
        SymbolTable* currentSymbolTable = symbolTableStack[i];
        for (int j = 0; j < currentSymbolTable->tableIndex; j++) {
            SymbolTableEntry* entry = &(currentSymbolTable->symbolTable[j]);
            if (strcmp(entry->name, identifier) == 0) {
                // 找到了标识符，进行相应处理
                printf("Found existing symbol: %s\n", entry->name);
                dump_tokens("ID\t %s\t \t %d\t %d\t %p\t \n", yytext, yylineno, yycolumn, &entry);
                break;
            }
        }
    }
    printf("ok%d\n", i);
    if (i < 0) 
    {
        printf("ok");
        SymbolTable* currentSymbolTable = symbolTableStack[stackTop];      
         
        // 在符号表中创建新的项
        SymbolTableEntry entry;
        entry.name = strdup(yytext);
        entry.type = temp_type;
        entry.scope = currentScope;
            printf("ok");
        currentSymbolTable->symbolTable[currentSymbolTable->tableIndex++] = entry;

        printf("Created new symbol: %s\n", entry.name);
        dump_tokens("ID\t %s\t \t %d\t %d\t %p\t \n", yytext, yylineno, yycolumn, &entry);   

    }


    yycolumn+=strlen(yytext);

}

{EOL} {
    yylineno++;
    yycolumn = 1;
}

{WHITE} {}

    /*  Your code here (lab3). */

{SINGLE_COMMENT} {yylineno++;}


{OCTAL} {
    int decimal;
    decimal = strtol(yytext, NULL, 8);
    dump_tokens("OCTAL \t%s \t%d \t%d \t%d \n", yytext, yylineno, yycolumn, decimal);
    yycolumn+=strlen(yytext);
}

{HEX} {
    int decimal;
    decimal = strtol(yytext, NULL, 16);
    dump_tokens("HEX \t%s \t%d \t%d \t%d \n", yytext, yylineno, yycolumn, decimal);
    yycolumn+=strlen(yytext);
}

{FLOAT} {
    double flt;
    flt = atof(yytext);
    dump_tokens("FLOAT\t %s\t %d\t %d\t %f\n", yytext, yylineno, yycolumn, flt);
    yycolumn+=strlen(yytext);
}

"/*"                            { BEGIN(COMMENT); }
<COMMENT>[^*\n]+               {}
<COMMENT>"*"+[^*/\n]*           {}
<COMMENT>\n                     { yylineno++; yycolumn =1;}
<COMMENT>"*/"                   { BEGIN(INITIAL); }
<COMMENT>.                     {}
%%
/* user code section */
