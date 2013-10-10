#
# mof2orientdb/lib/mof2orientdb/client.rb
#
# OrientDB client
#

require 'orientdb4r'

module Mof2OrientDB
  class Client

    def initialize options = nil
      @options = options
      parms = Hash.new
      if @options.target
        parms[:host] = @options.target.host
        parms[:port] = @options.target.port.to_i
        parms[:ssl] = @options.target.scheme == "https"
      end
      @client = Orientdb4r.client parms
    end
    
    def connect
      @client.connect :database => @options.database, :user => @options.user, :password => @options.password
    end
    
    def disconnect
      @client.disconnect if @client
    end
  end
end
