
class LogAn::Cache
	READ = 1
	WRITE = 2
	attr_reader :source, :data

	def initialize source, type = nil, data = nil
		type ||= READ | WRITE
		@source, @data, self.type = source, data || {}, type
	end

	def flush!
		@data.each {|k,v| @obj[k] = v }
		@data = {}
	end

	def dget k
		@data[k] ||= @obj[k]
	end

	def oget k
		@data[k] || @obj[k]
	end

	def dset k, v
		@data[k] ||= v
	end

	def oset k, v
		@obj[k] = v
	end

	def type= type
		self.read, self.write = type & 1 > 0, type & 2 > 0
		type
	end

	def read_cache= type
		@type &= ~ (type ? 0 : 1)
		define_singleton_method :[], type ? :oget : :dget
	end

	def write_cache= type
		@type &= ~ (type ? 0 : 2)
		define_singleton_method :[], type ? :oset : :dset
	end

	#include Enumerable
	#def each &e
		#return Enumerator.new self, :each  unless e
		#flush!
		#@obj.each &e
		#self
	#end
end

class LogAn::AutoValueConvertHash
	include Enumerable

	def initialize obj, encode = nil, each = nil, &decode
		@object, @encoder = obj, decode.nil? ? encode || Marshal.method( :dump) : nil,
		@each = each || obj.method( :each)  rescue NameError
		@decode = decode || Marshal.method( :restore)
	end

	def [] k
		decode.call @object[k]
	end

	def []= k, v
		@object[k] = encode.call v
	end

	def each *paras
		@each.call *paras do |k, v|
			yield k, decode( v)
		end
	end
end
