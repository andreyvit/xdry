require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "dictionary coding generator" do

  it "should implement dictionary coding" do
    xdry :dict_coding, <<-END
      @interface Foo {
        // persistent
        NSString *_something;
      }

      - (id)initWithDictionary:(NSDictionary *)dict;

      @property(nonatomic, retain) NSString *something;

      @end

      // start impl

    + #define SomethingKey @"Something"
    +
      @implementation Foo

      - (id)initWithDictionary:(NSDictionary *)dict {
        if (self = [super init]) {
    +     id somethingRaw = [dict objectForKey:SomethingKey];
    +     if (somethingRaw != nil) {
    +       _something = [somethingRaw copy];
    +     }
        }
        return self;
      }

      - (NSDictionary *)dictionaryRepresentation {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];"
    +   [dictionary setObject:_something forKey:SomethingKey];
        return dictionary;
      }

      @end
    END
  end

end
