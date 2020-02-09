require_relative '../lib/pay/db'
require_relative '../lib/pay/user'
require_relative '../lib/pay/merchant'
require_relative '../lib/pay/payment'

RSpec.describe Pay::Payment do
  
  before :each do
    Pay::DB.remove_db
  end

  context "creating" do
    it "creates payment with all required attributes" do
      merchant = Pay::Merchant.new(["m2", "m2@email.com", "0.5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      user = Pay::User.new(["u1", "u1@email.com", "500"])
      Pay::DB.save_object(user, :users, user.name)
      Pay::User.record_transaction(["u1", "m2", 100])
      payback = Pay::Payment.new(["u1", "50"])
      expect(payback).to be_kind_of(Pay::Payment)
    end

    it "raises error if any of user name and amount is missing" do
      expect{Pay::Payment.new(["u1"])}.to raise_error(Pay::Error, "User name, amount are mandatory")
    end

    it "raises error if user does not exists" do
      expect{Pay::Payment.new(["non_existent", "50"])}.to raise_error(Pay::Error, "User does not exists")
    end

    it "raises error if payment amount is not float like or zero" do
      user = Pay::User.new(["u2", "u2@email.com", "500"])
      Pay::DB.save_object(user, :users, user.name)
      expect{Pay::Payment.new(["u2", "str"])}.to raise_error(Pay::Error, "Provide an positive integer value for payment amount")
      expect{Pay::Payment.new(["u2", "str"])}.to raise_error(Pay::Error, "Provide an positive integer value for payment amount")
      expect{Pay::Payment.new(["u2", "-1"])}.to raise_error(Pay::Error, "Provide an positive integer value for payment amount")
    end

    it "raises error if payment amount exceeds user's due" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      Pay::DB.save_object(user, :users, user.name)
      Pay::User.record_transaction(["u3", "m3", 100])
      expect{Pay::Payment.new(["u3", "105"])}.to raise_error(Pay::Error, /Please enter a amount less than or equal to current due/)
    end
  end

  describe ".record_payback" do
    it "creates a payment with proper data" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      Pay::DB.save_object(user, :users, user.name)
      Pay::User.record_transaction(["u3", "m3", 100])
      Pay::Payment.record_payback(["u3", 50])
      payments = Pay::DB.get_object(:paybacks)
      expect(payments.length).to eq(1)
      expect(payments[0].user).to eq("u3")
    end

    it "passes data and updates users credit limit and due" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      Pay::DB.save_object(user, :users, user.name)
      Pay::User.record_transaction(["u3", "m3", 100])
      
      Pay::Payment.record_payback(["u3", 50])
      user = Pay::DB.get_object(:users, "u3")

      expect(user.cr_limit).to eq(450.0)
      expect(user.due).to eq(50.0)

      Pay::Payment.record_payback(["u3", 50])
      user = Pay::DB.get_object(:users, "u3")
      expect(user.cr_limit).to eq(500.0)
      expect(user.due).to eq(0.0)
    end
  end
end
