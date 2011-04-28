module AB
  class Alternative
    attr_reader :name
    attr_accessor :range

    def initialize(test, name, options = {}, &value_proc)
      @test, @name, @options, @value_proc = test, name, options, value_proc
      @test.update_percentage_range(self) if percent
    end

    def percent
      @options[:percent]
    end

    def value
      @value ||= @value_proc.call
    end

    def views_key
      @views_key ||= "ab:#{@test.name}:#{@name}"
    end

    def view!(identity)
      return if identity.nil?
      return if redis.zscore(views_key, identity)
      score = Time.now.to_i
      redis.zadd(views_key, score, identity)
    end

    def views
      redis.zcard(views_key)
    end

    def conversions_key
      @conversions_key ||= views_key + ":conversions"
    end

    def track_conversion!(identity)
      return if identity.nil?
      return if redis.zscore(conversions_key, identity)
      return unless redis.zscore(views_key, identity)
      score = Time.now.to_i
      redis.zadd(conversions_key, score, identity)
    end

    def conversions
      redis.zcard(conversions_key)
    end

    def results
      {
        :name => name,
        :value => value,
        :views => views,
        :conversions => conversions,
        :percent => percent
      }
    end

    private

    def redis
      AB.redis
    end
  end
end
