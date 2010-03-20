#!/usr/bin/ruby

require 'sbdb'
require 'safebox'

_ = nil
Dir.mkdir 'logs' rescue Errno::EEXIST
SBDB::Env.new 'logs', SBDB::CREATE | SBDB::Env::INIT_TRANSACTION do |logs|
	db = logs['test', :type => SBDB::Btree, :flags => SBDB::CREATE]
	db = Safebox::Persistent.new db, db.cursor
	$stdout.print "(0)$ "
	STDIN.each_with_index do |line, i|
		ret = Safebox.run line, Safebox::Box, db, _
		if :value == ret.first
			_ = ret.last
			$stdout.puts "=> #{ret.last.inspect}"
		else
			$stdout.puts ret.last.inspect
		end
		$stdout.print "(#{i+1})$ "
	end
end
