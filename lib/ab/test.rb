module AB
  class Test
    attr_reader :name, :description, :alternatives

    def initialize(name, description)
      @name, @description, @alternatives, @last_percent= name, description, [], 0
    end

    def alternative(name, options={}, &value_proc)
      alternative = AB::Alternative.new(self, name, options, &value_proc)
      alternatives << alternative
      alternative
    end

    def use(name)
      begin
        @using = alternatives.detect { |alternative| alternative.name == name }
        yield
      ensure
        @using = nil
      end
    end

    def get_alternative(identity)
      return @using if @using

      if identity.nil?
        return alternatives.first
      end

      if alternatives.any?(&:percent)
        alternatives.detect { |alternative| alternative.range.include?(identity % 100) }
      else
        alternatives[identity % alternatives.size]
      end
    end

    def update_percentage_range(alternative)
      percent = alternative.percent - 1
      alternative.range = @last_percent..(@last_percent + percent)
      @last_percent = alternative.range.last + 1
    end

    def verify_percentages
      return unless alternatives.any?(&:percent)
      raise ArgumentError.new("Some alternatives are missing percentages") unless alternatives.all?(&:percent)
      raise ArgumentError.new("Percentages must add up to 100") unless @last_percent == 100
    end

    def results
      alternatives.map(&:results)
    end
  end
end
