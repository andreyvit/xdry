D.R.Y. for Xcode
================

Work in progress…

From stuff like

    @interface MyTag : NSObject {
    	// persistent
    	NSString *_uid;
    	NSString *_displayName;
    }

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

Ideally, should monitor the file system and modify files on the fly. E.g.:

* when you declare a method, an implementation stub is added
* when you add a property, a field and @synthesize are added automatically
* when you use a class, #import is added
