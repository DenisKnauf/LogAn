
require 'sbdb'
require 'safebox'
require 'robustserver'

module LogAn::Inc
	class Main < RobustServer
		def config db, type = nil
			type ||= 1+4
			ret = @etc[ 'inc.cnf', db, SBDB::RDONLY]
			ret = AutoValueConvertHash.new ret  if type&4 > 0
			ret = Cache.new ret, type&3  if type&3 > 0
			ret
		end

		def initialize conf
			super
			@conf = conf
			@logs = LogAn::Loglines.new 'logs'
			etc = @conf[:etc] || 'etc'
			Dir.mkdir etc  rescue Errno::EEXIST
			@etc = SBDB::Env.new( etc,
					log_config: SBDB::Env::LOG_IN_MEMORY | SBDB::Env::LOG_AUTO_REMOVE,
					flags: SBDB::CREATE | SBDB::Env::INIT_TXN | Bdb::DB_INIT_MPOOL)
			@hosts = config 'hosts'
			@files = config 'files'
			@fileparser = config 'fileparser'
			@serv = LogAn::Inc.new :sock => TCPServer.new( *@conf[:server])
			@sigs[:INT] = @sigs[:TERM] = method(:shutdown)
		end

		def at_exit
			@logs and @logs.close
			@etc and @etc.close
		end

		def shutdown s = nil
			$stderr.puts [:signal, s, Signal[s]].inspect  if s
			@serv.close
			exit 0
		end

		def run
			@serv.run
		end
	end
end
