require_relative '../lib/pay/merchant'
require_relative '../lib/pay/db'
require_relative '../lib/pay/user'
require_relative '../lib/pay/transaction'
require_relative '../lib/pay/report'

RSpec.describe Pay::Report do
  
  before :each do
    Pay::DB.remove_db
  end

  describe '.get_report_for' do
    it "returns nil if no arguments provided" do
      expect(Pay::Report.get_report_for([])).to eq(nil)
    end

    it "returns array of users at credit limit when type is users-at-credit-limit" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"]).save

      user1 = Pay::User.new(["u1", "u1@email.com", "100"]).save
      user2 = Pay::User.new(["u2", "u2@email.com", "200"]).save
      user3 = Pay::User.new(["u3", "u3@email.com", "300"]).save
      Pay::User.record_transaction(["u1", "m3", 100])
      Pay::User.record_transaction(["u2", "m3", 200])
      Pay::User.record_transaction(["u3", "m3", 100])
      expect(Pay::Report.get_report_for(["users-at-credit-limit"])).to eq(["u1", "u2"])
    end

    it "returns dues for all users with a due along with total due for report type total-dues" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"]).save

      user1 = Pay::User.new(["u1", "u1@email.com", "100"]).save
      user2 = Pay::User.new(["u2", "u2@email.com", "200"]).save
      user3 = Pay::User.new(["u3", "u3@email.com", "300"]).save
      Pay::User.record_transaction(["u1", "m3", 100])
      Pay::User.record_transaction(["u2", "m3", 200])
      total_dues = Pay::Report.get_report_for(["total-dues"])
      expect(total_dues.length).to eq(3) # 2 users with due and 1 total value
      expect(total_dues["u1"]).to eq(100)
      expect(total_dues["u2"]).to eq(200)
      expect(total_dues["total"]).to eq(300)
    end

    it "return discount of a merchant if report type is discount" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"]).save
      user1 = Pay::User.new(["u1", "u1@email.com", "200"]).save
      Pay::User.record_transaction(["u1", "m3", 200])
      expect(Pay::Report.get_report_for(["discount", "m3"])).to eq(1.0)
    end

    it "raises error if merchant name not available for a discount report" do
      expect{ Pay::Report.get_report_for(["discount"]) }.to raise_error(Pay::Error, "merchant name required")
    end

    it "return dues of a user if report type is dues" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"]).save
      user1 = Pay::User.new(["u1", "u1@email.com", "100"]).save
      Pay::User.record_transaction(["u1", "m3", 100])
      expect(Pay::Report.get_report_for(["dues", "u1"])).to eq(100.0)
    end

    it "raises error if user name not available for a dues report" do
      expect{ Pay::Report.get_report_for(["dues"]) }.to raise_error(Pay::Error, "user name required")
    end
    it "raises error if report type is not known" do
      expect{ Pay::Report.get_report_for(["unknown"]) }.to raise_error(Pay::Error, "Unknown report type")
    end
  end
end
