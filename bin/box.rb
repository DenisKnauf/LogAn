#!/usr/bin/ruby

require 'thread'

class Queue
	attr_reader :que, :waiting
end

class Box
	attr_reader :_
	attr_accessor :emited

	def initialize _
		@_, @emited = _, []
	end

	def emit k, v
		@emited.push [k, v]
	end
end

Thread.abort_on_exception = true
q, o, r = Queue.new, Queue.new, nil
puts q.inspect
$stdout.print "(0)$ "

STDIN.each_with_index do |l, i|
	r = begin
			Thread.new do
				l.untaint
				$SAFE = 4
				b = Box.new r
				[b.instance_eval( l, 'BOX', 0), b.emited]
			end.value
		rescue Object
			[$!.class, $!, $!.backtrace].inspect
		end
	$stdout.print "#{r.inspect}\n(#{i+1})$ "
end
