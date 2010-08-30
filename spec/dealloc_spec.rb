require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "dealloc support" do

  it "should add missing release calls to dealloc" do
    xdry :dealloc, <<-END
      @interface Foo {
        NSString *something;
      }
      @end

      @implementation Foo

      - (void)dealloc {
    +   [something release], something = nil;
        [super dealloc];
      }

      @end
    END
  end

  it "shouldn't add release calls that already exist" do
    xdry :dealloc, <<-END
      @interface Foo {
        NSString *something;
        NSString *somethingElse;
      }
      @end

      @implementation Foo

      - (void)dealloc {
        [something release];
    +   [somethingElse release], somethingElse = nil;
        [super dealloc];
      }

      @end
    END
  end

  it "shouldn't add anything if all calls already exist" do
    xdry :dealloc, <<-END
      @interface Foo {
        NSString *something;
        NSString *somethingElse;
      }
      @end

      @implementation Foo

      - (void)dealloc {
        [something release];
        [somethingElse release], somethingElse = nil;
        [super dealloc];
      }

      @end
    END
  end

  it "should detect self.foo = nil as a release call" do
    xdry :dealloc, <<-END
      @interface Foo {
        NSString *something;
        NSString *somethingElse;
      }
      @end

      @implementation Foo

      - (void)dealloc {
        self.something = nil;
    +   [somethingElse release], somethingElse = nil;
        [super dealloc];
      }

      @end
    END
  end

  it "should add dealloc if it does not exist" do
    xdry :dealloc, <<-END
      @interface Foo {
        NSString *something;
        NSString *somethingElse;
      }
      @end

      @implementation Foo
    +
    + - (void)dealloc {
    +   [something release], something = nil;
    +   [somethingElse release], somethingElse = nil;
    +   [super dealloc];
    + }
    +
      @end
    END
  end

end
