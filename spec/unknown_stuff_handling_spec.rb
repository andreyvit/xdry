require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "XDry" do

  it "should not choke on unknown types" do
    xdry <<-END
      @interface Foo {
        Foo Bar Buuuzzzzza _something;
      }

      @end

      @implementation Foo
      @end
    END
  end

end
