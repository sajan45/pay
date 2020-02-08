require_relative "../pay"
require_relative "./db"

module Pay
  class User
    attr_reader :name, :email, :cr_limit, :due

    def initialize(data_arr)
      raise Error, "Name, Email, Credit limit needed" if data_arr.length < 3 # ignoring all other validations like name format
      @name, @email, @cr_limit = data_arr
      @due = 0
      @cr_limit = @cr_limit.to_f.round(2)
      existing_users = Pay::DB.get_object(:users) || {}
      raise Error, "User already exists" if existing_users.keys.include?(@name) # assuming name is primary key and unique
      raise Error, "Provide an positive integer value for credit limit" if @cr_limit.zero?
    end

    def self.record_transaction(txn_data)
      txn = Pay::Transaction.new(txn_data)
      user = Pay::DB.get_object(:users, txn.user)
      raise Error, "rejected! (reason: credit limit)" unless user.credit_available_for(txn.amount)
      Pay::DB.save_object(txn, :transactions)
      user.update_balance(txn.amount, :debit)
    end

    def credit_available_for(amount)
      cr_limit >= amount
    end

    def update_balance(amount, type)
      if type == :debit
        updated_cr_limit = cr_limit - amount
        updated_due = due + amount
      elsif type == :credit
        updated_cr_limit = cr_limit + amount
        updated_due = due - amount
      else
        raise Error, "unknown transaction type"
      end
      self.instance_variable_set(:@cr_limit, updated_cr_limit)
      self.instance_variable_set(:@due, updated_due)
      Pay::DB.save_object(self, :users, name)
    end

    def self.exists?(user_name)
      user = Pay::DB.get_object(:users, user_name)
      !!user
    end
  end
end
