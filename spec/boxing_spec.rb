require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "boxing support" do

  def box expected
    expected = remove_common_indent(expected)
    unless expected.lines.first.strip =~ %r,^- \(id\)box:\(([^)]+)\)(\w+) \{$,
      raise StandardError, "Invalid first line: #{expected.lines.first}"
    end
    type_string, var_name = $1.strip, $2.strip
    type = XDry::VarType.parse(type_string)
    raise "Invalid variable type '#{type_string}'" if type.nil?
    boxer = XDry::Boxing.converter_for(type)
    raise "No boxer available for variable type '#{type_string}'" if boxer.nil?
    lines = XDry::Emitter.capture do |o|
      o.block "- (id)box:(#{type.to_s})#{var_name}" do
        o << "return " + boxer.box(o, var_name, "#{var_name}fix") + ";"
      end
    end
    result = lines.join("\n").gsub("\t", "  ")
    result.strip.should == expected.strip
  end

  it "should box NSString verbatim" do
    box <<-END
      - (id)box:(NSString *)foo {
        return foo;
      }
    END
  end

  it "should box int via NSNumber" do
    box <<-END
      - (id)box:(int)foo {
        return [NSNumber numberWithInt:foo];
      }
    END
  end

  it "should box NSInteger via NSNumber" do
    box <<-END
      - (id)box:(NSInteger)foo {
        return [NSNumber numberWithInteger:foo];
      }
    END
  end

  it "should box float via NSNumber" do
    box <<-END
      - (id)box:(float)foo {
        return [NSNumber numberWithFloat:foo];
      }
    END
  end

  it "should box double via NSNumber" do
    box <<-END
      - (id)box:(double)foo {
        return [NSNumber numberWithDouble:foo];
      }
    END
  end

end
