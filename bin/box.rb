#!/usr/bin/ruby

require 'thread'

class Queue
	attr_reader :que, :waiting
end

Thread.abort_on_exception = true
q, o = Queue.new, Queue.new
puts q.inspect

t = Thread.new( q, o) do |q, o|
	begin
		o << 3
o.que.taint
q.que.taint
o.waiting.taint
q.waiting.taint
		$SAFE = 3
		loop do
			i = q.pop
			begin
				o.push eval(i)
			rescue Object
				o.push [$!.class, $!, $!.backtrace].inspect
			end
		end
	rescue Object
		o.push [$!.class, $!, $!.backtrace].inspect
	end
end

Thread.new( o) {|o| loop{$stdout.puts "=> #{o.pop.inspect}"} }

STDIN.each_with_index do |l,i|
	l.untaint
	q.push l
	$stdout.print "(#{i})> "
end
