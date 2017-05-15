module Crinja::Lexer
  module Symbol
    PREFIX          = '{'
    POSTFIX         = '}'
    FIXED           = 0
    NOTE            = '#'
    TAG             = '%'
    EXPR_START      = '{'
    EXPR_END        = '}'
    NEWLINE         = '\n'
    TRIM_WHITESPACE = '-'

    PIPE   = '|'
    MEMBER = '.'

    STR_DELIMITER     = '"'
    STR_DELIMITER_ALT = '\''
    STRING_ESCAPE     = '\\'

    OP_TILDE  = '~'
    OP_PLUS   = '+'
    OP_MINUS  = '-'
    OP_TIMES  = '*'
    OP_DIV    = '/'
    OP_MODULO = '%'

    COMP_EQ   = '='
    COMP_BANG = '!'
    COMP_GT   = '>'
    COMP_LT   = '<'

    PARENTHESIS_START = '('
    PARENTHESIS_END   = ')'

    LIST_START     = '['
    LIST_END       = ']'
    DICT_START     = '{'
    DICT_END       = '}'
    DICT_ASSIGN    = ':'
    LIST_SEPARATOR = ','

    PAIRS = {
      PARENTHESIS_START => PARENTHESIS_END,
      LIST_START        => LIST_END,
      DICT_START        => DICT_END,
    }

    TEST       = "is"
    NOT        = "not"
    RAW_START  = "raw"
    RAW_END    = "endraw"
    WHITESPACE = [' ', '\t', '\n', '\r']
  end
end
