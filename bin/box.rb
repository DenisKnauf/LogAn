#!/usr/bin/ruby

require 'thread'

class Box
	attr_reader :_, :emited
	alias db emited
	alias persistent emited
	attr_accessor :emited

	def initialize db, _
		@_, @emited = _, db
	end

	def emit k, v
		@emited[k] = v
	end

	def do code
		instance_eval code, self.class.to_s, 0
	end
end

require 'sbdb'

class Persistent
	include Enumerable
	def initialize( db)  @db, @cursor = db, db.cursor  end
	def emit( k, v)  @db[k] = v  end
	alias push emit
	alias put emit
	alias []= emit
	def get( k)  @db[k]  end
	alias [] get
	alias fetch get
	def inspect() "#<%s:0x%016x>" % [ self.class, self.object_id ] end
	def each &e
		e ? @cursor.each( &e) : Enumerator.new( self, :each)
	end
	def to_hash
		h = {}
		each {|k, v| h[ k] = v }
		h
	end
end

#Persistent.freeze

r = nil
Dir.mkdir 'logs' rescue Errno::EEXIST
SBDB::Env.new 'logs', SBDB::CREATE | SBDB::Env::INIT_TRANSACTION do |logs|
	db = Persistent.new logs['test', :type => SBDB::Btree, :flags => SBDB::CREATE]
	$stdout.print "(0)$ "
	STDIN.each_with_index do |l, i|
		r = Thread.new do
				l.untaint
				$SAFE = 4
				b = Box.new db, r
				begin
					b.do( l)
				rescue Object
					$!
				end
			end.value
		$stdout.print "=> #{r.inspect}\n(#{i+1})$ "
	end
end
