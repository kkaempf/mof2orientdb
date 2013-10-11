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
    # try to access inc/name
    # return triple of [ path, directory?, readable? ]
    def try_path inc, name
      path = File.join(inc, name)
      res = [ path, File.directory?(path), File.readable?(path) ]
#      puts "Try #{res}"
      res
    end
    #
    # expand name by
    # - cycling through includes
    # - append .mof
    # - prepend CIM_
    #
    def expand name, scheme = nil
      path, is_dir, is_readable = try_path "", name
      unless is_dir || is_readable
        # loop through include dirs, including current dir
        @includes.unshift(".").each do |inc|
          # test <name>, <name>.mof, CIM_<name>.mof
          # if <name> is a directory, recursively import it
          incdir = File.expand_path(inc)
          path, is_dir, is_readable = try_path inc, name
          break if is_dir || is_readable
          if scheme
            path, is_dir, is_readable = try_path inc, File.join(scheme,name)
            break if is_dir || is_readable
          end
          unless name =~ /^.*\.mof$/
            path, is_dir, is_readable = try_path inc, "#{name}.mof"
            break if is_readable
            if scheme
              path, is_dir, is_readable = try_path inc, File.join(scheme,"#{name}.mof")
              break if is_readable
            end
          end
          unless name =~ /^(CIM_.*|.*\/.*)$/
            path, is_dir, is_readable = try_path inc, "CIM_#{name}.mof"
            break if is_readable
            if scheme
              path, is_dir, is_readable = try_path inc, File.join(scheme,"CIM_#{name}.mof")
              break if is_readable
            end
          end
        end
      end
#      puts "dir? #{is_dir}, readable? #{is_readable} : #{path}"
      if is_dir
        puts "Importing directory #{path}"
        Dir.foreach(path) do |filename|
          next if filename[0,1] == "."
          yield File.join(path, filename)
        end
      elsif is_readable
        yield path
      else
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
