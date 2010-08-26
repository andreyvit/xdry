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
      def unbox_retained out, object_expr, tempvar_prefix
        retain_policy.retain(unbox(out, object_expr, tempvar_prefix))
      end
    end

    class NSNumberConverter < Boxer
      def initialize repr_selector, init_selector
        @init_selector = init_selector
        @repr_selector = repr_selector
      end

      def box out, data_expr, tempvar_prefix
        "[NSNumber #{@init_selector}:#{data_expr}]"
      end

      def unbox out, object_expr, tempvar_prefix
        "[#{object_expr} #{@repr_selector}]"
      end

      def retain_policy; RetainPolicy::ASSIGN_VALUE; end
    end

    class DateConverter < Boxer
      def box out, data_expr, tempvar_prefix
        SIMPLE_CONVERTIONS['double'].box out, "[#{data_expr} timeIntervalSinceReferenceDate]"
      end

      def unbox out, object_expr, tempvar_prefix
        number = SIMPLE_CONVERTIONS['double'].unbox(out, object_expr)
        "[NSDate dateWithTimeIntervalSinceReferenceDate:#{number}]"
      end

      def retain_policy; RetainPolicy::RETAIN; end
    end

    class NopConverter < Boxer
      def box out, data_expr, tempvar_prefix
        data_expr
      end

      def unbox out, object_expr, tempvar_prefix
        object_expr
      end

      def retain_policy; RetainPolicy::RETAIN; end
    end

    class StringConverter < Boxer
      def box out, data_expr, tempvar_prefix
        data_expr
      end

      def unbox out, object_expr, tempvar_prefix
        object_expr
      end

      def retain_policy; RetainPolicy::COPY; end
    end

    class ArrayConverter < Boxer
      def initialize item_type, init_selector, repr_selector
        @item_type = item_type
        @init_selector = init_selector
        @repr_selector = repr_selector
      end

      def box out, data_expr, tempvar_prefix
        array_var = "#{tempvar_prefix}Array"
        item_var  = "#{tempvar_prefix}Item"

        out << "NSMutableArray *#{array_var} = [NSMutableArray array];"
        out.block "for (#{@item_type} *#{item_var} in #{data_expr})" do
          out << "[#{array_var} addObject:[#{item_var} #{@repr_selector}]];"
        end
        "#{array_var}"
      end

      def unbox out, object_expr, tempvar_prefix
        unbox_internal out, object_expr, tempvar_prefix, "[NSMutableArray array]"
      end

      def unbox_retained out, object_expr, tempvar_prefix
        unbox_internal out, object_expr, tempvar_prefix, "[[NSMutableArray alloc] init]"
      end

      def retain_policy; RetainPolicy::COPY; end

    private

      def unbox_internal out, object_expr, tempvar_prefix, array_init
        array_var = "#{tempvar_prefix}Array"
        item_dict_var  = "#{tempvar_prefix}ItemDictionary"
        item_var  = "#{tempvar_prefix}Item"

        out << "NSMutableArray *#{array_var} = #{array_init};"
        out.block "for (NSDictionary *#{item_dict_var} in (NSArray *) #{object_expr})" do
          out << "#{@item_type} *#{item_var} = [[#{@item_type} alloc] #{@init_selector}:#{item_dict_var}];"
          out << "[#{array_var} addObject:#{item_var}];"
          out << "[#{item_var} release];"
        end
        "#{array_var}"
      end
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
      case type.name
      when 'NSArray'
        return ArrayConverter.new(type.type_hint || 'NSObject', 'initWithDictionary', 'dictionaryRepresentation')
      end
      case type
      when OSimpleVarType
        SIMPLE_CONVERTIONS[type.name]
      when OPointerVarType
        POINTER_CONVERTIONS[type.name]
      else
        nil
      end
    end

    def self.retain_policy_of type
      if conv = converter_for(type)
        conv.retain_policy
      else
        case type
          when OPointerVarType then RetainPolicy::RETAIN
          when OIdVarType      then RetainPolicy::ASSIGN_REF
          when OSimpleVarType  then RetainPolicy::ASSIGN_VALUE
        end
      end
    end

  end

end
