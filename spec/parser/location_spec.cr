require "../spec_helper"

describe Crinja::Parser::TemplateParser do
  it "fixed string" do
    parser = Crinja::Parser::TemplateParser.new(Crinja.new, "Hallo Welt!")
    tree = parser.parse

    fixed_string = tree.children.first
    fixed_string.location_start.should eq?({1, 1, 0})
    fixed_string.location_end.should eq?({1, 12, 11})
  end

  it "fixed string and expression" do
    parser = Crinja::Parser::TemplateParser.new(Crinja.new, "Hallo Welt {{ name }}!")
    tree = parser.parse

    hello = tree.children[0]
    hello.location_start.should eq?({1, 1, 0})
    hello.location_end.should eq?({1, 12, 11})

    print = tree.children[1].as(Crinja::AST::PrintStatement)
    print.location_start.should eq?({1, 12, 11})
    print.location_end.should eq?({1, 22, 21})

    literal = print.expression
    literal.location_start.should eq?({1, 15, 14})
    literal.location_end.should eq?({1, 19, 18})

    bang = tree.children[2]
    bang.location_start.should eq?({1, 22, 21})
    bang.location_end.should eq?({1, 23, 22})
  end
end

describe Crinja::Parser::ExpressionParser do
  it "parse double parenthesis" do
    expression = parse_expression("dict(foo=(1, 2))").as(Crinja::AST::CallExpression)

    expression.location_start.should eq?({1, 1, 0})
    expression.location_end.should eq?({1, 17, 16})

    identifier = expression.identifier
    identifier.location_start.should eq?({1, 1, 0})
    identifier.location_end.should eq?({1, 5, 4})

    keywords = expression.keyword_arguments

    key_id = keywords.first_key
    key_id.location_start.should eq?({1, 6, 5})
    key_id.location_end.should eq?({1, 9, 8})

    value = keywords.first_value.as(Crinja::AST::TupleLiteral)
    value.location_start.should eq?({1, 10, 9})
    value.location_end.should eq?({1, 16, 15})

    one = value.children[0]
    one.location_start.should eq?({1, 11, 10})
    one.location_end.should eq?({1, 12, 11})

    one = value.children[1]
    one.location_start.should eq?({1, 14, 13})
    one.location_end.should eq?({1, 15, 14})
  end
end
