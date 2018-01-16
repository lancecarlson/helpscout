require "spec_helper"

describe "Reports" do
  let(:helpscout) { HelpScout::Client.new(ENV["HELPSCOUT_API_KEY"]) }

  it "should list reports" do
    start_time = Time.now - 500000
    end_time = Time.now
    helpscout.reports.conversations(start_time, end_time)
  end
end
