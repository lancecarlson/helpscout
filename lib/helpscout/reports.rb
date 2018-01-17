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

      if start_time.is_a?(Time)
        start_time = start_time.utc.iso8601
      end

      if end_time.is_a?(Time)
        end_time = end_time.utc.iso8601
      end

      previous_start = options["previousStart"]
      previous_end = options["previousEnd"]

      if previous_start.is_a?(Time)
        options["previousStart"] = previous_start.utc.iso8601
      end

      if previous_end.is_a?(Time)
        options["previousEnd"] = previous_end.utc.iso8601
      end

      params = {
        "start": start_time,
        "end": end_time,
        "page": 1
      }.merge(options)

      begin
        item = HelpScout::Client.request_item(@auth, url, params, ReportEnvelope)
        report = Models::ConversationsReport.new(item)
        #p report
        report
      rescue StandardError => e
        puts "Request failed: #{e.message}"
      end
    end

    module Models
      class FilterTag
        attr_reader :id, :name

        def initialize(object)
          data = object.clone
          @id = data.delete("id")
          @name = data.delete("name")
          # TODO: log extra data coming through
        end
      end

      class ConversationsReport
        attr_reader :day, :hour, :count

        class BusiestDay
          def initialize(object)
            data = object.clone
            @day = data.delete("day")
            @hour = data.delete("hour")
            @count = data.delete("count")
            # TODO: log extra data coming through
          end
        end

        class Volume
          attr_reader :startDate, :endDate, :totalConversations, :conversationsCreated, :newConversations, :customers, :messagesReceived, :days, :conversationsPerDay

          def initialize(object)
            data = object.clone
            @startDate = DateTime.iso8601(data.delete("startDate"))
            @endDate = DateTime.iso8601(data.delete("endDate"))
            @totalConversations = data.delete("totalConversations")
            @totalConversationsCreated = data.delete("conversationsCreated")
            @newConversations = data.delete("newConversations")
            @customers = data.delete("customers")
            @messagesReceived = data.delete("messagesReceived")
            @days = data.delete("days")
            @conversationsPerDay = data.delete("conversationsPerDay")
            # TODO: log extra data coming through
          end
        end

        class Statistics
          attr_reader :id, :count, :percent, :previousCount, :previousPercent, :deltaPercent

          def initialize(object)
            data = object.clone
            @id = data.delete("id")
            @name = data.delete("name")
            @count = data.delete("count")
            @previousCont = data.delete("previousCount")
            @percent = data.delete("percent")
            @previousPercent = data.delete("previousPercent")
            @deltaPercent = data.delete("deltaPercent")
            # TODO: log extra data coming through
          end
        end

        class TagStatistics < Statistics; end
        class CustomerStatistics < Statistics; end

        class ReplyStatistics < Statistics
          attr_reader :mailboxId

          def initialize(object)
            super(object)
            data = object.clone
            @mailboxId = data.delete("mailboxId")
            # TODO: log extra data coming through
          end
        end

        class WorkflowStatistics < Statistics; end

        # tagCount is specific to this library
        attr_reader :filterTags, :companyId, :busiestDay, :busyTimeStart, :busyTimeEnd,
                    :customers, :customerCount,
                    :tags, :tagCount,
                    :replies, :replyCount,
                    :workflows, :workflowCount,
                    :customFields, :customFieldCount

        def initialize(object)
          @customers = object["customers"]
          @companyId = object["companyId"]

          @filterTags = []
          object["filterTags"].each do |ft|
            @filterTags << FilterTag.new(ft)
          end

          @busiestDay = BusiestDay.new(object["busiestDay"])

          @busyTimeStart = object["busyTimeStart"]
          @busyTimeEnd = object["busyTimeEnd"]

          @current = Volume.new(object["current"])

          if object.key?("previous")
            @previous = Volume.new(object["previous"])
          end

          @tags = []
          @tagCount = object["tags"]["count"]

          object["tags"]["top"].each do |tag|
            @tags << TagStatistics.new(tag)
          end

          @customers = []
          @customerCount = object["customers"]["count"]

          object["customers"]["top"].each do |customer|
            @customers << CustomerStatistics.new(customer)
          end

          @replies = []
          @replyCount = object["replies"]["count"]

          object["replies"]["top"].each do |reply|
            @replies << ReplyStatistics.new(reply)
          end

          @workflows = []
          @workflowCount = object["workflows"]["count"]

          object["workflows"]["top"].each do |workflow|
            @workflows << WorkflowStatistics.new(workflow)
          end

          @customFieldCount = object["customFields"]["count"]
        end

        private
      end
    end
  end
end
