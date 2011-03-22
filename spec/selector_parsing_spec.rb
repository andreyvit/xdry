require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SelectorDef" do

  it "should parse a simple selector" do
    sel = XDry::SelectorDef.parse('count')
    sel.class.should == XDry::SimpleSelectorDef
    sel.selector.should == 'count'
  end

  it "should parse foo:(Foo)oof" do
    sel = XDry::SelectorDef.parse('foo:(Foo)oof')
    sel.components.count.should == 1
    sel.components[0].keyword.should == 'foo:'
    sel.components[0].arg_name.should == 'oof'
    sel.components[0].type.class.should == XDry::SimpleVarType
    sel.components[0].type.name.should == 'Foo'
  end

  it "should parse foo:" do
    sel = XDry::SelectorDef.parse('foo:')
    sel.components.count.should == 1
    sel.components[0].keyword.should == 'foo:'
    sel.components[0].arg_name.should == nil
    sel.components[0].type.should == nil
  end

  it "should parse foo:oof" do
    sel = XDry::SelectorDef.parse('foo:oof')
    sel.components.count.should == 1
    sel.components[0].keyword.should == 'foo:'
    sel.components[0].arg_name.should == 'oof'
    sel.components[0].type.should == nil
  end

  it "should parse foo:(Foo)oof bar:(Bar)rab" do
    sel = XDry::SelectorDef.parse('foo:(Foo)oof bar:(Bar)rab')
    sel.components.count.should == 2

    sel.components[0].keyword.should == 'foo:'
    sel.components[0].arg_name.should == 'oof'
    sel.components[0].type.class.should == XDry::SimpleVarType
    sel.components[0].type.name.should == 'Foo'

    sel.components[1].keyword.should == 'bar:'
    sel.components[1].arg_name.should == 'rab'
    sel.components[1].type.class.should == XDry::SimpleVarType
    sel.components[1].type.name.should == 'Bar'
  end

  it "should parse foo:bar:" do
    sel = XDry::SelectorDef.parse('foo:bar:')
    sel.components.count.should == 2

    sel.components[0].keyword.should == 'foo:'
    sel.components[0].arg_name.should == nil
    sel.components[0].type.should == nil

    sel.components[1].keyword.should == 'bar:'
    sel.components[1].arg_name.should == nil
    sel.components[1].type.should == nil
  end

  it "should parse foo:(unsigned char)oof" do
    sel = XDry::SelectorDef.parse('foo:(unsigned char)oof')
    sel.components.count.should == 1
    sel.components[0].keyword.should == 'foo:'
    sel.components[0].arg_name.should == 'oof'
    sel.components[0].type.class.should == XDry::SimpleVarType
    sel.components[0].type.name.should == 'unsigned char'
  end

  it "should parse foo : (  unsigned char  )   oof   bar    : (long long) zzzz  " do
    sel = XDry::SelectorDef.parse('foo : (  unsigned char  )   oof   bar    : (long long) zzzz  ')
    sel.components.count.should == 2

    sel.components[0].keyword.should == 'foo:'
    sel.components[0].arg_name.should == 'oof'
    sel.components[0].type.class.should == XDry::SimpleVarType
    sel.components[0].type.name.should == 'unsigned char'

    sel.components[1].keyword.should == 'bar:'
    sel.components[1].arg_name.should == 'zzzz'
    sel.components[1].type.class.should == XDry::SimpleVarType
    sel.components[1].type.name.should == 'long long'
  end

end
