require_relative "../pay"
require_relative "./db"
require_relative "./user"

module Pay
  class Report
    def self.get_report_for(tokens)
      return nil if tokens.empty?
      report_type = tokens.shift
      case report_type
      when "users-at-credit-limit"
        Pay::User.get_users_at_cr_limit
      when "total-dues"
        Pay::User.get_user_wise_due
      when "dues"
        raise Error, "user name required" if tokens.empty?
        user = Pay::DB.get_object(:users, tokens.shift)
        user.due
      when "discount"
        raise Error, "merchant name required" if tokens.empty?
        merchant = Pay::DB.get_object(:merchants, tokens.shift)
        merchant.get_total_discount
      else
        raise Error, "Unknown report type"
      end
    end
  end
end
