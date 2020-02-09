require_relative "../lib/pay/user"

RSpec.describe Pay::User do
  
  before :each do
    Pay::DB.remove_db
  end

  context "creating" do
    it "creates user when all required data available" do
      user = Pay::User.new(["u1", "u1@email.com", "300"])
      expect(user).to be_kind_of(Pay::User)
    end

    it "sets new users due to zero by default" do
      user = Pay::User.new(["u1", "u1@email.com", "300"])
      expect(user.due).to eq(0)
    end

    it "raises error when any required data is missing" do
      expect{ Pay::User.new(["u1", "u1@email.com"]) }.to raise_error(Pay::Error, "Name, Email, Credit limit needed")
    end

    it "raises error when name is not unique" do
      user = Pay::User.new(["u1", "u1@email.com", "300"])
      user.save
      expect{ Pay::User.new(["u1", "u2@email.com", "400"]) }.to raise_error(Pay::Error, "User already exists")
    end

    it "raises error when credit limit is not valid" do
      expect{ Pay::User.new(["u2", "u2@email.com", "0"]) }.to raise_error(Pay::Error, "Provide an positive integer value for credit limit")
      expect{ Pay::User.new(["u2", "u2@email.com", "str"]) }.to raise_error(Pay::Error, "Provide an positive integer value for credit limit")
      expect{ Pay::User.new(["u2", "u2@email.com", "-1"]) }.to raise_error(Pay::Error, "Provide an positive integer value for credit limit")
    end
  end

  describe ".record_transaction" do
    before :each do
      @merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      @merchant.save
      @user = Pay::User.new(["u3", "u3@email.com", "500"])
      @user.save
    end
    it "creates a new transaction if credit limit is available" do
      Pay::User.record_transaction([@user.name, @merchant.name, "200.50"])
      all_transactions = Pay::DB.get_object(:transactions)
      expect(all_transactions.length).to eq(1)
      expect(all_transactions[0].user).to eq(@user.name)
    end

    it "rejects transaction if credit limit has reached" do
      Pay::User.record_transaction([@user.name, @merchant.name, "500"])
      expect{ Pay::User.record_transaction([@user.name, @merchant.name, "10"])}.to raise_error(Pay::Error, "rejected! (reason: credit limit)")
    end

    it "updates reduces credit limit and increases due" do
      Pay::User.record_transaction([@user.name, @merchant.name, "150"])
      user = Pay::DB.get_object(:users, @user.name)
      expect(user.cr_limit).to eq(350.0)
      expect(user.due).to eq(150.0)
    end
  end

  describe ".credit_available_for" do
    it "returns true if credit limit is available for desired amount" do
      @merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      @merchant.save
      @user = Pay::User.new(["u3", "u3@email.com", "500"])
      @user.save
      Pay::User.record_transaction([@user.name, @merchant.name, "150"])
      updated_user = Pay::DB.get_object(:users, @user.name)
      expect(updated_user.credit_available_for(350)).to eq(true)
      expect(updated_user.credit_available_for(400)).to eq(false)
    end
  end

  describe ".update_balance" do
    it "reduces users credit limit and increases due if type is debit" do
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      user.update_balance(200, :debit)
      expect(user.cr_limit).to eq(300)
      expect(user.due).to eq(200)
    end

    it "increases users credit limit and reduces due if type is credit" do
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      user.update_balance(200, :debit)
      expect(user.cr_limit).to eq(300)
      expect(user.due).to eq(200)

      user.update_balance(100, :credit)
      expect(user.cr_limit).to eq(400)
      expect(user.due).to eq(100)
    end

    it "raises error if type is not known" do
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      expect{ user.update_balance(200, :interest) }.to raise_error(Pay::Error, "unknown transaction type")
    end

    it "saves the updated value to db after balance update" do
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      user.update_balance(200, :debit)
      updated_user = Pay::DB.get_object(:users, "u3")
      expect(updated_user.cr_limit).to eq(300)
      expect(updated_user.due).to eq(200)
    end
  end

  describe ".exists?" do
    it "return true if user by provided name exists" do
      user = Pay::User.new(["u3", "u3@email.com", "500"])
      user.save
      expect(Pay::User.exists?(user.name)).to eq(true)
    end

    it "return false if user by provided name does not exists" do
      expect(Pay::User.exists?("non_existent")).to eq(false)
    end
  end

  describe ".get_users_at_cr_limit" do

    it "returns an array of user names who have reached credit limit" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      merchant.save
      user3 = Pay::User.new(["u3", "u3@email.com", "500"]).save
      user2 = Pay::User.new(["u2", "u2@email.com", "200"]).save
      user1 = Pay::User.new(["u1", "u1@email.com", "100"]).save
      Pay::User.record_transaction([user3.name, merchant.name, "200.50"])
      Pay::User.record_transaction([user2.name, merchant.name, "200"])
      Pay::User.record_transaction([user1.name, merchant.name, "100"])

      expect(Pay::User.get_users_at_cr_limit).to eq(["u2", "u1"])
    end
  end

  describe ".get_user_wise_due" do
    it "returns an hash of users and and their dues if its more than 0" do
      merchant = Pay::Merchant.new(["m3", "m3@email.com", "0.5%"])
      merchant.save
      user1 = Pay::User.new(["u1", "u1@email.com", "100"]).save
      user2 = Pay::User.new(["u2", "u2@email.com", "200"]).save
      user3 = Pay::User.new(["u3", "u3@email.com", "300"]).save
      Pay::User.record_transaction(["u1", "m3", 100])
      Pay::User.record_transaction(["u2", "m3", 200])
      due_data = Pay::User.get_user_wise_due
      expect(due_data).to be_kind_of(Hash)
      expect(due_data["u1"]).to eq(100.0)
      expect(due_data["u2"]).to eq(200.0)
    end
  end

  describe ".all_users" do
    it "returns all users hash" do
      user3 = Pay::User.new(["u3", "u3@email.com", "500"]).save
      user2 = Pay::User.new(["u2", "u2@email.com", "200"]).save
      user1 = Pay::User.new(["u1", "u1@email.com", "100"]).save
      all_users = Pay::User.all_users

      expect(all_users.length).to eq(3)
      expect(all_users["u3"]).to be_kind_of(Pay::User)
      expect(all_users["u3"].name).to eq("u3")
    end
  end

  describe ".save" do
    it "saves the object to DB" do
      user = Pay::User.new(["u1", "u1@email.com", "100"]).save
      all_users = Pay::User.all_users
      expect(all_users.length).to eq(1)
      expect(all_users.keys.include?("u1")).to eq(true)
    end
  end
end
