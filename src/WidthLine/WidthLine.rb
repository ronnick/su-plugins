
Sketchup::require 'WidthLine/Common.rb'

module BFZH

class WidthLine
  
  # constructor
  def initialize
    @edges = nil
    @all_vertices = nil
    @sorted_vertices = nil
    @positive_vertices = []
    @negative_vertices = []
    @vertices_cnt = nil
    @vect_fa = nil
    @common_op = Common4Line.new
  end
  
  # Main interface to draw width line
  def width_line
    model = Sketchup.active_model
    ents = model.entities
    sel = model.selection
  
    #all_one_face sel
    @edges = @common_op.get_edges sel
    if @edges.length < 2
      UI.messagebox "请选择至少2条相连的线段"
      return
    end
    
    unless @common_op.is_all_one_face @edges
      UI.messagebox "所有的线段不在一个平面上"
      return
    end
    
    @all_vertices = @common_op.get_all_vertices @edges
    @vertices_cnt = @common_op.count_vertex @all_vertices
    
    unless @common_op.is_all_connected @vertices_cnt
      UI.messagebox "所有的线段未连续连接"
      return
    end
    
    @vect_fa = @common_op.vect_fa
    # judge all edges are parallel
    unless @vect_fa
      UI.messagebox "所有的线段不能为一条直线"
      return
    end
    
    # create parameters inputbox
    prompts = ["宽度(mm): ", "删除中心线: ", "是否成组: "]
    defaults = ["500", "Yes", "Yes"]
    list = ["", "Yes|No","Yes|No"]
    results = UI.inputbox prompts, defaults, list, "WidthLine参数设置"
    # convert the parameters string
    wlen = results[0].to_i
    wlen = wlen / 2
    wlen = wlen.mm
    
    start_vertex = @common_op.find_start_vertex @vertices_cnt
    @sorted_vertices = @common_op.sort_vertices @edges, start_vertex
    
    # get the normal vector of the face.
    vect1 = @sorted_vertices[1].position - @sorted_vertices[0].position
    # offset the start vertex
    vect2 = vect1.cross @vect_fa
    vect2.length = wlen
    
    pt = @sorted_vertices[0].position.offset vect2
    pt_n = @sorted_vertices[0].position.offset vect2.reverse
    @positive_vertices << pt
    @negative_vertices << pt_n
    
    len = @sorted_vertices.length
    # offset the connected vertices
    for i in 1...len-1 do
      vect_l = @sorted_vertices[i].position - @sorted_vertices[i-1].position
      vect_r = @sorted_vertices[i+1].position - @sorted_vertices[i].position
      
      vect_l_offset = vect_l.cross @vect_fa
      vect_l_offset.length = wlen
      
      # two connected edges are parallel
      if vect_l.parallel? vect_r
        pt2 = @sorted_vertices[i].position.offset vect_l_offset
        pt2_n = @sorted_vertices[i].position.offset vect_l_offset.reverse
        @positive_vertices << pt2
        @negative_vertices << pt2_n
      else
        pt1 = @sorted_vertices[i-1].position.offset vect_l_offset
        pt2 = @sorted_vertices[i].position.offset vect_l_offset
        edge_l = [pt1, pt2]
        
        pt1_n = @sorted_vertices[i-1].position.offset vect_l_offset.reverse
        pt2_n = @sorted_vertices[i].position.offset vect_l_offset.reverse
        edge_l_n = [pt1_n, pt2_n]
        
        
        vect_r_offset = vect_r.cross @vect_fa
        vect_r_offset.length = wlen
        
        pt1 = @sorted_vertices[i].position.offset vect_r_offset
        pt2 = @sorted_vertices[i+1].position.offset vect_r_offset
        edge_r = [pt1, pt2]
        
        pt1_n = @sorted_vertices[i].position.offset vect_r_offset.reverse
        pt2_n = @sorted_vertices[i+1].position.offset vect_r_offset.reverse
        edge_r_n = [pt1_n, pt2_n]
        
        pt_conn = Geom.intersect_line_line edge_l, edge_r
        pt_conn_n = Geom.intersect_line_line edge_l_n, edge_r_n
        
        @positive_vertices << pt_conn
        @negative_vertices << pt_conn_n
      end
    end # end of for connected vertices
    
    # offset the last vertex      
    vector_last = @sorted_vertices[len-1].position - @sorted_vertices[len-2].position
    vect_last_offset = vector_last.cross @vect_fa
    vect_last_offset.length = wlen
    
    pt = @sorted_vertices[len-1].position.offset vect_last_offset
    @positive_vertices << pt
    
    pt_n = @sorted_vertices[len-1].position.offset vect_last_offset.reverse
    @negative_vertices << pt_n
    
    all_new_vertices = @positive_vertices.concat @negative_vertices.reverse
    # create face using new vertices
    model.start_operation "dline", true
    face = ents.add_face all_new_vertices
    
    # delete the middle line
    if "Yes" == results[1].to_s
      ents.erase_entities @edges
      @edges.clear
    end
    # group entites
    if "Yes" == results[2].to_s
      gp_ents = face.all_connected
      gp_ents.concat @edges
      gp = ents.add_group gp_ents
      gp.name= 'dline'
      sel.add gp
    end
    model.commit_operation
    
  end # end of dline
  
  def self.build_ui()
    UI.menu.add_item("Width Line") { WidthLine.new.width_line }
  end
  
end # class WidthLine

end # module BFZH

#=begin
unless file_loaded?(__FILE__)
  BFZH::WidthLine.build_ui
  file_loaded(__FILE__)
end
#=end

=begin
BFZH::WidthLine.new.width_line
=end



