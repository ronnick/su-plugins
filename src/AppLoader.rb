# LOAD SUPPORT FILES
require 'sketchup.rb'

# CREATE EXTENSION
ext = SketchupExtension.new('WidthLine', 'WidthLine/WidthLine.rb')
# REGISTER AND LOAD THE EXTENSION
ext.creator = 'Nick Luo'
ext.version = '1.0.0'
ext.copyright = 'bfzh copyright reserved'
ext.description = 'draw face along a line with special width'
# REGISTER AND LOAD THE EXTENSION
Sketchup.register_extension(ext, true)
