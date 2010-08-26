eXtra D.R.Y. for Xcode
======================

From stuff like

    @interface MyTag : NSObject {
    	// persistent
    	NSString *_uid;
    	NSString *_displayName;
    }

    - (id)initWithUID: displayName:;

produces stuff like

    - (id) initWithDictionary:(NSDictionary *)dictionary {
        if (self = [super init]) {
            id uidRaw = [dictionary objectForKey:@"uid"];
            if (uidRaw != nil) {
                _uid = [uidRaw retain];
            }
            id displayNameRaw = [dictionary objectForKey:@"displayName"];
            if (displayNameRaw != nil) {
                _displayName = [displayNameRaw retain];
            }
        }
        return self;
    }

    - (NSDictionary *) dictionaryRepresentation {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:_uid forKey:@"uid"];
        [dictionary setObject:_displayName forKey:@"displayName"];
        return dictionary;
    }

    - (id)initWithUID:(NSString *)uid displayName:(NSString *)displayName {
        if (self = [super init]) {
            _uid = [uid copy];
            _displayName = [displayName copy];
        }
        return self;
    }

    - (id)dealloc {
        [_uid release], _uid = nil;
        [_displayName release], _displayName = nil;
        [super dealloc];
    }


Why?
----

Because typing all the boilerplate sucks.

One's life is too precious to be spent that way.

Seriously.


Early Stage
-----------

Right now, you need to run XD.R.Y. for the command line. The generated source code is saved into `xdry.m`.
You then hunt down the snippet you want in the giant pile of output. Yeah, I know. Duh.

Everything that XD.R.Y. can generate for now is illustrated in the above snippet. Nothing else is supported.


Vision
------

XD.R.Y. should monitor the file system and modify the files on the fly each time you save. E.g.:

* when you declare a method, an implementation stub is added
* when you add a property, a field and @synthesize are added automatically
* when you use a class, #import is added
* when you declare `+ (Foo *)sharedSomething`, the singleton boilerplate code is generated
