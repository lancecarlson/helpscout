module HelpScout
  class Reports
    class ReportEnvelope
      attr_reader :item

      def initialize(object)
        @item = object
      end
    end

    def initialize(auth)
      @auth = auth
    end

    def conversations(start_time, end_time, options = {})
      url = "/reports/conversations.json"

      start_time = start_time.utc.iso8601
      end_time = end_time.utc.iso8601

      options = {
        "start": start_time,
        "end": end_time,
        "page": 1
      }

      p options

      begin
        items = HelpScout::Client.request_item(@auth, url, options, ReportEnvelope)
        p items
        #items.each do |item|
         # p item
#          ratings << Rating.new(item)
        #end
#        page = page + 1
      rescue StandardError => e
        puts "Request failed: #{e.message}"
      end
    end
  end
end
