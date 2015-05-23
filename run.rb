#!/usr/bin/env ruby

require './acceptor'

acceptor = Acceptor.new
t = acceptor.start do |stroke_time|

  puts "Stroke took " + stroke_time.to_s
  puts "Data: " + acceptor.current_status.inspect


end
t.join