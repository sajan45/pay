require_relative "../pay"
require_relative "./db"

module Pay
  class Transaction
    attr_reader :user, :merchant, :amount

    def initialize(data_arr)
      raise Error, "User name, merchant name, amount are mandatory" if data_arr.length < 3 # ignoring all other validations like name format
      @user, @merchant, @amount = data_arr
      raise Error, "User does not exists" unless User.exists?(@user)
      raise Error, "Merchant does not exists" unless Merchant.exists?(@merchant)
      @amount = @amount.to_f.round(2)
      raise Error, "Provide an positive integer value for credit limit" if @amount.zero?
    end
  end
end
