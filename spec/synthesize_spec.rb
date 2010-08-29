require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "@synthesize support" do

  it "should handle empty input" do
    xdry :synth, "  "
  end

  it "should add @synthesize when a @property exists" do
    xdry :synth, <<-END
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
    xdry :synth, <<-END
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
    xdry :synth, <<-END
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
    xdry :synth, <<-END
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
    xdry :synth, <<-END
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
