#
# mof2orientdb/lib/mof2orientdb/client.rb
#
# OrientDB client
#

require 'orientdb4r'

module Mof2OrientDB
  class Client
    attr_reader :dbclient
    def initialize options = nil
      @options = options
      parms = Hash.new
      if @options.target
        parms[:host] = @options.target.host
        parms[:port] = @options.target.port.to_i
        parms[:ssl] = @options.target.scheme == "https"
      end
      @dbclient = Orientdb4r.client parms
    end
    
    def connect
      @dbclient.connect :database => @options.database, :user => @options.user, :password => @options.password
    end
    
    def disconnect
      @dbclient.disconnect if @dbclient
    end
  end
end
