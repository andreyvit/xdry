require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "VarType" do

  for simple in ['int', 'signed int', 'unsigned int', 'unsigned char', 'long long']
    it "should parse #{simple}" do
      sel = XDry::VarType.parse(simple)
      sel.class.should == XDry::SimpleVarType
      sel.to_s == simple
    end
  end

  it "should parse NSString *" do
    sel = XDry::VarType.parse('NSString *')
    sel.class.should == XDry::PointerVarType
    sel.name == 'NSString'
  end

  it "should parse NSError **" do
    sel = XDry::VarType.parse('NSError **')
    sel.class.should == XDry::PointerPointerVarType
    sel.name == 'NSError'
  end

  it "should parse id" do
    sel = XDry::VarType.parse('id')
    sel.class.should == XDry::IdVarType
    sel.protocol == nil
  end

  it "should parse id<Foo>" do
    sel = XDry::VarType.parse('id<Foo>')
    sel.class.should == XDry::IdVarType
    sel.protocol == 'Foo'
  end

end
