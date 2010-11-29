require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "constructor from fields generator" do

  it "should add a constructor for NSString *_something field marked with a full-line marker" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   !c
        NSString *_something;
      }

    + - (id)initWithSomething:(NSString *)something;
    +
      @end

      @implementation Foo
    +
    + - (id)initWithSomething:(NSString *)something {
    +   if (self = [super init]) {
    +     _something = [something copy];
    +   }
    +   return self;
    + }

      @end
    END
  end

  it "should add a constructor for NSString *_something field marked with an inline marker" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   NSString *_something; !c
    +   NSString *_something;
      }

    + - (id)initWithSomething:(NSString *)something;
    +
      @end

      @implementation Foo
    +
    + - (id)initWithSomething:(NSString *)something {
    +   if (self = [super init]) {
    +     _something = [something copy];
    +   }
    +   return self;
    + }

      @end
    END
  end

  it "should do nothing when a constructor already exists" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   NSString *_something; !c
    +   NSString *_something;
      }

      - (id)initWithSomething:(NSString *)something;

      @end

      @implementation Foo

      - (id)initWithSomething:(NSString *)something {
        if (self = [super init]) {
          _something = [something copy];
        }
        return self;
      }

      @end
    END
  end

  it "should add a missing interface declaration when an implementation already exists" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   NSString *_something; !c
    +   NSString *_something;
      }
    +
    + - (id)initWithSomething:(NSString *)something;

      @end

      @implementation Foo

      - (id)initWithSomething:(NSString *)something {
        if (self = [super init]) {
          _something = [something copy];
        }
        return self;
      }

      @end
    END
  end

  it "should add a missing implementation when an interface declaration already exists" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   NSString *_something; !c
    +   NSString *_something;
      }

      - (id)initWithSomething:(NSString *)something;

      @end

      @implementation Foo
    +
    + - (id)initWithSomething:(NSString *)something {
    +   if (self = [super init]) {
    +     _something = [something copy];
    +   }
    +   return self;
    + }

      @end
    END
  end

  it "should use aSomething as arg name if a field is not prefixed" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   NSString *something; !c
    +   NSString *something;
      }

    + - (id)initWithSomething:(NSString *)something;
    +
      @end

      @implementation Foo
    +
    + - (id)initWithSomething:(NSString *)aSomething {
    +   if (self = [super init]) {
    +     something = [aSomething copy];
    +   }
    +   return self;
    + }

      @end
    END
  end

  it "should use 'an' prefix if an unprefixed field name starts with a vowel" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   NSString *apple; !c
    +   NSString *apple;
      }

    + - (id)initWithApple:(NSString *)apple;
    +
      @end

      @implementation Foo
    +
    + - (id)initWithApple:(NSString *)anApple {
    +   if (self = [super init]) {
    +     apple = [anApple copy];
    +   }
    +   return self;
    + }

      @end
    END
  end

  it "should add a missing assignment to an already defined implementation" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   NSString *something; !c
    +   NSString *something;
      }

      - (id)initWithSomething:(NSString *)something;

      @end

      @implementation Foo

      - (id)initWithSomething:(NSString *)aSomething {
        if (self = [super init]) {
    +     something = [aSomething copy];
        }
        return self;
      }

      @end
    END
  end

  it "should use self->something if the arg name == field name in an already defined implementation" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   NSString *something; !c
    +   NSString *something;
      }

      - (id)initWithSomething:(NSString *)something;

      @end

      @implementation Foo

      - (id)initWithSomething:(NSString *)something {
        if (self = [super init]) {
    +     self->something = [something copy];
        }
        return self;
      }

      @end
    END
  end

  it "should add a constructor for several fields" do
    xdry :ctor_from_field, <<-END
      @interface Foo {
    -   NSString *_foo; !c
    -   NSInteger _bar; !c
    -   Boz *_boz; !c
    +   NSString *_foo;
    +   NSInteger _bar;
    +   Boz *_boz;
      }

    + - (id)initWithFoo:(NSString *)foo bar:(NSInteger)bar boz:(Boz *)boz;
    +
      @end

      @implementation Foo
    +
    + - (id)initWithFoo:(NSString *)foo bar:(NSInteger)bar boz:(Boz *)boz {
    +   if (self = [super init]) {
    +     _foo = [foo copy];
    +     _bar = bar;
    +     _boz = [boz retain];
    +   }
    +   return self;
    + }

      @end
    END
  end

end
