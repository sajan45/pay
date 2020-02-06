require_relative "pay/version"

module Pay
  class Error < StandardError; end
  
  def self.banner
    "Welcome to Pay! Press CTRL + c to quit, or type help for list of commands."
  end
end
