
require 'logan/loglines'
require 'time'

class LogAn::Analyse
	attr_reader :lines

	def close
		@lines.close
	end

	def initialize lines
		@lines = String === lines ? LogAn::Loglines.new( lines) : lines
	end

	def extremum val
		val = case val
			when String  then Time.parse val
			when Integer then Time.at val
			when Time    then val
			else raise ArgumentError, "Unknwon type: #{val}", caller[ 1..-1]
			end
	end

	def timerange min, max = nil
		exend = false
		min, max, exend = min.min, min.max, min.exclude_end?  if Range === min
		Range.new extremum( min), extremum( max), exend
	end

	def dbs min, max = nil, &exe
		return Enumerator.new( self, :dbs, min, max)  unless exe
		range = timerange min, max
		@lines.rdb.each do |time, db|
			exe.call db
		end
	end

	def search min, max = nil, &exe
		dbs = @lines.dbs
		range = timerange min, max
		@lines.rdb.each do |time, db|
			dbs[ UUIDTools::UUID.parse_raw( db)].each &exe  if range === Time.at( *time.unpack( 'N'))
		end
	end
	alias [] search

	def each min, max = nil, &exe
		exe ? search( min, max, &exe) : Enumerator.new( self, :search, min, max)
	end
end
