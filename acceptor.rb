#!/usr/bin/env ruby

require 'serialport'

class Acceptor

  BAUD_RATE = 19_200
  PORT_LOCATION = "/dev/serial/by-id/usb-Microchip_Technology_Inc._CDC_RS-232\:_WR-S4.2-if00"
  UPDATE_STATE_EVERY = 1000 #ms

  COMMAND_START = "USB"
  COMMAND_EXIT = "EXIT"
  COMMAND_READ_DATA = "IRD"

  MEMORY_LOCATIONS = {
    total_distance: "057", #meters
    total_time: "05b", #seconds
    total_calories: "08a", #kcal
    total_strokes: "140", #n
    current_speed: "148" #cm/s
  }
  
  @port_mutex = Mutex.new
  @data_mutex = Mutex.new
  
  @last_update = Time.now
  @last_stroke_start = Time.now
  @last_stroke_end = Time.now
  @data = {}

  def start(&block)
    @stroke_callback = block
    
    # Create connection
    @port = SerialPort.new(PORT_LOCATION, BAUD_RATE)
    write(COMMAND_START)
    
    main_loop
    
  end  
  
  def end
      write(COMMAND_EXIT)
      @closing = true
      @port_mutex.synchronize {
        @port.close
      }
  end
  
  protected
  
  def write(command)
    @port_mutex.synchronize {
      unless @port.closed?
        @port.write(command + "\r\n")
      end
    }
  end
  
  def read
    @port_mutex.synchronize {
      unless @port.closed?
        @port.readline
      end
    }
  end
  
  def request_data(memory_name)
    memory_location = MEMORY_LOCATIONS[memory_name]
    unless MEMORY_LOCATIONS[memory_name].nil?
      write(COMMAND_READ_DATA + memory_location)
    end
  end
  
  def main_loop
    
    while true
      break if @closing
      
      query_if_necessary
        
      data = read
      puts "Read: " + data
      parse_and_update_internals(data)
    end
    
  end
  
  def parse_and_update_internals(data)
    case data
    when /SS/
      @last_stroke_start = Time.now
      puts "Understood: " + "Start of stroke."
    when /SE/
      @last_stroke_end = Time.now
      puts "Understood: " + "End of stroke."
      notify_of_stroke
    when /^IDD([0-9]{3})(.*)\r\n$/
      value = ("0x" + $2).hex
      data_type = MEMORY_LOCATIONS.find($1)
      
      unless data_type.nil?
        @data_mutex.synchronize {
          puts "Understood: " + data_type + " => " + value.to_s
          @data[data_type] = value
        }
      end
    end
  end
  
  def notify_of_stroke
    unless @stroke_callback.nil?
      time_for_stroke = 0 #seconds
      @data_mutex.synchronize {
        time_for_stroke = @last_stroke_end - @last_stroke_start
      }
    
      Thread.new do
        @stroke_callback.call(time_for_stroke)
      end
    end
  end
  
  def query_if_necessary 
    #if query interval has passend
    if Time.now - @last_update > (UPDATE_STATE_EVERY / 1000.0)
      query!
    end
  end
  
  def query!
    MEMORY_LOCATIONS.each do |name, location|
      request_data(name)
    end
  end
  
end