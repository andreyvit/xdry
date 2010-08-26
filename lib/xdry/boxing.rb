module XDry

  module RetainPolicy

    module ASSIGN_VALUE
      def self.retain expr
        expr
      end

      def self.release out, expr
      end

      def self.release_and_clear out, var_name
      end
    end

    module ASSIGN_REF
      def self.retain expr
        expr
      end

      def self.release out, expr
      end

      def self.release_and_clear out, var_name
        out << "#{var_name} = nil;";
      end
    end

    module COPY
      def self.retain expr
        "[#{expr} copy]"
      end

      def self.release out, expr
        out << "[#{expr} release]";
      end

      def self.release_and_clear out, var_name
        out << "[#{var_name} release], #{var_name} = nil;";
      end
    end

    module RETAIN
      def self.retain expr
        "[#{expr} retain]"
      end

      def self.release out, expr
        out << "[#{expr} release]";
      end

      def self.release_and_clear out, var_name
        out << "[#{var_name} release], #{var_name} = nil;";
      end
    end

  end

  module Boxing

    class Boxer
      def unbox_retained out, object_expr
        retain_policy.retain(unbox(out, object_expr))
      end
    end

    class NSNumberConverter < Boxer
      def initialize init_selector, repr_selector
        @init_selector = init_selector
        @repr_selector = repr_selector
      end

      def box out, data_expr
        "[NSNumber #{@init_selector}:#{data_expr}]"
      end

      def unbox out, object_expr
        "[#{object_expr} #{@repr_selector}]"
      end

      def retain_policy; RetainPolicy::ASSIGN_VALUE; end
    end

    class DateConverter < Boxer
      def box out, data_expr
        SIMPLE_CONVERTIONS['double'].box out, "[#{data_expr} timeIntervalSinceReferenceDate]"
      end

      def unbox out, object_expr
        number = SIMPLE_CONVERTIONS['double'].unbox(out, object_expr)
        "[NSDate dateWithTimeIntervalSinceReferenceDate:#{number}]"
      end

      def retain_policy; RetainPolicy::RETAIN; end
    end

    class NopConverter < Boxer
      def box out, data_expr
        data_expr
      end

      def unbox out, object_expr
        object_expr
      end

      def retain_policy; RetainPolicy::RETAIN; end
    end

    class StringConverter < Boxer
      def box out, data_expr
        data_expr
      end

      def unbox out, object_expr
        object_expr
      end

      def retain_policy; RetainPolicy::COPY; end
    end

    SIMPLE_CONVERTIONS = {
      'int' => NSNumberConverter.new('intValue', 'numberWithInt'),
      'NSInteger' => NSNumberConverter.new('integerValue', 'numberWithInteger'),
      'NSUInteger' => NSNumberConverter.new('unsignedIntegerValue', 'numberWithUnsignedInteger'),
      'BOOL' => NSNumberConverter.new('boolValue', 'numberWithBool'),
      'float' => NSNumberConverter.new('floatValue', 'numberWithFloat'),
      'double' => NSNumberConverter.new('doubleValue', 'numberWithDouble'),
    }

    POINTER_CONVERTIONS = {
      'NSDate' => DateConverter.new,
      'NSString' => StringConverter.new,
    }

    def self.converter_for type
      case type
      when OSimpleVarType
        SIMPLE_CONVERTIONS[type.name]
      when OPointerVarType
        POINTER_CONVERTIONS[type.name]
      else
        nil
      end
    end
  end

end
