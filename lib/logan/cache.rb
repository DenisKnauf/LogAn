
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
	attr_reader :decode, :encode

	def initialize source, encode = nil, each = nil, &decode
		@source, @encoder = source, decode.nil? ? encode || Marshal.method( :dump) : nil,
		@each = each || source.method( :each)  rescue NameError
		@decode = decode || Marshal.method( :restore)
	end

	def [] k
		@decode.call @source[k]
	end

	def []= k, v
		@source[k] = @encode.call v
	end

	def each *paras
		return Enumerator.new self, :each  unless block_given?
		@each.call *paras do |k, v|
			yield k, @decode.call( v)
		end
	end

	def each_keys *paras
		return Enumerator.new self, :each_keys  unless block_given?
		@each.call *paras do |k, v|
			yield k
		end
	end
end
