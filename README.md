# A Ruby Interface to the WaterRower S4 Performance Monitor

This is a work in progress, to query the S4 performance monitor of the WaterRower rowing machine about the current workout status.

The idea is based on the James Nesfield's nodejs version located here: https://github.com/jamesnesfield/node-waterrower .

## Fair Warning

This is

  - work in progress
  - might never be finished
  - will not work if you don't know what you are doing
  - might break your S4/System (unlikely, but if you don't know what you are doing...)
  
## Get it to work

`gem build rowr_interface.gemspec`

`gem install ./row r_interface-*.gem`

Usage: See `bin/example`.

## Dependencies

`gem install serialport`

## Notes

Use at your own risk. Use under MIT license if you really need to have one.