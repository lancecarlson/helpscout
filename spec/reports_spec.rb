require "spec_helper"

describe "Reports" do
  let(:helpscout) { HelpScout::Client.new(ENV["HELPSCOUT_API_KEY"]) }

  it "should show conversation: overall report" do
    start_time = Time.now - 5000000
    end_time = Time.now

    opts = {
      "previousStart": Time.now - 100000,
      "previousEnd": Time.now - 50000
    }

    query = HelpScout::Reports::Query.new(start_time, end_time, opts)

    #resp = helpscout.reports.conversations(query)
    #p resp
  end

  it "should show user: overall report" do
    start_time = Time.now - 5000000
    end_time = Time.now

    opts = {
      "previousStart": Time.now - 100000,
      "previousEnd": Time.now - 50000
    }

    query = HelpScout::Reports::UsersQuery.new(start_time, end_time, 210750, opts)

    resp = helpscout.reports.users(query)
    #expect(resp).to respond_to(:filterTags)
    #expect(resp).to respond_to(:user)
#    p resp.current
  end
end
