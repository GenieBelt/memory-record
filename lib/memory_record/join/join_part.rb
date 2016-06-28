module MemoryRecord
  class JoinPart
    def initialize(base_name, result_hash)
      @result = result_hash
      @base = base_name.to_sym
      @keys = result_hash.keys.map(&:to_sym)
    end

    def respond_to?(method)
      super ||
          if @keys.include?(method.to_sym) && method.to_sym != @base
            true
          else
            @result[@base].respond_to?(method)
          end
    end

    def ==(other)
      if other.kind_of? JoinPart
        super
      else
        @result[@base] == other
      end
    end

    def ===(other)
      @result.values.select { |object| object == other }.any?
    end

    def method_missing(method, *args)
      if @keys.include?(method.to_sym) && method.to_sym != @base
        @result[method.to_sym]
      else
        @result[@base].send(method, *args)
      end
    end

    def _result
      @result
    end

    def merge(new_values)
      if new_values.kind_of?(JoinPart)
        @result.merge! new_values._result
      else
        @result.merge! new_values
      end
      @keys = @result.keys.map(&:to_sym)
      self
    end
  end
end
