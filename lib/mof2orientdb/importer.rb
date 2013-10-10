#
# mof2orientdb/lib/mof2orientdb/importer.rb
#
# Importer of MOF files/directories into OrientDB
#
module Mof2OrientDB
  class Importer
  private
    # try to access inc/name
    # return triple of [ path, directory?, readable? ]
    def try_path inc, name
      path = File.join(inc, name)
      STDERR.puts "Trying #{path}"
      [ path, File.directory? name, File.readable?(path) ]
    end
  public
    def initialize name, includes = []
      path = nil
      is_dir = false
      # loop through include dirs, including current dir
      includes.unshift(".").each do |inc|
        # test <name>, <name>.mof, CIM_<name>.mof
        # if <name> is a directory, recursively import it
        incdir = File.expand_path(inc)
        path, is_dir, is_readable = try_path inc, name
        break if is_dir || is_readable
        path, is_dir, is_readable = try_path inc, "#{name}.mof"
        break if is_readable
        path, is_dir, is_readable = try_path inc, "CIM_#{name}.mof"
        break if is_readable
      end
      if is_dir
      elsif is_readable
      else
        raise "No such file or directory"
      end
    end # initialize
  end
end