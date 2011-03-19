require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Properties Support" do

  it "should add @property" do
    xdry <<-END
      @interface Foo {
    -   Bar *value; !p
    +   Bar *value;
      }

    + @property(nonatomic, retain) Bar *value;
    +
      @end

      @implementation Foo
    +
    + @synthesize value;
    +
    + - (void)dealloc {
    +   [value release], value = nil;
    +   [super dealloc];
    + }
    +
      @end
    END
  end

  it "should add @property" do
    xdry <<-END
      @interface Foo {
        // persistent
        NSArray *_bars; // of Bar
      }
      @end

    + #define BarsKey @"Bars"
    +
      @implementation Foo
    +
    + - (id)initWithDictionary:(NSDictionary *)dictionary {
    +   if (self = [super init]) {
    +     id barsRaw = [dictionary objectForKey:BarsKey];
    +     if (barsRaw != nil) {
    +       NSMutableArray *barsArray = [[NSMutableArray alloc] init];
    +       for (NSDictionary *barsItemDictionary in (NSArray *) barsRaw) {
    +         Bar *barsItem = [[Bar alloc] initWithDictionary:barsItemDictionary];
    +         [barsArray addObject:barsItem];
    +         [barsItem release];
    +       }
    +       _bars = barsArray;
    +     }
    +   }
    +   return self;
    + }
    +
    + - (NSDictionary *)dictionaryRepresentation {
    +   NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    +   NSMutableArray *barsArray = [NSMutableArray array];
    +   for (Bar *barsItem in _bars) {
    +     [barsArray addObject:[barsItem dictionaryRepresentation]];
    +   }
    +   [dictionary setObject:barsArray forKey:BarsKey];
    +   return dictionary;
    + }
    +
    + - (void)dealloc {
    +   [_bars release], _bars = nil;
    +   [super dealloc];
    + }
    +
      @end
    END
  end

end
