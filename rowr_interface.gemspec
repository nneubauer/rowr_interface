Gem::Specification.new do |s|
  s.name        = 'rowr_interface'
  s.version     = '1.0.0'
  s.date        = '2015-05-23'
  s.summary     = "A Ruby interface to the WaterRower S4 Performance Monitor."
  s.description = "A Ruby interface to the WaterRower S4 Performance Monitor."
  s.authors     = ["Nicolas Neubauer"]
  s.email       = 'find@me.com'
  s.files       = ["lib/rowr_interface.rb"]
  s.executables << 'example'
  s.homepage    =
    'https://github.com/nneubauer/rowr_interface'
  s.license       = 'MIT'
  
  s.add_runtime_dependency 'serialport', '~> 1.3'
end