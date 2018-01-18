module HelpScout
  class Reports
    class ReportEnvelope
      attr_reader :item

      def initialize(object)
        @item = object
      end
    end

    class Query
      def initialize(start_time, end_time, options = {})
        @start_time = start_time
        @end_time = end_time

        if @start_time.is_a?(Time)
          @start_time = @start_time.utc.iso8601
        end

        if @end_time.is_a?(Time)
          @end_time = @end_time.utc.iso8601
        end

        @options = options

        previousStart = @options[:previousStart]
        previousEnd = @options[:previousEnd]
        if previousStart.is_a?(Time)
          @options[:previousStart] = previousStart.utc.iso8601
        end

        if previousEnd.is_a?(Time)
          @options[:previousEnd] = previousEnd.utc.iso8601
        end
      end

      def to_params
        params = {
          "start": @start_time,
           "end": @end_time,
           "page": 1
        }.merge(@options)
      end
    end

    class UsersQuery < Query
      def initialize(start_time, end_time, user, options = {})
        @user = user.to_i
        options[:user] = @user
        super(start_time, end_time, options)
      end
    end

    def initialize(auth)
      @auth = auth
    end

    def conversations(start_time, end_time, options = {})
      url = "/reports/conversations.json"

      query = Query.new(start_time, end_time, options)

      begin
        item = HelpScout::Client.request_item(@auth, url, query.to_params, ReportEnvelope)
        Models::ConversationsReport.new(item)
      rescue StandardError => e
        puts "Request failed: #{e.message}"
      end
    end

    def company(start_time, end_time, options = {})
      url = "/reports/company.json"

      query = Query.new(start_time, end_time, options)

      #begin
        item = HelpScout::Client.request_item(@auth, url, query.to_params, ReportEnvelope)
        Models::CompanyReport.new(item)
      #rescue StandardError => e
      #  puts "Request failed: #{e.message}"
      #end
    end

    def users(start_time, end_time, user, options = {})
      url = "/reports/user.json"

      query = UsersQuery.new(start_time, end_time, user, options)

      begin
        item = HelpScout::Client.request_item(@auth, url, query.to_params, ReportEnvelope)
        Models::UsersReport.new(item)
      rescue StandardError => e
        puts "Request failed: #{e.message}"
      end
    end

    module Models
      module FilterTaggable
        class FilterTag
          attr_reader :id, :name

          def initialize(object)
            data = object.dup
            @id = data.delete("id")
            @name = data.delete("name")
            # TODO: log extra data coming through
          end
        end

        def parse_filter_tags(object)
          @filterTags = []
          object["filterTags"].each do |ft|
            @filterTags << FilterTag.new(ft)
          end
        end
      end

      class Statistics
        attr_reader :id, :count, :percent, :previousCount, :previousPercent, :deltaPercent

        def initialize(object)
          data = object.dup
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
          data = object.dup
          @mailboxId = data.delete("mailboxId")
          # TODO: log extra data coming through
        end
      end

      class WorkflowStatistics < Statistics; end

      class ConversationsReport
        class BusiestDay
          attr_reader :day, :hour, :count

          def initialize(object)
            data = object.dup
            @day = data.delete("day")
            @hour = data.delete("hour")
            @count = data.delete("count")
            # TODO: log extra data coming through
          end
        end

        class Volume
          attr_reader :startDate, :endDate, :totalConversations, :conversationsCreated, :newConversations, :customers, :messagesReceived, :days, :conversationsPerDay

          def initialize(object)
            data = object.dup
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

        class CustomField
          class Value
            attr_reader :id, :name, :count, :percent

            def initialize(object)
              data = object.dup
              @id = data.delete("id").to_i
              @name = data.delete("name")
              @count = data.delete("count").to_i
              @percent = data.delete("percent")
            end
          end

          class Summary
            attr_reader :total, :totalAnswered, :previousTotal, :previousTotalAnswered, :unansweredDelta, :unansweredPreviousPercent, :unansweredPercent

            def initialize(object)
              data = object.dup
              @total = data.delete("total").to_i
              @totalAnswered = data.delete("totalAnswered").to_i
              @previousTotal = data.delete("previousTotal")
              @previousTotalAnswered = data.delete("previousTotalAnswered")
              @unansweredDelta = data.delete("unansweredDelta")
              @unansweredPreviousPercent = data.delete("unansweredPreviousPercent")
              @unansweredPercent = data.delete("unansweredPercent")
            end
          end

          attr_reader :id, :name, :mailboxId, :values, :summary

          def initialize(object)
            data = object.dup
            @id = data.delete("id").to_i
            @name = data.delete("name")
            @mailboxId = data.delete("mailboxId").to_i

            @values = []
            data.delete["values"].each do |value|
              @values << Value.new(value)
            end

            @summary = Summary.new(data.delete("summary"))
          end
        end

        include FilterTaggable

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

          parse_filter_tags(object)
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

          @customFields = []
          @customFieldCount = object["customFields"]["count"]

          object["customFields"]["fields"].each do |field|
            @customFields << CustomField.new(field)
          end
        end

        private
      end

      class CompanyReport
        include FilterTaggable

        class User
          attr_reader :name, :user, :handleTime, :replies, :customersHelped, :closed, :happinessScore, :previousHandleTime, :previousReplies, :previousCustomersHelped, :previousClosed, :previousHappinessScore

          def initialize(object)
            data = object.dup
            @name = data.delete("name")
            @user = data.delete("user").to_i
            @handleTime = data.delete("handleTime")
            @replies = data.delete("replies").to_i
            @customersHelped = data.delete("customersHelped").to_i
            @closed = data.delete("closed").to_i
            @happinessScore = data.delete("happinessScore")
            @previousHandleTime = data.delete("previousHandleTime")
            @previousReplies = data.delete("previousReplies")
            @previousCustomersHelped = data.delete("previousCustomersHelped")
            @previousClosed = data.delete("previousClosed")
            @previousHappinessScore = data.delete("previousHappinessScore")
          end
        end

        class Performance
          attr_reader :startDate, :endDate, :customersHelped, :closed, :totalReplies, :totalUsers, :totalDays, :repliesPerDayPerUser, :repliesPerDay, :resolvedPerDay
          attr_reader :range

          def initialize(object, range)
            @range = range
            data = object.dup

            if range == :deltas
            else
              @startDate = DateTime.iso8601(data.delete("startDate"))
              @endDate = DateTime.iso8601(data.delete("endDate"))
            end

            @customersHelped = data.delete("customersHelped").to_i
            @closed = data.delete("closed").to_i
            @totalReplies = data.delete("totalReplies").to_i
            @totalUsers = data.delete("totalUsers").to_i
            @totalDays = data.delete("totalDays").to_i
            @repliesPerDayPerUser = data.delete("repliesPerDayPerUser")
            @repliesPerDay = data.delete("repliesPerDay")
            @resolvedPerDay = data.delete("resolvedPerDay")
          end
        end

        def initialize(object)
          data = object.dup
          @current = Performance.new(data.delete("current"), :current)

          if data.key?("previous")
            @previous = Performance.new(data.delete("previous"), :previous)
          end

          @deltas = Performance.new(data.delete("deltas"), :deltas)

          @users = []
          object["users"].each do |user|
            @users << User.new(user)
          end
        end
      end

      class UsersReport
        include FilterTaggable

        class User
          attr_reader :id, :name, :hasPhoto, :photoUrl, :totalCustomersHelped, :createdAt

          def initialize(object)
            data = object.dup
            @id = data.delete("id").to_i
            @name = data.delete("name")
            @hasPhoto = data.delete("hasPhoto")
            @photoUrl = data.delete("photoUrl")
            @totalCustomersHelper = data.delete("totalCustomersHelped")
            @createdAt = DateTime.iso8601(data.delete("createdAt"))
          end
        end

        class UserStatistics
          attr_reader :startDate, :endDate,
                      :totalDays, :resolved, :conversationsCreated, :closed,
                      :totalReplies, :resolvedOnFirstReply, :percentResolvedOnFirstReply, :repliesToResolve,
                      :handleTime, :happinessScore, :responseTime, :resolutionTime,
                      :repliesPerDay, :averageFirstResponseTime, :customersHelped, :totalConversations,
                      :busiestDay, :conversationsPerDay
          attr_reader :range


          def initialize(object, range)
            @range = range

            data = object.dup

            if range == :deltas
              @activeConversations = data.delete("activeConversations")
            else
              @startDate = DateTime.iso8601(data.delete("startDate"))
              @endDate = DateTime.iso8601(data.delete("endDate"))
            end

            @totalDays = data.delete("totalDays").to_i
            @resolved = data.delete("resolved").to_i
            @conversationsCreated = data.delete("conversationsCreated").to_i
            @closed = data.delete("closed").to_i
            @totalReplies = data.delete("totalReplies").to_i
            @resolvedOnFirstReply = data.delete("resolvedOnFirstReply").to_i
            @percentResolvedOnFirstReply = data.delete("percentResolvedOnFirstReply")
            @repliesToResolve = data.delete("repliesToResolve")
            @handleTime = data.delete("handleTime")
            @happinessScore = data.delete("happinessScore")
            @responseTime = data.delete("responseTime").to_i
            @resolutionTime = data.delete("resolutionTime")
            @repliesPerDay = data.delete("repliesPerDay")
            @averageFirstResponseTime = data.delete("averageFirstResponseTime")
            @customersHelped = data.delete("customersHelped").to_i,
            @totalConversations = data.delete("totalConversations").to_i
            @busiestDay = data.delete("busiestDay").to_i
            @conversationsPerDay = data.delete("conversationsPerDay")
          end
        end

        attr_reader :filterTags, :user, :current, :previous, :deltas

        def initialize(object)
          parse_filter_tags(object)
          @user = User.new(object["user"])
          @current = UserStatistics.new(object["current"], :current)
          @previous = UserStatistics.new(object["previous"], :previous)
          @delta = UserStatistics.new(object["deltas"], :deltas)
        end
      end
    end
  end
end
