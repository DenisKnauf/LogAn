#!/usr/bin/ruby

require 'sbdb'
require 'uuidtools'

class Rotate
	def initialize db, env = db.home, &e
		@rdb, @env, @dbs = db, env, {}
		self.hash = e || lambda {|k|
			[k.timestamp.to_i/60/60/24].pack 'N'
		}
	end

	def hash= e
		self.hash &e
	end

	def hash &e
		@hash_func = e  if e
		@hash_func
	end

	def hashing k
		@hash_func.call k
	end

	def db_name id
		h = hashing id
		n = @rdb[ h]
		if n
			n = UUIDTools::UUID.parse_raw n
		else
			n = UUIDTools::UUID.timestamp_create
			@rdb[ h] = n.raw
			info :create => n.to_s
		end
		n
	end

	def db n
		@env[ n.to_s, :type => SBDB::Btree, :flags => SBDB::CREATE | SBDB::AUTO_COMMIT]
	end

	def sync
		@dbs.each{|n,db|db.sync}
		@rdb.sync
	end

	def close
		@dbs.each{|n,db|db.close 0}
		@rdb.close 0
	end

	def put k, v, f = k
		id = UUIDTools::UUID.timestamp_create
		s = [0x10, v].pack 'Na*'
		n = db_name id
		db( n)[ id.raw] = s
	end
	alias emit put

	def get k
		n = db_name id
		db( n)[ id.raw] = s
	end
end
