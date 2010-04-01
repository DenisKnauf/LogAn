#!/usr/bin/ruby

require 'sbdb'
require 'uuidtools'
require 'logan'

module LogAn
	class Loglines
		attr_reader :env, :rdb, :dbs, :counter

		def self.new *paras
			ret = obj = super( *paras)
			begin ret = yield obj
			ensure
				SBDB.raise_barrier &obj.method( :close)
			end  if block_given?
			ret
		end

		def initialize env = nil
			env ||= 'logs'
			@env = if String === env
					Dir.mkdir env  rescue Errno::EEXIST
					SBDB::Env.new env,
						log_config: SBDB::Env::LOG_IN_MEMORY | SBDB::Env::LOG_AUTO_REMOVE,
						flags: SBDB::CREATE | SBDB::Env::INIT_TXN | Bdb::DB_INIT_MPOOL
				else env
				end
			@rdb = @env[ 'rotates.db', :type => SBDB::Btree, :flags => SBDB::CREATE | SBDB::AUTO_COMMIT]
			@queue = @env[ "newids.queue", :type => SBDB::Queue,
					:flags => SBDB::CREATE | SBDB::AUTO_COMMIT, :re_len => 16]
			@dbs, @counter = {}, 0
			self.hash_func = lambda {|k|
				[k.timestamp.to_i/60/60].pack 'N'  # Hour-based rotation
			}
		end

		def close
			@env.close
		end

		def hash_func= exe
			hash_func &exe
		end

		def hash_func &exe
			@hash_func = exe  if exe
			@hash_func
		end

		def hashing key
			@hash_func.call key
		end

		def db_name id
			hash = hashing id
			name = @rdb[ hash]
			if name
				name = UUIDTools::UUID.parse_raw name
			else
				name = UUIDTools::UUID.timestamp_create
				@rdb[ hash] = name.raw
			end
			name
		end

		def db name
			@dbs[name] ||= @env[ name.to_s, :type => SBDB::Btree,
					:flags => SBDB::CREATE | SBDB::AUTO_COMMIT]
		end

		def sync
			@dbs.each {|name, db| db.sync }
			@rdb.sync
		end

		def put val, sid = nil
			id = UUIDTools::UUID.timestamp_create
			dat = [sid || 0x10, val].pack 'Na*'
			name = db_name id
			db( name)[ id.raw] = dat
			@counter += 1
			@queue.push id.raw
		end
		alias emit put

		def get key
			name = db_name id
			db( name)[ id.raw]
		end
	end
end
