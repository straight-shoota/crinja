module Crinja::Parser::Symbol
  PREFIX          = '{'
  POSTFIX         = '}'
  FIXED           = 0
  NOTE            = '#'
  TAG             = '%'
  EXPR_START      = '{'
  EXPR_END        = '}'
  NEWLINE         = '\n'
  TRIM_WHITESPACE = '-'

  PIPE = '|'

  STR_DELIMITER     = '"'
  STR_DELIMITER_ALT = '\''
  STRING_ESCAPE     = '\\'

  OP_TILDE   = "~"
  OP_PLUS    = "+"
  OP_MINUS   = "-"
  OP_TIMES   = "*"
  OP_DIV     = "/"
  OP_INT_DIV = "//"
  OP_MODULO  = "%"
  OP_POW     = "**"

  OP_MEMBER = "."

  OP_AND = "and"
  OP_OR  = "or"
  OP_NOT = "not"

  OP_EQUAL         = "=="
  OP_NOT_EQUAL     = "!="
  OP_GREATER       = ">"
  OP_GREATER_EQUAL = ">="
  OP_LESS_EQUAL    = "<="
  OP_LESS          = "<"

  OP_ASSIGN = "="

  COMP_EQ   = '='
  COMP_BANG = '!'
  COMP_GT   = '>'
  COMP_LT   = '<'

  LEFT_PAREN  = '('
  RIGHT_PAREN = ')'

  LEFT_BRACKET  = '['
  RIGHT_BRACKET = ']'
  LEFT_CURLY    = '{'
  RIGHT_CURLY   = '}'
  DICT_ASSIGN   = ':'
  COMMA         = ','

  PAIRS = {
    LEFT_PAREN   => RIGHT_PAREN,
    LEFT_BRACKET => RIGHT_BRACKET,
    LEFT_CURLY   => RIGHT_CURLY,
  }

  TEST       = "is"
  RAW_START  = "raw"
  RAW_END    = "endraw"
  WHITESPACE = [' ', '\t', '\n', '\r']
end
