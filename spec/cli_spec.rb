require_relative "../lib/pay/cli"

RSpec.describe Pay::CLI do
  
  before :each do
    Pay::DB.remove_db
  end
  
  before :all do
    @cli = Pay::CLI.new
  end

  # supressing puts outputs in testing mode
  before :all do
    $original_stderr = $stderr
    $original_stdout = $stdout
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end

  after :all do
    $stderr = $original_stderr
    $stdout = $original_stdout
  end

  describe ".handle_new" do
    it "creates new user when resource type is user and all data are available" do
      @cli.handle_new(["user", "user1", "u1@users.com", "300"])
      all_users = Pay::User.all_users
      expect(all_users.keys.include?("user1")).to eq(true)
      expect(all_users.length).to eq(1)
      expect(all_users["user1"].cr_limit).to eq(300)
    end

    it "creates new merchant when resource type is merchant and all data are available" do
      @cli.handle_new(["merchant", "m1", "m1@example.com", "0.5%"])
      all_merchants = Pay::DB.get_object(:merchants)
      expect(all_merchants.keys.include?("m1")).to eq(true)
      expect(all_merchants.length).to eq(1)
      expect(all_merchants["m1"].discount).to eq(0.5)
    end

    it "creates new transaction if resource type is txn and all data are available" do
      @cli.handle_new(["user", "user1", "u1@users.com", "300"]) # user is necessary for txn
      @cli.handle_new(["merchant", "m1", "m1@example.com", "0.5%"]) # merchant is necessary for txn
      @cli.handle_new(["txn", "user1", "m1", "200"])
      all_transactions = Pay::DB.get_object(:transactions)
      expect(all_transactions.length).to eq(1)
      expect(all_transactions[0].user).to eq("user1")
      expect(all_transactions[0].merchant).to eq("m1")
    end
  end

  describe ".handle_update" do
    it "updates merchant discount when merchant name and new discount provided" do
      merchant = Pay::Merchant.new(["m4", "m4@email.com", "5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      @cli.handle_update(["merchant", "m4", "1%"])
      mechant_record = Pay::DB.get_object(:merchants, "m4")
      expect(mechant_record.discount).to eq(1)
    end
  end

  describe ".handle_payback" do
    it "creates a payment record for user" do
      merchant = Pay::Merchant.new(["m4", "m4@email.com", "5%"])
      Pay::DB.save_object(merchant, :merchants, merchant.name)
      user = Pay::User.new(["u1", "u1@email.com", "100"])
      Pay::DB.save_object(user, :users, user.name)
      Pay::User.record_transaction(["u1", "m4", 100])
      @cli.handle_payback(["u1", "100"])
      all_payments = Pay::DB.get_object(:paybacks)
      expect(all_payments.length).to eq(1)
      expect(all_payments[0].user).to eq("u1")
      expect(all_payments[0].amount).to eq(100)
    end
  end
end
