class CStruct
	def new post, *p
		Class.new do
			include CStruct::Mix
			eval <<-EOF
				attr_accessor #{p.map{|n,v| ":#{n}" }.join', '}
				def self._directives
					["#{p.map{|n,v|"#{v}"}.join}", #{post}]
				end
				def initialize data
					#{p.map{|n,v|"@#{n}"}.join', '} = super data
				end
				def _create
					super #{p.map{|n,v|"@#{n}"}.join', '}
				end
			EOF
		end
	end
end

module CStruct::Mix
	def initialize data
		pre, pos = self.class._directives
		if pos.nil? or pos == 0  then data.unpack pre
		elsif pos == 1  then data.unpack pre+'a*'
		else
			# Statisch lange Daten,  Laengen von var und  der Rest in var
			(*dat, var) = data.unpack pre + ('N'*(pos-1)) + 'a*'
			dat[ 0...-pos ] + # Statisch lange Daten
				var.unpack( # Variabel lange Daten
					dat[ -pos...-1 ].inject( data.length-var.length) {|i,j|
						j.push i-j.last # Differenzieren
					}.map {|i| "a#{i}" }.join) # Packstring zusammensetzen
		end
	end

	def _create *data
		pre, pos = self.class._directives
		if pos.nil? or pos == 0  then data.pack pre
		elsif pos == 1  then data.pack pre+'a*'
		else
			r = data[ 0...-pos ].pack pre
			r += data[ -pos..-1 ].inject( [r.length]) {|i,j| j.push i+j.last}[1...-1].pack 'N*'
			r + data[ -pos..-1 ].pack 'a*'*(pos-1)
		end
	end
end
