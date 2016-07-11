
Sketchup::require 'WidthLine/Common.rb'

module BFZH

class PathSplit

 def initialize
   @common_op = Common4Line.new
 end
 
 def split
   
 end
 
end



mod = Sketchup.active_model
ents = mod.entities
sel = mod.selection
s = PathSplit.new

end