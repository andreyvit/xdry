require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "property from field generator" do

  it "should add property for a field marked with a full-line marker" do
    xdry :prop_from_field, <<-END
      @interface Foo {
    -   !p
        NSString *_something;
      }

    + @property(nonatomic, retain) NSString *something;
    +
      @end

      @implementation Foo

      @end
    END
  end

  it "should add property for a field marked with an inline marker" do
    xdry :prop_from_field, <<-END
      @interface Foo {
    -   NSString *_something; !p
    +   NSString *_something;
      }

    + @property(nonatomic, retain) NSString *something;
    +
      @end

      @implementation Foo

      @end
    END
  end

end
