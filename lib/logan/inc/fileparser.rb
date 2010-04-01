
module LogAn
	module Inc
		module FileParser
			module Base
				class <<self
					def logdb=( var)  @@logdb = var  end
					def logdb()  @@logdb  end
					def store=( var)  @@store = var  end
					def store()  @@store  end
				end

				def emit line
					@@logdb.emit line, @sid
				end

				def seeks read
					inode, seek = @@store[ :seeks][@sid]
					@@store[ :seeks][@sid] = [inode, read + seek]
				end
			end

			class Line
				include Base
				attr_reader :sid, :delimiter, :buffer, :linebuffer

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
