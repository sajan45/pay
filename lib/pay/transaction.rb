require_relative "../pay"
require_relative "./db"

module Pay
  class Transaction
    attr_reader :user, :merchant, :merchant_discount, :amount

    def initialize(data_arr)
      raise Error, "User name, merchant name, amount are mandatory" if data_arr.length < 3 # ignoring all other validations like name format
      @user, @merchant, @amount = data_arr
      raise Error, "User does not exists" unless User.exists?(@user)
      merchant_data = Pay::DB.get_object(:merchants, @merchant)
      raise Error, "Merchant does not exists" unless merchant_data
      @amount = @amount.to_f.round(2)
      raise Error, "Provide an positive integer value transaction amount" if @amount <= 0
      @merchant_discount = ((@amount * merchant_data.discount) / 100).round(2)
    end

    def self.all_transactions
      Pay::DB.get_object(:transactions)
    end
  end
end
