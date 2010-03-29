
module LogAn
	module Inc
		module FileParser
			module Base
				class <<self
					attr_accessor :logdb, :store
				end

				def emit v
					@@logdb.push @sid, line
				end

				def seeks read
					inode, seek = (@@store[ :seeks, @sid] || "\0\0\0\0\0\0\0\0").unpack 'a4N'
					@@store[ :seeks, @sid] = [inode, read + seek].pack( 'a4N')
				end
			end

			class Line
				extend Base
				attr_reader :sid, :delimiter, :buffer, :linebuffer
				@@fileparser = []

				def self.[] sid
					@@fileparser[sid] ||= self.new sid
				end

				def initialize sid, delimiter = nil
					@sid, @delimiter = sid, delimiter || "\n"
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
	end
end
