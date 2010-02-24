require 'logan'

class Logan::Type::Syslog
	include CStruct
	def self._directives
		['a*', 0, :]
	end

	def parse
		
	end
end
