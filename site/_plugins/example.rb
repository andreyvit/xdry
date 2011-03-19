
module Jekyll
  class HelloTag < Liquid::Block

    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render(context)
      ['<div class="example">'] + super + ['</div>']
    end
  end
end

Liquid::Template.register_tag('example', Jekyll::HelloTag)
