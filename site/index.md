---
title: Home
layout: default
---

Objective-C boilerplate generator
=================================

Run Extra D.R.Y. in your Objective-C project folder to automatically add (upon your request):

* `@property`, `@synthesize`, field declarations,
* initializing constructors,
* missing release calls in dealloc,
* initWithDictionary, dictionaryRepresentation based on the chosen fields.


Installation
------------

Install the command-line utility via RubyGems:

    sudo gem install xdry


Basic Usage
-----------

Tell XD.R.Y. which changes you want done using bang-commands. For example,
add `!p` to a field declaration line to generate a property:

{% example %}

{% highlight objc %}
    // Foo.h
    @interface Foo {
      Bar *value; !p
    }

    @end

    // Foo.m
    @implementation Foo
    @end
{% endhighlight %}

{% highlight objc %}
    // Foo.h
    @interface Foo {
      Bar *value;
    }

    @property(nonatomic, retain) Bar *value;

    @end

    // Foo.m
    @implementation Foo

    @synthesize value;

    - (void)dealloc {
      [value release], value = nil;
      [super dealloc];
    }

    @end
{% endhighlight %}

{% endexample %}

To run XD.R.Y., open a Terminal, cd to your project folder and execute `xdry`:

    cd ~/Documents/HelloWorld
    xdry


Automatic Changes
-----------------

Without any instructions from your side, XD.R.Y. automatically applies the following
changes:

* Adds missing release calls to `dealloc` methods:

{% example %}

{% highlight objc %}
    @interface Foo {
      NSString *value;
    }
    @end

    @implementation Foo
    @end
{% endhighlight %}

{% highlight objc %}
    @interface Foo {
      NSString *value;
    }
    @end

    @implementation Foo

    - (void)dealloc {
      [value release], value = nil;
      [super dealloc];
    }

    @end
{% endhighlight %}

{% endexample %}

* Adds missing `@synthesize` declarations for properties with no explicit accessor methods:

{% example %}

{% highlight objc %}
    @interface Foo {
      NSString *value;
    }

    @property(nonatomic, copy) NSString *value;

    @end

    @implementation Foo
    @end
{% endhighlight %}

{% highlight objc %}
    @interface Foo {
      NSString *value;
    }

    @property(nonatomic, copy) NSString *value;

    @end

    @implementation Foo

    @synthesize value;

    @end
{% endhighlight %}

{% endexample %}

* Adds missing fields for declared properties:

{% example %}

{% highlight objc %}
    @interface Foo {
    }

    @property(nonatomic, copy) NSString *value;

    @end
{% endhighlight %}

{% highlight objc %}
    @interface Foo {
      NSString *value;
    }

    @property(nonatomic, copy) NSString *value;

    @end
{% endhighlight %}

{% endexample %}



Properties, Fields, Constructors
--------------------------------

`!p` — generate a property for the given field:

{% example %}

{% highlight objc %}
    @interface Foo {
      Bar *value; !p
    }

    @end

    @implementation Foo
    @end
{% endhighlight %}

{% highlight objc %}
    @interface Foo {
      Bar *value;
    }

    @property(nonatomic, retain) Bar *value;

    @end

    @implementation Foo

    @synthesize value;

    - (void)dealloc {
      [value release], value = nil;
      [super dealloc];
    }

    @end
{% endhighlight %}

{% endexample %}



`!c` — generate an initializing constructor for the given field(s):

{% example %}

{% highlight objc %}
    @interface Foo {
      NSString *_something; !c
    }
    @end

    @implementation Foo
    @end
{% endhighlight %}

{% highlight objc %}
    @interface Foo {
      NSString *_something;
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
{% endhighlight %}

{% endexample %}


Dictionary Coding
-----------------

XD.R.Y. can generate `initWithDictionary:(NSDictionary *)dictionary` method, useful for loading objects from a plist. Similarly, an `(NSDictionary *)dictionaryRepresentation` method is generated to produce a plist-friendly dictionary from an object.

`// persistent` marks a block of fields to read from a dictionary / serialize into a dictionary:

{% example %}

{% highlight objc %}
    @interface Foo {
      // persistent
      NSString *_something;
    }
    @end

    @implementation Foo
    @end
{% endhighlight %}

{% highlight objc %}
    @interface Foo {
      // persistent
      NSString *_something;
    }
    @end

    #define SomethingKey @"Something"

    @implementation Foo

    - (id)initWithDictionary:(NSDictionary *)dictionary {
      if (self = [super init]) {
        id somethingRaw = [dictionary objectForKey:SomethingKey];
        if (somethingRaw != nil) {
          _something = [somethingRaw copy];
        }
      }
      return self;
    }

    - (NSDictionary *)dictionaryRepresentation {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      [dictionary setObject:_something forKey:SomethingKey];
      return dictionary;
    }

    @end
{% endhighlight %}

{% endexample %}

To correctly handle serialization and deserialization of arrays,
you need to hint XD.R.Y. about the item type:

{% example %}

{% highlight objc %}
    @interface Foo {
      // persistent
      NSArray *_bars; // of Bar
    }
    @end

    @implementation Foo
    @end
{% endhighlight %}

{% highlight objc %}
    @interface Foo {
      // persistent
      NSArray *_bars; // of Bar
    }
    @end

    @implementation Foo
    #define BarsKey @"Bars"

    @implementation Foo

    - (id)initWithDictionary:(NSDictionary *)dictionary {
      if (self = [super init]) {
        id barsRaw = [dictionary objectForKey:BarsKey];
        if (barsRaw != nil) {
          NSMutableArray *barsArray = [[NSMutableArray alloc] init];
          for (NSDictionary *barsItemDict in (NSArray *) barsRaw) {
            Bar *barsItem = [[Bar alloc] initWithDictionary:barsItemDict];
            [barsArray addObject:barsItem];
            [barsItem release];
          }
          _bars = barsArray;
        }
      }
      return self;
    }

    - (NSDictionary *)dictionaryRepresentation {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      NSMutableArray *barsArray = [NSMutableArray array];
      for (Bar *barsItem in _bars) {
        [barsArray addObject:[barsItem dictionaryRepresentation]];
      }
      [dictionary setObject:barsArray forKey:BarsKey];
      return dictionary;
    }

    - (void)dealloc {
      [_bars release], _bars = nil;
      [super dealloc];
    }

    @end
{% endhighlight %}

{% endexample %}



License and Authors
-------------------

Copyright 2010–2011, Andrey Tarantsov.

Distributed under the MIT license, see LICENSE file for details.


Contributing
------------

Fork the source on GitHub: [http://github.com/andreyvit/xdry](http://github.com/andreyvit/xdry).

Add a test, make a change, verify that all tests pass, update the docs in site/index.md, send me a pull request.

Testing prerequisites:

    sudo gem install rake rspec diff-lcs

The simplest way to run the tests:

    rake

Get a nice colorful table with test results:

    rspec -b -c -fd .

When something goes wrong, you want a verbose output:

    VERBOSE=1 rake

Site (documentation) prerequisites:

    sudo gem install jekyll
    sudo easy_install Pygments

Regenerate the site using:

    rake site:build

(open site/_site/index.html to view the results).
Don't bother with gh-pages branch.
