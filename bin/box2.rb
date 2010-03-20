#!/usr/bin/ruby

require 'sbdb'

module Sandbox
	def self.run *paras, &exe
		exe = paras.shift  unless exe
		box = paras.shift || Class
		Thread.new do
			$SAFE = 4
			this = box.new *paras
			begin
				[:value, this.instance_eval( exe, "Sandbox")]
			rescue Object
				[:exception, $!]
			end
		end.value
	end

	def self.create_class *paras, &exe
		exe = paras.shift  unless exe
		run Class, *paras do
			eval exe
			self
		end
	end
	alias new_class create_class
end

class Box
	attr_reader :_, :db

	def initialize db, _
		@_, @db = _, db
	end

	def put( key, val)  @db[key] = val  end
	def get( key)  @db[key]  end
end

class ClassBuilder
end

class Emit
	def initialize( db)  @db = db  end
	def emit( key, val)  @db[key] = val  end
	def inspect()  "#<%s:0x%016x>" % [ self.class, self.object_id ]  end
end

class Persistent < Emit
	include Enumerable
	def initialize db, cursor
		super db
		@cursor = cursor
	end
	alias put emit
	alias []= emit
	def get( key)  @db[key]  end
	alias [] get
	alias fetch get
	def each &exe
		exe ? @cursor.each( &exe) : Enumerator.new( self, :each)
	end
	def to_hash
		rh = {}
		each {|key, val| rh[ key] = val }
		rh
	end
end

_ = nil
Dir.mkdir 'logs' rescue Errno::EEXIST
SBDB::Env.new 'logs', SBDB::CREATE | SBDB::Env::INIT_TRANSACTION do |logs|
	db = logs['test', :type => SBDB::Btree, :flags => SBDB::CREATE]
	db = Persistent.new db, db.cursor
	$stdout.print "(0)$ "
	STDIN.each_with_index do |line, i|
		ret = Sandbox.run line, Box, db, _
		if :value == ret.first
			_ = ret.last
			$stdout.puts "=> #{ret.last.inspect}"
		else
			$stdout.puts ret.last.inspect
		end
		$stdout.print "(#{i+1})$ "
	end
end
