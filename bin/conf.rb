#!/usr/bin/env ruby

require 'sbdb'

conf = {}
%w[etc sids].each {|key| conf[key.to_sym] = key }
conf[:sids] = File.basename( conf[:sids], ".cnf")+".cnf"

$stdout.puts ARGV.inspect

SBDB::Env.open( conf[:etc], SBDB::CREATE | SBDB::Env::INIT_TXN | Bdb::DB_INIT_MPOOL,
		log_config: SBDB::Env::LOG_IN_MEMORY | SBDB::Env::LOG_AUTO_REMOVE) do |etc|
	etc.recno( conf[:sids], ARGV[0], flags: SBDB::CREATE | SBDB::AUTO_COMMIT) do |db|
		$stderr.puts db.inspect
		if ARGV[2]
			db[ ARGV[1].to_i] = ARGV[2].empty? ? nil : ARGV[2]
		end
		if ARGV[1]
			$stdout.puts "#{ARGV[0].inspect} #{ARGV[1].to_i} #{db[ ARGV[1].to_i].inspect}"
		else
			db.each do |k, v|
				begin
					$stdout.puts "#{ARGV[0].inspect} #{k} #{v.inspect}"
				rescue Bdb::DbError
					next  if 22 == $!.code
					raise $!
				end
			end
		end
	end
end
