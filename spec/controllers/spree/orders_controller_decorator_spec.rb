require 'spec_helper'

describe Spree::OrdersController do

  let(:order) { mock_model(Spree::Order, remaining_total: 1000, state: 'cart') }
  let(:user) { mock_model(Spree::User, store_credits_total: 500) }
  let(:checkout_event) { mock_model(Spree::CheckoutEvent) }

  before(:each) do
    allow(user).to receive(:orders).and_return(Spree::Order.all)
    allow(controller).to receive(:track_activity).and_return(checkout_event)
    allow(controller).to receive(:check_authorization).and_return(true)
    allow(controller).to receive(:current_order).and_return(order)
    allow(controller).to receive(:associate_user).and_return(true)
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(controller).to receive(:current_order).and_return(order)
  end

  describe '#edit' do

    def send_request
      get :edit, id: order.number
    end

    describe 'when return to cart' do

      context 'when return from a checkout step' do
        before(:each) do
          checkout_steps = double('checkout_steps')
          allow(order).to receive(:checkout_steps).and_return(checkout_steps)
          allow(checkout_steps).to receive(:include?).and_return(true)
          request.env['HTTP_REFERER'] = 'test/address'
          send_request
        end

        it 'should create a tracker entry when return from any checkout step' do
          expect(controller.track_activity).to be_instance_of(Spree::CheckoutEvent)
        end
      end

      context 'when a product is added' do
        before(:each) do
          checkout_steps = double('checkout_steps')
          allow(order).to receive(:checkout_steps).and_return(checkout_steps)
          allow(checkout_steps).to receive(:include?).and_return(false)
          request.env['HTTP_REFERER'] = 'test/my_test_product'
          send_request
        end

        it 'should create a tracker entry' do
          expect(controller.track_activity).to be_instance_of(Spree::CheckoutEvent)
        end
      end

      context 'when return to cart from cart itself' do
        before(:each) do
          checkout_steps = double('checkout_steps')
          allow(order).to receive(:checkout_steps).and_return(checkout_steps)
          allow(checkout_steps).to receive(:include?).and_return(true)
          request.env['HTTP_REFERER'] = 'test/cart'
          send_request
        end

        it 'should not create tracker entry' do
          expect(controller).not_to receive(:track_activity)
        end
      end

    end
  end

  describe '#empty' do
    def send_request
      put :empty
    end

    before do
      allow(order).to receive(:empty!)
      request.env['HTTP_REFERER'] = 'test/cart'
      send_request
    end

    it 'should empty the cart and create an tracker record' do
      expect(controller.track_activity).to be_instance_of(Spree::CheckoutEvent)
    end

  end

end