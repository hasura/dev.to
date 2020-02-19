require "rails_helper"

RSpec.describe Search::QueryBuilders::ChatChannelMembership, type: :service do
  describe "::initialize" do
    it "sets params" do
      filter_params = { foo: "bar" }
      filter = described_class.new(filter_params, 1)
      expect(filter.params).to include(filter_params)
    end

    it "builds query body" do
      filter = described_class.new({}, 1)
      expect(filter.body).not_to be_nil
    end
  end

  describe "#as_hash" do
    it "applies FILTER_KEYS from params" do
      params = { channel_status: "active", channel_type: "direct", status: "open" }
      filter = described_class.new(params, 1)
      expected_filters = [
        { "terms" => { "channel_status" => "active" } },
        { "terms" => { "channel_type" => "direct" } },
        { "terms" => { "status" => "open" } },
        { "terms" => { "viewable_by" => 1 } },
      ]
      expect(filter.as_hash.dig("bool", "filter")).to match_array(expected_filters)
    end

    it "ignores params we dont support" do
      params = { not_supported: "direct", status: "closed" }
      filter = described_class.new(params, 1)
      expected_filters = [
        { "terms" => { "status" => "closed" } },
        { "terms" => { "viewable_by" => 1 } },
      ]
      expect(filter.as_hash.dig("bool", "filter")).to match_array(expected_filters)
    end

    it "sets default params when not present" do
      filter = described_class.new({}, 1)
      expect(filter.as_hash.dig("sort")).to eq("channel_last_message_at" => "desc")
      expect(filter.as_hash.dig("size")).to eq(0)
    end

    it "allows default params to be overriden" do
      params = { sort_by: "channel_name", sort_direction: "asc", size: 20 }
      filter = described_class.new(params, 1)
      expect(filter.as_hash.dig("sort")).to eq("channel_name" => "asc")
      expect(filter.as_hash.dig("size")).to eq(20)
    end
  end
end
