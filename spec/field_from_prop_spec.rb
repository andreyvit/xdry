require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "field from property generator" do

  it "should add missing fields for declared properties" do
    xdry :field_from_prop, <<-END
      @interface Foo {
    +   NSString *_something;
      }

      @property(nonatomic, retain) NSString *something;

      @end

      @implementation Foo

      @end
    END
  end

  it "shouldn't add fields that already exist" do
    xdry :field_from_prop, <<-END
      @interface Foo {
        NSString *something;
      }

      @property(nonatomic, retain) NSString *something;

      @end

      @implementation Foo

      @end
    END
  end

  it "shouldn't add fields that already exist, even if they are prefixed" do
    xdry :field_from_prop, <<-END
      @interface Foo {
        NSString *_something;
      }

      @property(nonatomic, retain) NSString *something;

      @end

      @implementation Foo

      @end
    END
  end

  it "shouldn't add a field if a getter exists" do
    xdry :field_from_prop, <<-END
      @interface Foo {
      }

      @property(nonatomic, retain) NSString *something;

      @end

      @implementation Foo

      - (NSString *)something {
        return @"foo";
      }

      @end
    END
  end

end
