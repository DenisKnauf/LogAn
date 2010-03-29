
require 'sbdb'
require 'safebox'
require 'robustserver'
require 'socket'
require 'logan/inc'
require 'logan/loglines'
require 'logan/cache'

module LogAn::Inc
	class Main < RobustServer
		def cache db, type, &e
			type ||= 1+4
			ret = LogAn::AutoValueConvertHash.new ret, &e  if type&4 > 0 or e
			ret = LogAn::Cache.new ret, type&3  if type&3 > 0
			ret
		end

		# Open Store.
		def store env, db, type = nil, flags = nil, &e
			$stderr.puts [:store, :open, "sids.cnf", db, type].inspect
			cache env[ 'sids.cnf', db, :flags => flags || SBDB::CREATE | SBDB::AUTO_COMMIT], type, &e
		end

		# Open Config.
		def config env, db, type = nil, flags = nil, &e
			$stderr.puts [:config, :open, "sids.cnf", db, type].inspect
			cache env[ 'sids.cnf', db, :flags => flags || SBDB::RDONLY], type, &e
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
			LogAn::Inc::FileParser::Base.logdb = @logs

			# Open config-databases
			Dir.mkdir @conf[:etc]  rescue Errno::EEXIST
			@etc = SBDB::Env.new( @conf[:etc],
					log_config: SBDB::Env::LOG_IN_MEMORY | SBDB::Env::LOG_AUTO_REMOVE,
					flags: SBDB::CREATE | SBDB::Env::INIT_TXN | Bdb::DB_INIT_MPOOL)

			# Open configs
			begin
				configs = @conf[:configs] = {}
				%w[hosts files].each {|key| configs[key.to_sym] = config( @etc, key) }
				configs[:fileparser] = config( @etc, 'fileparser') {|val| Safebox.run "[#{val}]"}
			end

			# Open seeks-database
			begin
				stores = @conf[:stores] = {}
				stores[:seeks] = store( @etc, 'seeks', 3,
						lambda {|val| val.pack( 'NN') }) {|val| (val||0.chr*8).unpack( 'NN') }
				LogAn::Inc::FileParser::Base.store = LogAn::Inc::SID0.store = stores
			end

			# Prepare Inc-server - create server
			@serv = LogAn::Inc::Server.new :sock => TCPServer.new( *@conf[:server]), :config => @conf[:configs]

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
