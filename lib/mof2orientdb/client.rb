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
      host = options.uri.host
      port = options.uri.port.to_i
      ssl = options.uri.scheme == "https"
      parms = Hash.new
      parms[:host] = host if host
      parms[:port] = port if port
      parms[:ssl] = ssl if ssl
      @client = Orientdb4r.client parms
    end
    
    def connect
      @client.connect :database => @options.database, :user => @options.user, :password => @options.password
    end
    
    def disconnect
      @client.disconnect
    end
  end
end
