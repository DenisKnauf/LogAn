
require 'select'

module Logan
	module Inc
		module FileParser
			module Base
				def emit v
					@logdb.push @sid, line
				end

				def seeks read
					inode, seek = (@store[ :seeks, @sid] || "\0\0\0\0\0\0\0\0").unpack 'a4N'
					@store[ :seeks, @sid] = [inode, read + seek].pack( 'a4N')
				end
			end

			class Line
				extend Base
				attr_reader :sid, :delimiter, :buffer, :linebuffer
				@@fileparser = []

				def self.[] sid
					@@fileparser[sid] ||= self.new sid
				end

				def initialize logdb, store, sid, delimiter = nil
					@logdb, @store, @sid, @delimiter = logdb, store, sid, delimiter || "\n"
					@delimiter = Regexp.new "^.*?#{@delimiter}"
					@buffer, @linebuffer = Select::Buffer.new( ''), Select::Buffer.new( '')
				end

				def event_read str, sock
					@buffer += str
					@buffer.each! @delimiter do |line|
						emit line
						seeks line.length
					end
				end
			end

			class Multiline < Line
				def initialize sid, delimiter = nil, multiline = nil
					super sid, delimiter
					@multiline = multiline || /^\d\d-\d\d-\d\d:/
				end

				def event_read str, sock
					@buffer += str
					@buffer.each! @delimiter do |line|
						if line =~ @multiline
							emit @linebuffer.to_s
							seeks @linebuffer.length
							@linebuffer.replace line
						else @linebuffer += line
						end
					end
				end
			end

		end

		class Command < ::Array
			attr_reader :sid
			def initialize sid = 0
				@sid = sid
			end

			def event_read line, sock
				cmd, l = line.unpack 'na*'
				self[cmd].call( l, sock)  if self[cmd]
			end
		end

		class SID0 < Command
			def initialize store, config, sid = 0
				@store, @config = store, config
				self[9] = method :event_hostname
				self[10] = method :event_filerotated
			end

			def event_filerotated line, sock
				sid, d = line.unpack 'Na8'
				@store[ :seeks, sid] = d
			end

			def event_hostname line, sock
				@config[ :hosts].each do |sid,host|
					next  unless line == host
					file = @config[ :files, sid]
					next  unless file
					# command, SID, (inode, seek), file
					pc = [1, sid, @store[ :seeks, sid] || "\x00\x00\x00\x00\x00\x00\x00\x00", file].pack 'nNa8a*'
					sock.write [pc.length, pc].pack( 'Na*')
				end
			end
		end
	end
end
