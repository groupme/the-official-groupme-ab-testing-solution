require 'spec_helper'

describe AB::Test do
  describe "#get_alternative" do
    before do
      @test = AB::Test.new(:home_page, "Red or blue home page")
      @red = @test.alternative(:red) { "red.erb" }
      @blue = @test.alternative(:blue) { "blue.erb" }
    end

    it "returns the value of an alternative based on the identity (50/50)" do
      @test.get_alternative(0).should == @red
      @test.get_alternative(1).should == @blue
    end

    it "returns the value of an alternative based on the identity (33/33/33)" do
      @green = @test.alternative(:green) { "green.erb" } # add an additional alternative
      @test.get_alternative(0).should == @red
      @test.get_alternative(1).should == @blue
      @test.get_alternative(2).should == @green
    end

    it "returns the first alternative when identity is nil" do
      @test.get_alternative(nil).should == @red
    end
  end

  describe "#verify_percentages" do
    before do
      @test = AB::Test.new(:home_page, "Red or blue home page")
    end

    it "raises ArgumentError when some alternatives do not have percentages and some do" do
      @test.alternative(:red, :percent => 10) { "red.erb" }
      @test.alternative(:blue) { "blue.erb" }
      running {
        @test.verify_percentages
      }.should raise_error(ArgumentError)
    end

    it "raises ArgumentError when percentages do not add up to 100" do
      @test.alternative(:red, :percent => 10) { "red.erb" }
      @test.alternative(:blue, :percent => 10) { "blue.erb" }
      running {
        @test.verify_percentages
      }.should raise_error(ArgumentError)
    end
  end

  describe "#results" do
    before do
      @test = AB::Test.new(:home_page, "Red or blue home page")
      @red = @test.alternative(:red) { "red.erb" }
      @blue = @test.alternative(:blue) { "blue.erb" }
    end

    it "returns list of alternatives with stats" do
      @red.view! 123
      @red.track_conversion! 123
      @test.results.should == [
        { :name => :red, :value => "red.erb", :views => 1, :conversions => 1, :percent => nil },
        { :name => :blue, :value => "blue.erb", :views => 0, :conversions => 0, :percent => nil }
      ]
    end
  end

  describe "#use" do
    it "always returns the alternative passed in the block" do
      test = AB::Test.new(:home_page, "Red or blue home page")
      red = test.alternative(:red) { "red.erb" }
      blue = test.alternative(:blue) { "blue.erb" }

      test.use :red do
        test.get_alternative(0).should == red
        test.get_alternative(1).should == red
      end

      test.get_alternative(0).should == red
      test.get_alternative(1).should == blue
    end
  end
end
