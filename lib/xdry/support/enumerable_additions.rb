
module XDry

  module EnumerableAdditions

    def prefix_while
      result = []
      each do |item|
        if yield(item)
          result << item
        else
          break
        end
      end
      return result
    end

    def suffix_while
      result = []
      reverse_each do |item|
        if yield(item)
          result << item
        else
          break
        end
      end
      return result.reverse!
    end

  end

  # tried to extend Enumerable here, but it did not work, so resorted to only extending Array
  Array.send(:include, EnumerableAdditions)

end
