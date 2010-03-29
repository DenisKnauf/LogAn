
require 'select'

module LogAn
	module Inc
	end
end

class LogAn::Inc::Select <::Select
	attr_reader :entries
	def initialize *p
		super *p
		@entries=[]
	end

	def run
		until @exit || (@exit_on_empty && self.empty?)
			cron
			run_once 1
		end
	end

	def cron
		@entries.each do |e|
			return  if e > Time.now
			e.call
			@entries.shift
		end
	end

	class Entry < Time
		attr_reader :do
		def do &e
			@do = e
		end

		def call *p
			@do.call *p
		end

		def self.new *a, &e
			x = self.at *a
			x.do &e
			x
		end
	end

	def at a, &e
		a = Entry.new a, &e if e
		@entries << a
		@entries.sort!
	end
end

class LogAn::Inc::Socket <::Select::Socket
	def event_read sock = @sock, event = :read
		begin
			@linebuf += sock.readpartial( @bufsize)
		rescue EOFError
			self.event_eof sock
		rescue Errno::EPIPE => e
			self.event_errno e, sock, event
		rescue IOError
			self.event_ioerror sock, event
		rescue Errno::ECONNRESET => e
			self.event_errno e, sock, event
		end
		loop do
			return  if @linebuf.size < 4
			l = @linebuf.unpack( 'N')[0]
			return  if l > @linebuf.length
			@linebuf.remove 4
			event_cmd @linebuf.remove( l)
		end
	end
end

class LogAn::Inc::Server < ::Select::Server
	attr_reader :config

	def init opts
		super opts
		@config = opts[:config] or raise( ArgumentError, "#{self.class} needs a Config!")
	end

	def event_new_client sock
		{ :clientclass => LogAn::Inc::Server::Socket, :config => @config }
	end

	class Socket < LogAn::Inc::Socket
		attr_reader :config

		def init opts
			super opts
			@config = opts[:config] or raise( ArgumentError, "#{self.class} needs a Config!")
		end
		
		def event_cmd cmd
			sid, line = cmd.unpack 'Na*'
			fps = @config[:fileparser][sid]
			fp.event_line line, self  if fp
		end
	end
end
