require "spec_helper"

describe "Reports" do
  let(:helpscout) { HelpScout::Client.new(ENV["HELPSCOUT_API_KEY"]) }
  let(:user) { ENV["TEST_USER_ID"] }

  it "should show conversation: overall report" do
    start_time = Time.now - 5000000
    end_time = Time.now

    opts = {
      "previousStart": Time.now - 100000,
      "previousEnd": Time.now - 50000
    }

    resp = helpscout.reports.conversations(start_time, end_time, opts)
    p resp
  end

  it "should show user: overall report" do
    start_time = Time.now - 5000000
    end_time = Time.now

    opts = {
      "previousStart": Time.now - 100000,
      "previousEnd": Time.now - 50000
    }

    resp = helpscout.reports.users(start_time, end_time, user, opts)
    expect(resp).to respond_to(:filterTags)
    expect(resp).to respond_to(:user)
    expect(resp).to respond_to(:current)
    expect(resp).to respond_to(:previous)
    expect(resp).to respond_to(:deltas)
  end
end
