require 'spec_helper'

describe AB::Alternative do
  before do
    @test = AB::Test.new(:home_page, "Red or blue home page")
    AB.redis.flushall
  end

  describe "#value" do
    it "returns the result of the value_proc" do
      alternative = AB::Alternative.new(@test, :red) { "red.erb" }
      alternative.value.should == "red.erb"
    end
  end

  describe "views_key" do
    it "returns the experiments namespace with the test name and alternative name" do
      alternative = AB::Alternative.new(@test, :red) { "red.erb" }
      alternative.views_key.should == "ab:home_page:red"
    end
  end

  describe "view!" do
    it "tracks the view (once per identity)" do
      alternative = AB::Alternative.new(@test, :red) { "red.erb" }

      running {
        alternative.view! 123
      }.should change { alternative.views }

      running {
        alternative.view! 123
      }.should_not change { alternative.views }
    end

    it "does not update timestamp" do
      alternative = AB::Alternative.new(@test, :red) { "red.erb" }
      AB.redis.zadd(alternative.views_key, 1000, 123)
      alternative.view! 123
      AB.redis.zscore(alternative.views_key, 123).should == "1000"
    end

    it "does not track the view if the identity is nil" do
      alternative = AB::Alternative.new(@test, :red) { "red.erb" }
      running {
        alternative.view! nil
      }.should_not change { AB.redis.dbsize }
    end
  end

  describe "views" do
    it "returns the number of views tracked" do
      alternative = AB::Alternative.new(@test, :red) { "red.erb" }
      alternative.views.should == 0
      alternative.view! 123
      alternative.views.should == 1
      alternative.view! 789
      alternative.views.should == 2
      alternative.view! 123
      alternative.views.should == 2
    end
  end

  describe "conversions_key" do
    it "returns views_key with :conversions suffix" do
      alternative = AB::Alternative.new(@test, :red) { "red.erb" }
      alternative.conversions_key.should == "ab:home_page:red:conversions"
    end
  end

  describe "track_conversion!" do
    before do
      @alternative = AB::Alternative.new(@test, :red) { "red.erb" }
    end

    it "tracks the conversion (once per identity)" do
      @alternative.view! 123

      running {
        @alternative.track_conversion! 123
      }.should change { @alternative.conversions }.by(1)

      running {
        @alternative.track_conversion! 123
      }.should_not change { @alternative.conversions }
    end

    it "does not track conversion if identity did not view alternative" do
      running {
        @alternative.track_conversion! 123
      }.should_not change { @alternative.conversions }
    end

    it "does not track the conversion if the identity is nil" do
      running {
        @alternative.track_conversion! nil
      }.should_not change { AB.redis.dbsize }
    end
  end
end
