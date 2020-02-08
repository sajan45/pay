require_relative "../pay"
require_relative "./db"

module Pay
  class Payment
    attr_reader :user, :amount

    def initialize(data_arr)
      raise Error, "User name, amount are mandatory" if data_arr.length < 2 # ignoring all other validations like name format
      @user, @amount = data_arr
      user_data = Pay::DB.get_object(:users, @user)
      raise Error, "User does not exists" unless user_data
      @amount = @amount.to_f.round(2)
      raise Error, "Provide an positive integer value for credit limit" if @amount.zero?
      raise Error, "Please enter a amount less than or equal to current due #{user_data.due}" if user_data.due < @amount
    end

    def self.record_payback(tokens)
      pay_record = self.new(tokens)
      user = Pay::DB.get_object(:users, pay_record.user)
      Pay::DB.save_object(pay_record, :paybacks)
      user.update_balance(pay_record.amount, :credit)
      pay_record
    end
  end
end
