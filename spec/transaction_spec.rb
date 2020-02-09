require_relative '../lib/pay/merchant'
require_relative '../lib/pay/db'
require_relative '../lib/pay/user'
require_relative '../lib/pay/transaction'

RSpec.describe Pay::Transaction do
  
  before :each do
    Pay::DB.remove_db
  end

  context "creating" do
    it "creates transaction with all required data" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      Pay::DB.save_object(user, :users, user.name)
      txn = Pay::Transaction.new(["u3", "m3", "200.50"])
      expect(txn).to be_kind_of(Pay::Transaction)
    end

    it "raises error if any of the required data is missing" do
      expect{ Pay::Transaction.new(["u3", "m3"]) }.to raise_error(Pay::Error, "User name, merchant name, amount are mandatory")
    end

    it "raises error if user does not exists" do
      expect{ Pay::Transaction.new(["non_existent", "m3", "200"]) }.to raise_error(Pay::Error, "User does not exists")
    end

    it "raises error if merchant does not exists" do
      user = Pay::User.new(["u2", "u2@email.com", "500"])
      Pay::DB.save_object(user, :users, user.name)
      expect{ Pay::Transaction.new(["u2", "non_existent", "200"]) }.to raise_error(Pay::Error, "Merchant does not exists")
    end

    it "raises error if transaction amount is not valid" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      Pay::DB.save_object(user, :users, user.name)

      expect{ Pay::Transaction.new(["u3", "m3", "0"]) }.to raise_error(Pay::Error, "Provide an positive integer value transaction amount")
      expect{ Pay::Transaction.new(["u3", "m3", "str"]) }.to raise_error(Pay::Error, "Provide an positive integer value transaction amount")
      expect{ Pay::Transaction.new(["u3", "m3", "-1"]) }.to raise_error(Pay::Error, "Provide an positive integer value transaction amount")
    end
  end

  describe ".all_transactions" do
    it "returns all transactions from db" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      Pay::DB.save_object(user, :users, user.name)
      user1 = Pay::User.new(["u1", "u1@email.com", "500"])
      Pay::DB.save_object(user1, :users, user1.name)

      Pay::User.record_transaction(["u3", "m3", 100])
      Pay::User.record_transaction(["u1", "m3", 100])
      txns = Pay::Transaction.all_transactions
      expect(txns.length).to eq(2)
      expect(txns.map(&:class).uniq[0]).to eq(Pay::Transaction) # all objects are of Transaction type
      expect(txns[0].user).to eq("u3")
    end
  end
end