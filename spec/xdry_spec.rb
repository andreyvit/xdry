require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Xdry" do

  def xdry content
    verbose = ((ENV['VERBOSE'] || '0').to_i != 0)

    first_line_indent = content.split("\n", 2).first.gsub(/\S.*$/, '')
    deleted_indent    = first_line_indent.sub(/\s\s$/, '-( |$)')
    added_indent      = first_line_indent.sub(/\s\s$/, "\\\\+( |$)")

    orig_content = content.lines.select { |l| l =~ /^(#{first_line_indent}|#{deleted_indent})|^$/ }.join("")
    new_content  = content.lines.select { |l| l =~ /^(#{first_line_indent}|#{added_indent})|^$/ }.join("")

    orig_content = orig_content.gsub(/^(#{first_line_indent}|#{deleted_indent})/, '')
    new_content  = new_content.gsub(/^(#{first_line_indent}|#{added_indent})/, '')

    if verbose
      puts "-" * 40
      puts orig_content
      puts "-" * 40
      puts new_content
      puts "-" * 40
    end

    result = XDry.test_run({'main.m' => orig_content}, verbose)['main.m']
    result = orig_content if result.nil?

    result.should == new_content
  end

  it "should handle empty input" do
    xdry("  ")
  end

  it "should add @synthesize when a @property exists" do
    xdry <<-END
      @interface Foo {
        BOOL value;
      }
      @property BOOL value;
      @end

      @implementation Foo
    +
    + @synthesize value;
    +
      @end
    END
  end

  it "should reuse existing whitespace when inserting the first @synthesize" do
    xdry <<-END
      @interface Foo {
        BOOL value;
      }
      @property BOOL value;
      @end

      @implementation Foo
    +
    + @synthesize value;

      @end
    END
  end

  it "should add @synthesize after existing @synthesize if any" do
    xdry <<-END
      @interface Foo {
        BOOL value;
      }
      @property BOOL value;
      @end

      @implementation Foo

      @synthesize something;
      @synthesize something_else;
    + @synthesize value;

      @end
    END
  end

  it "should use field name in @synthesize if needed" do
    xdry <<-END
      @interface Foo {
        BOOL _value;
      }
      @property BOOL value;
      @end

      @implementation Foo

      @synthesize something;
    + @synthesize value=_value;

      @end
    END
  end

  it "shouldn't add @synthesize if a getter is already implemented" do
    xdry <<-END
      @interface Foo {
        BOOL _value;
      }
      @property BOOL value;
      @end

      @implementation Foo

      - (BOOL) value {
        return _value;
      }

      @end
    END
  end

end
