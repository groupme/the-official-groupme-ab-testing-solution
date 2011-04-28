module AB
  class << self
    def define(name, description, &block)
      raise ArgumentError, "#{name.inspect} is already an AB test" if tests.has_key?(name)
      t = AB::Test.new(name, description)
      t.instance_eval(&block) if block_given?
      t.verify_percentages
      tests[name] = t
    end

    def get(name)
      tests[name]
    end

    def track(name, identity)
      test = get(name)
      alternative = test.get_alternative(identity)
      begin
        alternative.track_conversion!(identity)
      rescue Timeout::Error
        # Don't track data if redis is down
      end
    end

    def test(name, identity)
      test = get(name)
      alternative = test.get_alternative(identity)
      begin
        alternative.view!(identity)
      rescue Timeout::Error
        # Don't track data if redis is down
      end
      alternative.value
    end

    private

    def tests
      @tests ||= {}
    end
  end
end
