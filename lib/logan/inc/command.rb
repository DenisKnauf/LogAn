
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
			class <<self
				def config=( db)  @@config = db  end
				def config()  @@config  end
				def store=( db)  @@store = db  end
				def store()  @@store  end
			end

			def initialize sid = 0
				super sid
				self[9] = method :event_hostname
				self[10] = method :event_filerotated
			end

			def event_filerotated line, sock
				sid, inode, seek = line.unpack 'NNN'
				@@store[ :seeks][ sid] = [inode, seek]
			end

			def event_hostname line, sock
				@@config[ :hosts].each do |sid, host|
					next  unless line == host
					file = @@config[ :files][ sid]
					next  unless file
					# command, SID, (inode, seek), file
					pc = [1, sid, @@store[ :seeks][ sid], file].flatten.pack 'nNNNa*'
					sock.write [pc.length, pc].pack( 'Na*')
				end
			end
		end
	end
end
