require "spec/spec_helper"

describe AB do
  after do
    AB.send(:tests).delete(:home_page)
    AB.redis.flushall
  end

  describe ".define" do
    it "defines an AB test" do
      AB.define :home_page, "Big red button or big blue button versions" do
        alternative(:red) { "red.erb" }
        alternative(:blue) { "blue.erb" }
      end

      test = AB.get(:home_page)
      test.name.should == :home_page
      test.description.should == "Big red button or big blue button versions"
      test.should have(2).alternatives
      red_alternative = test.alternatives.first
      red_alternative.name.should == :red
      red_alternative.value.should == "red.erb"
    end

    it "raises when you try to define the same test twice" do
      AB.define(:home_page, "Big red button")
      running {
        AB.define(:home_page, "Other big red button")
      }.should raise_error(ArgumentError)
    end

    it "can set a percentage for alternatives" do
      AB.define :home_page, "Red button or blue button" do
        alternative(:red, :percent => 10) { "red.erb" }
        alternative(:red, :percent => 90) { "blue.erb" }
      end

      0.upto(9) { |i| AB.test(:home_page, i).should == "red.erb" }
      10.upto(99) { |i| AB.test(:home_page, i).should == "blue.erb" }
    end

    it "explodes if percentage sum does not equal 100" do
      running {
        AB.define :home_page, "Red button or blue button" do
          alternative(:red, :percent => 10) { "red.erb" }
          alternative(:red, :percent => 80) { "blue.erb" }
        end
      }.should raise_error(ArgumentError)
    end

    it "explodes if percentages are only set on some of the alternatives" do
      running {
        AB.define :home_page, "Red button or blue button" do
          alternative(:red, :percent => 10) { "red.erb" }
          alternative(:red) { "blue.erb" }
        end
      }.should raise_error(ArgumentError)
    end
  end

  describe ".test" do
    before do
      @test = AB.define :home_page, "Red or Blue home page" do
        alternative(:red) { "red.erb" }
        alternative(:blue) { "blue.erb" }
      end
    end

    it "returns an alternative value" do
      value = AB.test(:home_page, 123)
      ["red.erb", "blue.erb"].should include(value)
    end

    it "increases the views for the alternative" do
      alternative = @test.get_alternative(123)
      running {
        AB.test(:home_page, 123)
      }.should change { alternative.views }.by(1)
    end

    it "rescues Redis failures and still returns a value" do
      AB.redis.should_receive(:zadd).and_raise(Timeout::Error.new("time's up!"))
      running {
        value = AB.test(:home_page, 123)
        ["red.erb", "blue.erb"].should include(value)
      }.should_not raise_error
    end
  end

  describe ".track" do
    before do
      @test = AB.define :home_page, "Red or blue home page" do
        alternative(:red) { "red.erb" }
        alternative(:blue) { "blue.erb" }
      end

      @alternative = @test.get_alternative(123)
      @alternative.view! 123
    end

    it "increases the conversions for the alternative" do
      running {
        AB.track :home_page, 123
      }.should change { @alternative.conversions }.by(1)
    end

    it "rescues Redis timeout failures" do
      AB.redis.should_receive(:zscore).and_raise(Timeout::Error.new("time's up!"))
      running {
        AB.track :home_page, 123
      }.should_not raise_error
    end
  end
end
