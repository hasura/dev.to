module Search
  module QueryBuilders
    class ChatChannelMembership
      FILTER_KEYS = %i[
        channel_status
        channel_type
        status
        viewable_by
      ].freeze

      DEFAULT_PARAMS = {
        sort_by: "channel_last_message_at",
        sort_direction: "desc",
        size: 0
      }.freeze

      attr_accessor :params, :body

      def initialize(params, user_id)
        @params = params.deep_symbolize_keys
        @params[:viewable_by] = user_id
        build_body
      end

      def as_hash
        @body
      end

      private

      def build_body
        @body = ActiveSupport::HashWithIndifferentAccess.new
        build_queries
        add_sort
      end

      def build_queries
        @body[:bool] = { filter: filter_conditions }
        @body[:bool][:must] = add_query_string if @params[:query_string]
      end

      def add_sort
        sort_key = @params[:sort_by] || DEFAULT_PARAMS[:sort_by]
        sort_direction = @params[:sort_direction] || DEFAULT_PARAMS[:sort_direction]
        @body[:sort] = {
          sort_key => sort_direction
        }
        @body[:size] = @params[:size] || DEFAULT_PARAMS[:size]
      end

      def filter_conditions
        FILTER_KEYS.map do |filter_key|
          next if @params[filter_key].blank?

          { terms: { filter_key => @params[filter_key] } }
        end.compact
      end

      def add_query_string
        {
          query_string: {
            query: @params[:query_string],
            analyze_wildcard: true,
            allow_leading_wildcard: false
          }
        }
      end
    end
  end
end
