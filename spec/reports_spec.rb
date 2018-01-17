require "spec_helper"

describe "Reports" do
  let(:helpscout) { HelpScout::Client.new(ENV["HELPSCOUT_API_KEY"]) }

  it "should list reports" do
    start_time = Time.now - 5000000
    end_time = Time.now

    opts = {
#      previousStart: Time.now - 100000,
#      end_time: Time.now - 50000
    }

    helpscout.reports.conversations(start_time, end_time, opts)
  end
end
