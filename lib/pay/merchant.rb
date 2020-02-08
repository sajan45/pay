require_relative "../pay"
require_relative "./db"
require_relative "./transaction"

module Pay
  class Merchant
    attr_reader :name, :email, :discount

    def initialize(data_arr, new_obj=true)
      raise Error, "Name, email, discount all are required" if data_arr.length < 3 # ignoring all other validations like name format
      @name, @email, @discount = data_arr
      if @discount.match? (/\d+(\.\d{1,2})?%/) # a basic regex for decimal percent matching
        @discount = @discount[0..-1].to_f
      else
        raise Error, "Please input a valid discount percentage. e.g 2.5%"
      end
      if new_obj
        existing_merchants = Pay::DB.get_object(:merchants) || {}
        raise Error, "Merchant already exists" if existing_merchants.keys.include?(@name)# assuming name is primary key and unique
      end
    end

    def get_total_discount
      total_transactions = 0.0
      all_txns = Pay::Transaction.all_transactions
      all_txns.each do |txn|
        total_transactions += txn.amount if txn.merchant == self.name
      end
      return ((total_transactions * discount) / 100).round(2)
    end

    def self.update_discount(data)
      if data.length == 2
        merchant = Pay::DB.get_object(:merchants, data[0])
        raise Error, "Merchant does not exists" unless merchant
        updated_merchant = self.new([data[0], merchant.email, data[1]], false)
        Pay::DB.save_object(updated_merchant, :merchants, updated_merchant.name)
      else
        raise Error, "Please provide merchant name and new discount"
      end
    end

    def self.exists?(merchant_name)
      merchant = Pay::DB.get_object(:merchants, merchant_name)
      !!merchant
    end
  end
end
