eXtra D.R.Y. for Xcode
======================

From stuff like

    @interface MyTag : NSObject {
    	// persistent
    	NSString *_uid;
    	NSString *_displayName;
    }

    @property(nonatomic, retain) NSString *displayName;

    - (id)initWithUID: displayName:;

produces stuff like

    @synthesize displayName=_displayName;

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

    - (void)dealloc {
        [_uid release], _uid = nil;
        [_displayName release], _displayName = nil;
        [super dealloc];
    }


Why?
----

Because typing all the boilerplate sucks.

One's life is too precious to be spent that way.

Seriously.


Usage
-----

First, run XD.R.Y. in your project directory once:

    xdry

then examine the changes in `.xdry.h` and `.xdry.m` files to see if XD.R.Y. does something stupid on your project.

If you are satisfied and would like to operate XD.R.Y. for real, run:

    xdry -R -w

to continuously watch for file system changes and update your project files. (`-R` stands for “real”, i.e. patching your files instead of writing to `.dry.h`/`.dry.m`.)

There's some useful stuff generated that XD.R.Y. cannot yet patch-in into your files. You can find it in `xdry.m` in the root of your project.

In watching mode (`-w`), `growlnotify` is used to give some important updates. Please make sure it is installed.

In watching mode (`-w`), Xcode project is automatically refreshed. This works weirdly (AppleScript switches to Finder, wait 300ms, then switches back to Xcode, waits 300ms, then simulates Command-U). When you get an “Updating...” message from Growl, please stop coding for a moment.


What XD.R.Y. already does
-------------------------

Changes patched live into the sources:

* add missing `@synthesize` declarations for your properties
* add missing release calls to `dealloc`
* add `initWithDictionary:` and `dictionaryRepresentation` methods for classes that have some fields marked with `// persistent` comment, like this:

        @interface MyTag : NSObject {
        	// persistent
        	NSString *_uid;
        	NSString *_displayName;

        	NSString *_other; // this won't be saved/restored since an empty line resets the 'persistent' mode
        }

* add missing field declarations for properties (unless those have getters implemented as methods)
* add an initializing constructor for fields marked with `!c`

Collected in `xdry.m`:

* declare properties for all your fields that don't yet have properties declared (you can copy and paste those into your project)

* implement field-based constructors (if you declare `initWithXxx:yyy:zzz:` method and at least one of `xxx`, `yyy` or `zzz` matches one of the fields, this constructor is implemented and the matching arguments are stored in the corresponding fields)


TODO
----

* update `@synthesize` when a field name changes (i.e. prefix added/removed)
* generate/update `dealloc`
* auto-add `#import`
* auto-generate missing fields for declared properties
* when you declare a method, add a stub implementation
* when you declare `+ (Foo *)sharedSomething`, insert the singleton boilerplate code


License
-------

XD.R.Y. is licensed under the MIT license. Please see LICENSE file for details.


Hacking
-------

To run the tests, you need rspec, and also, since they are all based on string comparison, you will also want diff-lcs:

    sudo gem install rake rspec diff-lcs

To run the tests, use:

    rake

If something goes wrong, you will want to have a verbose output:

    VERBOSE=1 rake

(You can also run the tests using `spec -b -c -Du .`, which is exactly what `rake` does.)

To fix something, please:

1. Fork [the project on GitHub](http://github.com/mockko/xdry) and checkout your fork.
2. Create a branch for your fix: `git checkout -b fix-foo-doesnt-do-bar`
3. Add a test for the future fix to `spec/` before changing anything.
4. Run the tests to make sure the new test does not pass.
5. Fix the code until all tests pass again.
6. Commit. (You can commit several times, but you get bonus points if you can squash it all into a single commit before asking me to pull.)
7. Push your branch to GitHub. If you have [git_remote_branch](http://github.com/webmat/git_remote_branch) installed (recommended), do `grb publish fix-foo-doesnt-do-bar`; otherwise, just `git push origin fix-foo-doesnt-do-bar`. (To publish again, just run `git push`.)
8. Send me a pull request via GitHub.
