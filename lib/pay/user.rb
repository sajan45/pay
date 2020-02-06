require_relative "../pay"
require_relative "./db"

module Pay
  class User
    attr_reader :name, :email, :cr_limit

    def initialize(data_arr)
      raise Pay::Error, "Name, Email, Credit limit needed" if data_arr.length < 3 # ignoring all other validations like name format
      @name, @email, @cr_limit = data_arr
      @cr_limit = @cr_limit.to_f.round(2)
      existing_users = Pay::DB.get_object(:users) || {}
      raise Pay::Error, "User already exists" if existing_users.keys.include?(@email)
      raise Pay::Error, "Provide an positive integer value for credit limit" if @cr_limit.zero?
    end
  end
end
