require 'serialport'

class RowrInterface

  BAUD_RATE = 19_200
  PORT_LOCATION = "/dev/serial/by-id/usb-Microchip_Technology_Inc._CDC_RS-232\:_WR-S4.2-if00"
  UPDATE_STATE_EVERY = 1000 #ms

  COMMAND_START = "USB"
  COMMAND_EXIT = "EXIT"
  COMMAND_READ_DATA_16_BIT = "IRD"
  COMMAND_READ_DATA_24_BIT = "IRT"
  
  MEMORY_LOCATIONS_16_BIT = {
    total_distance: "057", #meters
    total_strokes: "140", #n
    current_speed: "148", #cm/s
    current_energy: "088", #watt
  }
  
  MEMORY_LOCATIONS_24_BIT = {
    total_calories: "08A", #cal
  }

  def initialize  
    @port_mutex = Mutex.new
    @data_mutex = Mutex.new
  
    @last_update = Time.now
    @last_stroke_start = Time.now
    @last_stroke_end = Time.now
    @data = {}
    @closing = false
    
    @stroke_callback = nil
    @reset_callback = nil
  end

  def current_status
    clone = nil
    @data_mutex.synchronize do
      clone = @data.clone
    end

    clone
  end

  def start    
    # Create connection
    @port = SerialPort.new(PORT_LOCATION, BAUD_RATE)
    write(COMMAND_START)
    t = Thread.new do     
      main_loop
    end
    t
  end
  
  def each_stroke(&block)
    @stroke_callback = block
  end
  
  def on_reset(&block)
    @reset_callback = block
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
  
  def request_data_16_bit(memory_name)
    memory_location = MEMORY_LOCATIONS_16_BIT[memory_name]
    unless memory_location.nil?
      write(COMMAND_READ_DATA_16_BIT + memory_location)
    end
  end
  
  def request_data_24_bit(memory_name)
    memory_location = MEMORY_LOCATIONS_24_BIT[memory_name]
    unless memory_location.nil?
      write(COMMAND_READ_DATA_24_BIT + memory_location)
    end
  end

  def main_loop
    
    while true
      break if @closing
      
      query_if_necessary
        
      data = read
      parse_and_update_internals(data)
    end
    
  end
  
  def parse_and_update_internals(data)
    case data
    when /^P.*$/
      # pulse value unused by now
    when /^SS/
      @last_stroke_start = Time.now
      #puts "Understood: " + "Start of stroke."
    when /^SE/
      @last_stroke_end = Time.now
      #puts "Understood: " + "End of stroke."
      notify_of_stroke
    when /^ID(.)(.{3})(.*)\r\n$/
      value = ("0x" + $3).hex
      case $1
      when "D"
        data_type = MEMORY_LOCATIONS_16_BIT.select {|k,v| v == $2 }.first
      when "T"
        data_type = MEMORY_LOCATIONS_24_BIT.select {|k,v| v == $2 }.first
      end

      unless data_type.nil?
        @data_mutex.synchronize {
          #puts "Understood: " + data_type[0].to_s + " => " + value.to_s
          @data[data_type[0]] = value
        }
      end
    when /ERROR/
      puts "ERROR."
    when /AKR/
      unless @reset_callback.nil?
        Thread.new do
          @reset_callback.call()
        end
      end
    else
      # puts "Did not understand: " + data
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
      @last_update = Time.now
    end
  end
  
  def query!
    MEMORY_LOCATIONS_16_BIT.each do |name, location|
      request_data_16_bit(name)
    end
    MEMORY_LOCATIONS_24_BIT.each do |name, location|
      request_data_24_bit(name)
    end
  end
  
end