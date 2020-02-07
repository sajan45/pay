require_relative '../pay'
require_relative './db'
require_relative './user'
require_relative './merchant'
require_relative './report'
require_relative './transaction'
require 'readline'

module Pay
  class CLI
    def start
      at_exit { Pay::DB.remove_db }
      puts Pay.banner
      stty_save = `stty -g`.chomp
      begin
        while buf = Readline.readline('> ')
          parse(buf)
        end
      rescue Pay::Error => e
        puts e.message
        retry
      rescue Interrupt
        system("stty", stty_save)
        exit 0
      end
    end

    def parse(input_string)
      command = {}
      tokens = input_string.split(" ")
      action = tokens.shift
      # if such type of commands grow in number, we can use dynamic invocation of methods to
      # cut down this type of duplicate code
      case action
      when "new"
        handle_new(tokens)
      when "update"
        handle_update(tokens)
      when "report"
        handle_report(tokens)
      when "payback"
        handle_payback(tokens)
      when "help"
        print_help
      else
        puts "Unknown command: #{action}"
        print_help
      end
    end

    def handle_new(tokens)
      if tokens.empty?
        puts "Resource type is needed for new action"
        puts "Ex. new user u1 u1@email.in 1000"
        return
      end
      resource_type = tokens.shift
      case resource_type
      when "user"
        user = Pay::User.new(tokens)
        Pay::DB.save_object(user, :users, user.name)
        puts "#{user.name}(#{user.cr_limit})"
      when "merchant"
        merchant = Pay::Merchant.new(tokens)
        Pay::DB.save_object(merchant, :merchants, merchant.name)
        puts "#{merchant.name}(#{merchant.discount}%)"
      when "txn"
        Pay::User.record_transaction(tokens)
      else
        puts "Unknown resource type: #{resource_type}"
      end
    end

    def handle_update(tokens)
      if tokens.empty?
        puts "Resource type is needed for update action"
        puts "Ex. update merchant m1 1%"
        return
      end
      resource_type = tokens.shift
      case resource_type
      when "merchant"
        Pay::Merchant.update_discount(tokens)
        puts "Merchant discount updated"
      else
        puts "Unknown resource type: #{resource_type}"
      end
    end

    def handle_report(tokens)
      if tokens.empty?
        puts "Report action needs at lease 1 argument"
        puts "Ex. report discount m1"
        puts "    report users-at-credit-limit"
        puts "    report total-dues"
        puts "    report dues u1"
        return
      end
      Pay::Report.get_report_for(tokens)
    end

    def handle_payback(tokens)
      if tokens.empty?
        puts "User name is needed for payback"
        puts "Ex. payback u1 300"
        return
      end
      Pay::Transaction.record_payback(tokens)
    end

    def print_help
      message = <<-HELP
Supported actions are 'new, update, report, payback'.
Ex. new user u1 u1@email.in 1000
    new merchant m1 m1@merchants.com 0.5%
    new txn u1 m2 400

    update merchant m1 1%

    report discount m1
    report total-dues

    payback u1 300
HELP
    puts message
    end
  end
end
