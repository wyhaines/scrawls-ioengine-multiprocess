require 'scrawls/ioengine/multiprocess/version'
require 'scrawls/ioengine/single'
require 'socket'
require 'mime-types'
require 'scrawls/config/task'
require 'scrawls/config/tasklist'

module Scrawls
  module Ioengine
    class Multiprocess < Scrawls::Ioengine::Single

      def initialize(scrawls)
        @scrawls = scrawls
      end

      def run( config = {} )
        server = TCPServer.new( config[:host], config[:port] )

        fork_it( config[:processes] - 1 )

        do_main_loop server
      end

      def fork_it( process_count )
        pid = nil
        process_count.times do
          if pid = fork
            Process.detach( pid )
          else
            break
          end
        end
      end

      def self.parse_command_line(configuration, meta_configuration)
        call_list = SimpleRubyWebServer::Config::TaskList.new

        configuration[:processes] = 1
        meta_configuration[:helptext] << <<-EHELP
--processes COUNT:
  The number of processes to fork. Defaults to 1.

EHELP

        options = OptionParser.new do |opts|
          opts.on( '--processes COUNT' ) do |count|
            call_list << SimpleRubyWebServer::Config::Task.new(9000) { n = Integer( count.to_i ); n = n > 0 ? n : 1; configuration[:processes] = n }
          end
        end

        leftover_argv = []

        begin
          options.parse!(ARGV)
        rescue OptionParser::InvalidOption => e
          e.recover ARGV
          leftover_argv << ARGV.shift
          leftover_argv << ARGV.shift if ARGV.any? && ( ARGV.first[0..0] != '-' )
          retry
        end

        ARGV.replace( leftover_argv ) if leftover_argv.any?

        call_list
      end

    end
  end
end
