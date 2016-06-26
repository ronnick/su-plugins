require "sketchup.rb"

width_line = "width-line\width-line.rb"
filename = File.basename(width_line)
unless file_loaded?(filename)
  file_loaded filename
end
