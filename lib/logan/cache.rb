
class LogAn::Cache
	READ = 1
	WRITE = 2
	attr_reader :source, :data

	def initialize source, type = nil, data = nil
		type ||= READ | WRITE
		@source, @data, self.type = source, data || {}, type
	end

	def flush!
		@data.each {|k,v| @source[k] = v }
		@data = {}
	end

	def dget k
		@data[k] ||= @source[k]
	end

	def oget k
		@data[k] || @source[k]
	end

	def dset k, v
		@data[k] ||= v
	end

	def oset k, v
		@source[k] = v
	end

	def type= type
		self.read_cache, self.write_cache = type & 1 > 0, type & 2 > 0
		type
	end

	def read_cache= type
		@type &= ~ (type ? 0 : 1)
		define_singleton_method :[], method( type ? :oget : :dget)
	end

	def write_cache= type
		@type &= ~ (type ? 0 : 2)
		define_singleton_method :[]=, method( type ? :oset : :dset)
	end

	include Enumerable
	def each *paras
		return Enumerator.new self, :each  unless block_given?
		flush!  if @type&2 == 2
		@source.each_keys( *paras) do |key|
			yield key, self[key]
		end
		self
	end
end

class LogAn::AutoValueConvertHash
	include Enumerable
	attr_reader :source

	def initialize source, encode = nil, each = nil, &decode
		@source, @encode = source, encode || ( decode.nil? && Marshal.method( :dump) )
		@each, @decode = each, decode || Marshal.method( :restore)
		@each ||= source.method( :each)  rescue NameError
		define_singleton_method :encode, &@encode  if @encode
		define_singleton_method :decode, &@decode  if @decode
		LogAn::Logging.debug encode: @encode, decode: @decode, each: @each
	end

	def [] k
		decode @source[k]
	end

	def []= k, v
		@source[k] = encode v
	end

	def each *paras
		return Enumerator.new self, :each  unless block_given?
		@each.call *paras do |k, v|
			yield k, decode( v)
		end
	end

	def each_keys *paras
		return Enumerator.new self, :each_keys  unless block_given?
		@each.call *paras do |k, v|
			yield k
		end
	end
end
