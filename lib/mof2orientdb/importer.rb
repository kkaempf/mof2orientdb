#
# mof2orientdb/lib/mof2orientdb/importer.rb
#
# Importer of MOF files/directories into OrientDB
#

require 'cim'
require 'mof'

module Mof2OrientDB
  class Importer
    QUALIFIERS = "/usr/share/mof/cim-current/qualifiers.mof"
    BASECLASS = "CIMClass"
    @@classes = {}
  private
    def try inc, name
      @result = nil
      @path = File.join(inc, name)
      puts "try (#{inc.inspect},#{name.inspect}): #{@path}"
      @result = if File.directory?(@path)
                  :dir 
                elsif File.readable?(@path)
                  :file
                else
                  nil
                end
    end
    #
    # expand name by
    # - cycling through includes
    # - append .mof
    # - prepend CIM_
    #
    def expand name, scheme = nil
      @path = nil
      @result = nil
      unless try "", name # name is not a reachable path
        # loop through include dirs, including current dir
        @includes.unshift(".").each do |inc|
          # test <name>, <name>.mof, CIM_<name>.mof
          # if <name> is a directory, recursively import it
          incdir = File.expand_path(inc)
          break if try inc, name
          break if scheme && try(inc, File.join(scheme,name))
          unless name =~ /^.*\.mof$/
            break if try inc, "#{name}.mof"
            break if scheme && try(inc, File.join(scheme,"#{name}.mof"))
          end
          unless name =~ /^(CIM_.*|.*\/.*)$/
            break if try inc, "CIM_#{name}.mof"
            break if scheme && try(inc, File.join(scheme,"CIM_#{name}.mof"))
          end
        end
      end
      puts "#{@path.inspect} -> #{@result.inspect}"
      case @result
      when :dir
        puts "Importing directory #{@path}"
        Dir.foreach(@path) do |filename|
          next if filename[0,1] == "."
          yield File.join(@path, filename)
        end
      when :file
        yield @path
      else
        STDERR.puts "Can't find MOF at #{name}"
        raise Errno::ENOENT
      end
    end

  public
    def initialize client, name, includes = [], scheme = nil
      @client = client
      @includes = includes
      @scheme = scheme
      expand(name, scheme) do |filename|
        import_file filename
      end
          
      @@classes.each_value { |c| import_class(c, scheme) }
      begin
        client.get_class "Superclass"
      rescue
        client.create_class "Superclass", :extends => "E"
      end
      @edges = []
      @vertexes.each do |name,vertex|        
        puts "Vertex #{name} : #{vertex.inspect}"
        sc = vertex['superclass']
        unless sc.empty?
          sql = "CREATE EDGE Superclass FROM (SELECT FROM #{BASECLASS} WHERE name = '#{vertex['name']}') TO (SELECT FROM #{BASECLASS} WHERE name = '#{sc}')"
          begin
            entries = @client.command sql
            puts "Edge: #{entries['result']}"
            @edges << entries['result'][0]
          rescue Exception => e
            puts "SQL #{sql.inspect}"
            puts "Failed with #{e}"
          end
        end
      end
      puts "#{@vertexes.size} vertexes, #{@edges.size} edges"
    end # initialize

    def import_file filename, scheme = nil, client = nil
      client ||= @client
      parser = MOF::Parser.new :style => :cim, :includes => @includes, :quiet => true
      result = parser.parse [ QUALIFIERS, filename ]
      result.each_value do |res|      # key: filename, value: result
        res.classes.each do |klass|
          @@classes[klass.name] = klass
        end
      end
    end
    #
    # Import CIM class to OrientDB
    # Map to OrientDB classes, model superclass as derived OrientDB class
    # CIM_Class -> CIM_Schema(schema) -> CIM_xxx
    #
    def import_class klass, scheme = nil, client = nil
      @vertexes ||= {}
      @scheme ||= scheme
      client ||= @client
      if klass.is_a? String
        name = klass
        klass = @@classes[name] 
        raise "Unknown class #{name}" unless klass
      end
      name = klass.name
      begin
        client.get_class BASECLASS
      rescue
        client.create_class BASECLASS, :extends => "V", :properties => [
          { :property => "name", :type => :string, :notnull => true, :mandatory => true },
          { :property => "scheme", :type => :string },
          { :property => "superclass", :type => :string }
        ]
      end
      vertex = @vertexes[name]
#      puts "Vertex? #{name}: #{vertex.inspect}"
      unless vertex
        vertex = client.get_vertex BASECLASS, { :name => name } rescue nil
#        puts "Vertex? #{BASECLASS}: #{vertex.inspect}"
        if vertex.empty?
          vertex = client.create_vertex BASECLASS, { :name => name, :scheme => scheme, :superclass => klass.superclass }
#          puts "Vertex! #{BASECLASS}:{name}: #{vertex.inspect}"
        end
        @vertexes[name] = vertex[0]
      end
      vertex
    end
  end
end
