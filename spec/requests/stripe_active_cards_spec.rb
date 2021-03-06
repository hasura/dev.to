require "rails_helper"

RSpec.describe "StripeSubscriptions", type: :request do
  let(:user) { create(:user) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_source_token) { stripe_helper.generate_card_token }

  before do
    StripeMock.start
    sign_in user
  end

  after { StripeMock.stop }

  def valid_instance(user)
    customer = Stripe::Customer.create(
      email: "stripe_tester@dev.to",
      source: stripe_helper.generate_card_token,
    )
    user.update(stripe_id_code: customer.id)
  end

  describe "POST StripeActiveCards#create" do
    it "successfully adds a card to the correct user" do
      post "/stripe_active_cards", params: { stripe_token: stripe_helper.generate_card_token }
      card = Stripe::Customer.retrieve(user.stripe_id_code).sources.first
      expect(card.is_a?(Stripe::Card)).to eq(true)
    end

    it "increments sidekiq.errors in Datadog on failure" do
      allow(DataDogStatsClient).to receive(:increment)
      invalid_error = Stripe::InvalidRequestError.new(nil, nil)
      allow(Stripe::Customer).to receive(:create).and_raise(invalid_error)
      post "/stripe_active_cards", params: { stripe_token: stripe_helper.generate_card_token }
      expect(DataDogStatsClient).to have_received(:increment).with("stripe.errors")
    end
  end

  describe "PUT StripeActiveCards#update" do
    it "increments sidekiq.errors in Datadog on failure" do
      valid_instance(user)
      customer = Stripe::Customer.retrieve(user.stripe_id_code)
      original_card_id = customer.sources.all(object: "card").first.id
      allow(DataDogStatsClient).to receive(:increment)
      card_error = Stripe::CardError.new(nil, nil, nil)
      allow(Stripe::Customer).to receive(:retrieve).and_raise(card_error)
      put "/stripe_active_cards/#{original_card_id}", params: {}
      expect(DataDogStatsClient).to have_received(:increment).with("stripe.errors")
    end
  end

  describe "DESTROY StripeActiveCards#destroy" do
    context "when a valid request is made" do
      before do
        valid_instance(user)
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        original_card_id = customer.sources.all(object: "card").first.id
        delete "/stripe_active_cards/#{original_card_id}"
      end

      it "redirects to billing page" do
        expect(response).to redirect_to("/settings/billing")
      end

      it "provides the proper flash notice" do
        expect(flash[:notice]).to eq("Your card has been successfully removed.")
      end

      it "successfully deletes the card" do
        customer = Stripe::Customer.retrieve(user.stripe_id_code)
        expect(customer.sources.all.count).to eq(0)
      end
    end
  end
end
