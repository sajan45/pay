require_relative '../pay'
require 'readline'

module Pay
  class CLI
    def self.start
      puts Pay.banner
      stty_save = `stty -g`.chomp
      begin
        while buf = Readline.readline('> ')
          p buf
        end
      rescue Interrupt
        system("stty", stty_save)
        exit 0
      end
    end
  end
end
