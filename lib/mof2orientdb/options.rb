#
# mof2orientdb/lib/mof2orientdb/options.rb
#
# Extract ARGV options
#

require 'getoptlong'
require 'uri'

module Mof2OrientDB
  class Options
    attr_reader :target, :user, :password, :database, :includes

    def initialize
      @includes = Array.new
      # Parse command line options
      GetoptLong.new(
        [ '-h', '--help', GetoptLong::NO_ARGUMENT ],
        [ '-H', '--man', GetoptLong::NO_ARGUMENT ],
        [ '-t', '--target', GetoptLong::REQUIRED_ARGUMENT ],
        [ '-u', '--user', GetoptLong::REQUIRED_ARGUMENT ],
        [ '-p', '--pass', '--password', GetoptLong::REQUIRED_ARGUMENT ],
        [ '-d', '--db', '--database', GetoptLong::REQUIRED_ARGUMENT ],
        [ '-I', '--include', GetoptLong::REQUIRED_ARGUMENT ]
      ).each do |opt, arg|
        puts "#{opt.inspect}: #{arg.inspect}"
        case opt
        when '-t'
          @target = URI.new(arg)
        when '-u'
          @user = arg
        when '-p'
          @password = arg
        when '-d'
          @database = arg
        when '-I'
          @includes << arg
        else
          "Run $0 -h or $0 -H for details on usage";
        end
      end
      
      abort "Database missing: --db <name>" unless @database
      abort "Username missing: --user <name>" unless @user
      abort "Password missing: --pass <name>" unless @password
    end
  
  end
end
