
require 'sbdb'
require 'safebox'
require 'robustserver'
require 'socket'
require 'logan/inc'
require 'logan/loglines'
require 'logan/cache'

module LogAn::Logging
	def log lvl, *txt
		$stderr.puts( ([Time.now, lvl]+txt).inspect)
	end
	alias method_missing log
end

module LogAn::Inc
	class Main < RobustServer
		def cache ret, type, &e
			type ||= 1+4
			ret = LogAn::AutoValueConvertHash.new ret, &e  if type&4 > 0 or e
			ret = LogAn::Cache.new ret, type&3  if type&3 > 0
			ret
		end

		# Open Store.
		def store env, db, type = nil, flags = nil, &e
			LogAn::Logging.info :store, :open, "sids.cnf", db, type
			cache env[ 'sids.cnf', db, :flags => flags || SBDB::CREATE | SBDB::AUTO_COMMIT], type, &e
		end

		# Open Config.
		def config env, db, type = nil, flags = nil, &e
			LogAn::Logging.info :config, :open, "sids.cnf", db, type
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
				%w[hosts files].each {|key| configs[key.to_sym] = config( @etc, key) {|l|l} }
				configs[:fileparser] = config( @etc, 'fileparser') {|val| Safebox.run "[#{val}]"}
				LogAn::Inc::SID0.config = configs
			end

			# Open seeks-database
			begin
				stores = @conf[:stores] = {}
				db = @etc[ 'sids.store', 'seeks', SBDB::Recno, SBDB::CREATE | SBDB::AUTO_COMMIT]
				db = LogAn::AutoValueConvertHash.new( db, lambda {|val| val.pack( 'NN') }) {|val| (val||0.chr*8).unpack( 'NN') }
				stores[:seeks] = LogAn::Cache.new db
				LogAn::Inc::FileParser::Base.store = LogAn::Inc::SID0.store = stores
			end

			# Select-framework
			@select = LogAn::Inc::Select.new
			status = lambda do
				@select.at Time.now+5, &status
				LogAn::Logging.info @select
				@conf[:stores].each{|key, db| db.flush!}
			end
			status.call

			# Prepare Inc-server - create server
			@serv = LogAn::Inc::Server.new :sock => TCPServer.new( *@conf[:server]), :config => @conf[:configs], :select => @select
			LogAn::Logging.debug @serv

			# Shutdown on signals
			@sigs[:INT] = @sigs[:TERM] = method( :shutdown)

		rescue Object
			# It's better to close everything, because BDB doesn't like unexpected exits
			self.at_exit
			raise $!
		end

		# Will be called at exit.  Will close all opened BDB::Env
		def at_exit
			LogAn::Logging.info :at_exit
			@logs and @logs.close
			@etc and @etc.close
		end

		# Shutdown Server cleanly. First shutdown TCPServer.
		def shutdown signal = nil
			LogAn::Logging.info :signal, signal, Signal[signal]]  if signal
			@serv.close
			exit 0
		end

		# Runs server.  Don't use it!  Use #main.
		def run
			@serv.run
		end
	end
end
