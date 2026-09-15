import 'dart:convert';
import 'dart:io';

enum TokenType {
  // Delimiters
  // Grouping Delimiters
  parenL, parenR,
  // Block Delimiteers
  curlyL, curlyR,
  // Literal Deelimiter
  bracketL,bracketR,

  // Arithmetic
  add, sub, mult, div,

  // Relational Operators
  equalEqual, notEqual, less, lessEqual, greater, greaterEqual, 

  // Assignments
  equal, not,

  // Types and null
  identifier, string, number, typeNull,

  // conditionals
  condIf, condElse, condIfelse,

  // loops
  repFor, repWhile,
  
  // bools
  boolTrue, boolFalse,

  // EOF, Statemeent teerminator, 
  termFile, termStatement, termLine, 
}

// symbols/lexemes for lookup
const Map<String, TokenType> Symbols = {
  // Grouping Delimiters
  "(": TokenType.parenL,
  ")": TokenType.parenR,

  // Block Delimiters
  "{": TokenType.curlyL,
  "}": TokenType.curlyR,

  // Literal Delimiters
  "[": TokenType.bracketL,
  "]": TokenType.bracketR,

  // Arithmetic
  "+": TokenType.add,
  "-": TokenType.sub,
  "*": TokenType.mult,
  "/": TokenType.div,

  // Relational Operators
  "==": TokenType.equalEqual,
  "!=": TokenType.notEqual,
  "<": TokenType.less,
  "<=": TokenType.lessEqual,
  ">": TokenType.greater,
  ">=": TokenType.greaterEqual,

  // Assignments
  "=": TokenType.equal,
  "!": TokenType.not,

  // Statement terminators
  "--": TokenType.termStatement,
  "\n": TokenType.termLine,
};

// Keywords for lookup
const Map<String, TokenType> Keywords = {
  // Types and null
  "null": TokenType.typeNull,

  // Conditionals
  "if": TokenType.condIf,
  "else": TokenType.condElse,
  "ifelse": TokenType.condIfelse, // or "elif" / "elseif"

  // Loops
  "for": TokenType.repFor,
  "while": TokenType.repWhile,

  // Bools
  "true": TokenType.boolTrue,
  "false": TokenType.boolFalse,
};

class Token {
  final TokenType type;
  final String lexeme;
  final Object? literal;
  final int line;

  const Token(this.type, this.lexeme, this.literal, this.line);

  @override
  String toString(){
    if (lexeme == '\n') {
      return 'Token(type: $type, lexeme: \\n, literal: $literal, line: $line)';
    }
    return 'Token(type: $type, lexeme: $lexeme, literal: $literal, line: $line)';
    }
}

class Scanner {
    /* 
    Changed current to column to make it clear if we are referring to
    the character before/on/after the current character.
    In this case, we refer to the character ON.
    */
    final String source;
    int start = 0;
    int column = 0;
    int line = 1;

    List<Token> tokens = [];

    Scanner(this.source);

    void scanTokens(){
        while(!_isAtEnd()){
            start = column;
            scanToken();
        }

        tokens.add(Token(TokenType.termFile, 'EOF', null, line));
    }

    void scanToken(){
        final character = _advance();

        if (_isDigit(character)){
            _scanNumber();
            return;
        }
        
        if (_isAlphabet(character)){
            _scanIdentifier();
            return;
        }
        
        if (character == '"'){
            _scanString();
            return;
        }

        _scanSymbol(character);
    }

    void _addToken(TokenType type, [Object? literal]){
        final lexeme = source.substring(start, column);
        final token = Token(type, lexeme, literal, line);
        tokens.add(token);
    }

    void _scanSymbol(String character){
        switch(character){
            case ' ':
            case '\r':
            case '\t':
                break;
            case '\n':
                line++;
                _addToken(TokenType.termLine);
                break;
            case '=':
                _addToken(_match('=') ? TokenType.equalEqual : TokenType.equal, character);
                break;
            case '!':
                _addToken(_match('=') ? TokenType.notEqual : TokenType.not, character);
                break;
            case '<':
                _addToken(_match('=') ? TokenType.lessEqual : TokenType.less, character);
                break;
            case '>':
                _addToken(_match('=') ? TokenType.greaterEqual : TokenType.greater, character);
                break;
            case '\\':
                break;
            default:
                final symbol = Symbols[character];

                if(symbol == null){
                    fail("unexpected character '$character' at line:column $line:$column");
                }

                _addToken(symbol, character);
        }
    }

    void _scanNumber(){
        while(_isDigit(_peek())){
            _advance();
        }

        final number = source.substring(start, column);
        final value = double.tryParse(number);

        _addToken(TokenType.number, value);
    }

    void _scanIdentifier(){
        while(_isAlphabet(_peek()) || _isDigit(_peek())){
            _advance();
        }

        final identifier = source.substring(start, column);
        final keyword = Keywords[identifier];

        if(keyword != null){
            _addToken(keyword, identifier);
        } else {
            _addToken(TokenType.identifier, identifier);
        }
    }

    void _scanString(){
        while(_peek() != '"' && !_isAtEnd()){
            if(_peek() == '\n') line++;
            _advance();
        }

        if(_isAtEnd()){
            fail("unterminated string at line:column $line:$column");
        }

        _advance(); // consume closing "

        final value = source.substring(start + 1, column - 1);
        _addToken(TokenType.string, value);
    }

    String _peek() {
        if (_isAtEnd()) return '\u0000';
        return source.substring(column, column + 1);
    }

    String _advance() {
        final character = source.substring(column, column + 1);
        column++;
        return character;
    }

    bool _match(String expected){
        if (_isAtEnd()) return false;
        if (source[column] != expected) return false;

        column++;
        return true;
    }

    bool _isAlphabet(String character){
        final codeUnit = character.codeUnits.first;
        return (codeUnit >= 'a'.codeUnits.first && codeUnit <= 'z'.codeUnits.first) || (codeUnit >= 'A'.codeUnits.first && codeUnit <= 'Z'.codeUnits.first);

    }
    bool _isDigit(String character){
        return character.codeUnits.first >= '0'.codeUnits.first && character.codeUnits.first<= '9'.codeUnits.first;
    }
    bool _isAtEnd(){return column >= source.length;}

}


Never fail(String message) {
  stderr.writeln('lab0: $message');
  exit(65);
}

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    fail('expected one source-file path');
  }

  final path = arguments.last;
  final command = arguments.first;

  if (command == '--tokenize'){
    try {
    final source = File(path).readAsStringSync(encoding: utf8); 
        final scanner = Scanner(source);
        scanner.scanTokens();

        for (final token in scanner.tokens) {
            stdout.writeln(token.toString());
        }
    } on FileSystemException catch (error) {
      fail("cannot read '$path': ${error.message}");
    }
  }else{
    try {
    final source = File(path).readAsStringSync(encoding: utf8);
    stdout.write(source);
    } on FileSystemException catch (error) {
      fail("cannot read '$path': ${error.message}");
    }
  }

  
}
