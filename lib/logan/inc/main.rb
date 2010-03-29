
require 'sbdb'
require 'safebox'
require 'robustserver'
require 'socket'
require 'logan/inc'
require 'logan/loglines'
require 'logan/cache'

module LogAn::Inc
	class Main < RobustServer
		# Open Config.
		def config env, db, type = nil, flags = nil, &e
			$stderr.puts "Open Database \"sids.cnf\" #{db.inspect} (#{type.inspect})"
			type ||= 1+4
			ret = env[ 'sids.cnf', db, :flags => flags || SBDB::RDONLY]
			ret = LogAn::AutoValueConvertHash.new ret, &e  if type&4 > 0 or e
			ret = LogAn::Cache.new ret, type&3  if type&3 > 0
			ret
		end

		# Prepare Server.
		#
		# * conf:
		#    logs
		#    : Where to store log-databases? default: ./logs
		#    etc
		#    : Where to find config-databases? default: ./etc
		#    server
		#    : Server-Configuration. default { port: 1087 }
		def initialize conf
			super
			@conf = {}

			# Copy config - changes possible
			conf.each {|key, val| @conf[key]= val }

			# Default directories
			%w[logs etc].each {|key| @conf[key.to_sym] = key }

			# Open Loglines-databases
			@logs = LogAn::Loglines.new @conf[:logs]

			# Open config-databases
			Dir.mkdir @conf[:etc]  rescue Errno::EEXIST
			@etc = SBDB::Env.new( @conf[:etc],
					log_config: SBDB::Env::LOG_IN_MEMORY | SBDB::Env::LOG_AUTO_REMOVE,
					flags: SBDB::CREATE | SBDB::Env::INIT_TXN | Bdb::DB_INIT_MPOOL)

			# Set inc-config - stored in etc/inc.cnf
			begin
				inc = @conf[:inc] = {}
				%w[hosts files fileparser].each {|key| @conf[:inc][key.to_sym] = config( @etc, key) }
				inc[:fileparser] = config( @etc, 'fileparser') {|val| Safebox.run "[#{val}]"}
			end
			@store = LogAn::Cache.new LogAn::AutoValueConvertHash.new( @etc[ 'sids.store', 'seeks', SBDB::Recno, SBDB::CREATE | SBDB::AUTO_COMMIT]), 3

			# Prepare Inc-server - create server
			LogAn::Inc::FileParser::Base.logdb = @logs
			LogAn::Inc::FileParser::Base.store = @store
			@serv = LogAn::Inc::Server.new :sock => TCPServer.new( *@conf[:server]), :config => @conf[:inc]

			# Shutdown on signals
			@sigs[:INT] = @sigs[:TERM] = method( :shutdown)

		rescue Object
			# It's better to close everything, because BDB doesn't like unexpected exits
			self.at_exit
			raise $!
		end

		# Will be called at exit.  Will close all opened BDB::Env
		def at_exit
			$stderr.puts :at_exit
			@logs and @logs.close
			@etc and @etc.close
		end

		# Shutdown Server cleanly. First shutdown TCPServer.
		def shutdown signal = nil
			$stderr.puts [:signal, signal, Signal[signal]].inspect  if signal
			@serv.close
			exit 0
		end

		# Runs server.  Don't use it!  Use #main.
		def run
			@serv.run
		end
	end
end
