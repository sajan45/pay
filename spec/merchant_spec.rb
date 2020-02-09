require_relative '../lib/pay/merchant'
require_relative '../lib/pay/db'
require_relative '../lib/pay/user'

RSpec.describe Pay::Merchant do
  
  before :all do
    Pay::DB.remove_db
  end

  context "creating" do
    it "creates merchant with all required attributes" do
      merchant = Pay::Merchant.new(["m1", "m1@email.com", "0.5%"])
      expect(merchant).to be_kind_of(Pay::Merchant)
      expect(merchant.discount).to eq(0.5)
    end

    it "raises error if discount is not valid" do
      data_arr = ["m3", "m3@email.com", "5"] # invalid discount, it requires '%'
      expect { Pay::Merchant.new(data_arr) }.to raise_error(Pay::Error, "Please input a valid discount percentage. e.g 2.5%")
    end

    it "raises error while creating new merchant if one name is not unique" do
      merchant2 = Pay::Merchant.new(["m2", "m2@email.com", "0.5%"])
      Pay::DB.save_object(merchant2, :merchants, merchant2.name)
      expect{ Pay::Merchant.new(["m2", "m2@email.com", "0.5%"]) }.to raise_error(Pay::Error, "Merchant already exists")
    end

    it "raises error if any data is missing from arguments" do
      data_arr = ["m3", "0.5%"] # invalid discount, it requires '%'
      expect { Pay::Merchant.new(data_arr) }.to raise_error(Pay::Error, "Name, email, discount all are required")
    end
  end

  describe ".update_discount" do
    it "updates discount data if name and discount are provided" do
      merchant = Pay::Merchant.new(["m4", "m4@email.com", "5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      Pay::Merchant.update_discount(["m4", "1%"])
      updated_merchant = Pay::DB.get_object(:merchants, merchant.name)
      expect(updated_merchant.discount).to eq(1)
    end

    it "fails to update if name and new discount not provided" do
      merchant = Pay::Merchant.new(["m5", "m5@email.com", "5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      expect{Pay::Merchant.update_discount(["m5"])}.to raise_error(Pay::Error, "Please provide merchant name and new discount")
    end

    it "raises while trying to update discount of a non existent merchant" do
      expect{Pay::Merchant.update_discount(["non_existent", "1%"])}.to raise_error(Pay::Error, "Merchant does not exists")
    end
  end

  describe ".exists?" do
    it "return true if merchant by provided name exists" do
      merchant = Pay::Merchant.new(["m6", "m6@email.com", "5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      expect(Pay::Merchant.exists?(merchant.name)).to eq(true)
    end

    it "return false if merchant by provided name does not exists" do
      expect(Pay::Merchant.exists?("non_existent")).to eq(false)
    end
  end

  describe ".get_total_discount" do
    it "returns the total discount generated from all transactions for a merchant" do
      merchant = Pay::Merchant.new(["m7", "m7@email.com", "0.5%"])
      user1 = Pay::User.new(["user1", "user1@email.com", "200"])
      user2 = Pay::User.new(["user2", "user2@email.com", "300"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      Pay::DB.save_object(user1, :users, user1.name)
      Pay::DB.save_object(user2, :users, user2.name)
      Pay::User.record_transaction(["user1", "m7", 200])
      Pay::User.record_transaction(["user2", "m7", 200])
      expect(merchant.get_total_discount).to eq(2.0)
    end
  end
end
