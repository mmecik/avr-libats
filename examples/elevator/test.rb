#!/usr/bin/env ruby

require 'rubygems'
require 'serialport'
require 'json'

#Really hacky discrete event simulator for the elevator. Each service request
#and passenger request should be an object along with total wait time for service.

semaphore = Mutex.new

FLOORS = 10

curr = 0

sp = SerialPort.new "/dev/tty.usbmodemfd121", 9600, 8 , 1, SerialPort::NONE

#Serial Connection Resets the Chip.
sleep 1.0

$origin = Time.now.to_f * 1000.0

def snapshot()
  Time.now.to_f * 1000.0 - $origin
end

a = Thread.new {
  while true
    #Go to a random floor
    direction = (rand(2) == 0) ? 'u' : 'd'
    floor = rand(FLOORS) + 1
    out = "#{direction}#{floor}"
    semaphore.synchronize {
      puts ({:tag => "service",:dir => direction, :flr => floor, :time => snapshot()}.to_json)
      sp.print "#{out}\r"
      sp.flush
    }
    sleep (rand(5)+1)
  end
}

while true
  resp = ""
  resp = sp.readline("\n")

  if m = /^(f|o)([0-9]+).*/.match(resp)
    if m[1] == 'f'
      target = m[2].to_i
      diff = (curr - target).abs
      puts ({:tag => "move", :from => curr, :time => snapshot()}.to_json)
      sleep diff
      semaphore.synchronize {
        curr = target
        puts ({:tag => "arrive", :flr => m[2], :time => snapshot()}.to_json)
        sp.print "a#{m[2]}\r"
        sp.flush
      }
    elsif m[1] == 'o'
      semaphore.synchronize {
        puts ({:tag => "open", :time => snapshot()}.to_json)
        (rand(2)+1).times do
          flr = rand(FLOORS)+1
          puts ({:tag => "request", :flr => m[2], :time => snapshot()}.to_json)
          sp.print "r#{flr}\r"
          sp.flush
        end
      }
      sleep 2.0
      puts ({:tag => "close", :time => snapshot()}.to_json)
      sp.print "c\r"
    end
  else
    puts resp
    raise
  end
end
