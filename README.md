# The Official GroupMe AB Testing Solution

Simple AB testing with Redis.

## USAGE

Define an AB test:

    AB.define :new_twitter, "Show new Twitter or old Twitter to logged in users" do
      alternative(:new) { "new-twitter.erb" }
      alternative(:old) { "old-twitter.erb" }
    end

Currently, identity of experiment participants is determined by an integer you
pass when the participant views the experiment. Use `AB.test` to show always show
a participant a consistent experience.

    class TwitterController
      def show
        render :template => AB.test(:new_twitter, current_user.id)
      end
    end

If you don't have a current user, you can set a cookie or something:

    class HomepageController
      def index
        identifier = session[:ab_identifier] ||= rand(100)
        render :template => AB.test(:home_page, identifier)
      end
    end

To track conversions, use `AB.track`, passing the participant's identifier:

    class TwitterController
      def spend_dollahs
        AB.track(:new_twitter, current_user.id)
      end
    end

or with a cookie:

    class HomepageController
      def signup
        AB.test(:home_page, session[:ab_identifier])
      end
    end

To get at your results, you can get a test, and call `results`.

    AB.get(:home_page).results

### TODO

* More interesting statistics, including relevance information
* Pretty printing of stats to the command line
* Pretty web interface
