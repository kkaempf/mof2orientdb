#
# mof2orientdb/lib/mof2orientdb/options.rb
#
# Extract ARGV options
#

require 'getoptlong'
require 'uri'

module Mof2OrientDB
  class Options
    attr_reader :target, :user, :password, :database

    def initialize

      # Parse command line options
      GetoptLong.new(
        [ '-h', '--help', GetoptLong::NO_ARGUMENT ],
        [ '-H', '--man', GetoptLong::NO_ARGUMENT ],
        [ '-t', '--target', GetoptLong::REQUIRED_ARGUMENT ],
        [ '-u', '--user', GetoptLong::REQUIRED_ARGUMENT ],
        [ '-p', '--pass', '--password', GetoptLong::REQUIRED_ARGUMENT ],
        [ '-d', '--db', '--database', GetoptLong::REQUIRED_ARGUMENT ]
      ).each do |opt, arg|
        puts "#{opt.inspect}: #{arg.inspect}"
        case opt
        when '--target'
          @target = URI.new(arg)
        when '--user'
          @user = arg
        when '-password'
          @password = arg
        when '--database'
          @database = arg
        when '--package'
          self.package = arg
        else
          "Run $0 -h or $0 -H for details on usage";
        end
      end
      unless ARGV.empty?
        abort "Extra arguments: #{ARGV}"
      end
      
      raise "Username missing: --user <name>" unless @user
      raise "Password missing: --pass <name>" unless @user
    end
  
  end
end
