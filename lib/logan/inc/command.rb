
module LogAn
	module Inc
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
