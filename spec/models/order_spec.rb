require 'rails_helper'

describe Order, type: :model do
  describe "validations" do
    it { should validate_presence_of :name }
    it { should validate_presence_of :address }
    it { should validate_presence_of :city }
    it { should validate_presence_of :state }
    it { should validate_presence_of :zip }
    it { should validate_presence_of :current_status }
  end

  describe "relationships" do
    it {should have_many :item_orders}
    it {should have_many(:items).through(:item_orders)}
    it { should belong_to :user }
    it {should belong_to(:coupon).optional}
  end

  describe 'instance methods' do
    before :each do
      user = create(:random_user)

      @meg = Merchant.create(name: "Meg's Bike Shop", address: '123 Bike Rd.', city: 'Denver', state: 'CO', zip: 80203)
      @brian = Merchant.create(name: "Brian's Dog Shop", address: '125 Doggo St.', city: 'Denver', state: 'CO', zip: 80210)

      @tire = @meg.items.create(name: "Gatorskins", description: "They'll never pop!", price: 100, image: "https://www.rei.com/media/4e1f5b05-27ef-4267-bb9a-14e35935f218?size=784x588", inventory: 12)
      @pull_toy = @brian.items.create(name: "Pull Toy", description: "Great pull toy!", price: 10, image: "http://lovencaretoys.com/image/cache/dog/tug-toy-dog-pull-9010_2-800x800.jpg", inventory: 32)

      @order_1 = user.orders.create!(name: 'Meg', address: '123 Stang Ave', city: 'Hershey', state: 'PA', zip: 17033)

      @tire_item_order = @order_1.item_orders.create!(item: @tire, price: @tire.price, quantity: 2, status: 1)
      @pt_item_order = @order_1.item_orders.create!(item: @pull_toy, price: @pull_toy.price, quantity: 3, status: 1)
    end

    it 'grandtotal' do
      expect(@order_1.grandtotal).to eq(230)
    end

    it "change_current_status_to_cancelled" do
      expect(@order_1.current_status).to eq("pending")

      @order_1.cancel

      expect(@order_1.current_status).to eq("cancelled")
    end

    it "changes all item orders to unfulfilled" do
      expect(@tire_item_order.fulfilled?).to be_truthy
      expect(@pt_item_order.fulfilled?).to be_truthy

      @order_1.cancel

      expect(@order_1.item_orders[0].unfulfilled?).to be_truthy
      expect(@order_1.item_orders[1].unfulfilled?).to be_truthy
    end

    it ".ship" do
      @order_1.fulfill

      expect(@order_1.current_status).to eq("packaged")

      @order_1.ship

      expect(@order_1.current_status).to eq("shipped")
    end

    it ".apply_coupon" do
      merchant = create(:random_merchant)
      user = create(:random_user)
      coupon_1 = Coupon.create(name: "20% Off",
                               code: "1234",
                               percentage: 20,
                               merchant_id: merchant.id)
      order = create(:random_order, user_id: user.id)

      order.apply_coupon(coupon_1.id)

      expect(order.coupon_id).to eq(coupon_1.id)
    end
  end
end
