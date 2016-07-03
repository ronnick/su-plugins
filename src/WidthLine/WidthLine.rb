

module BFZH

class WidthLine
  # selected edges
  @edges = []
  @all_vertices = []
  @sorted_vertices = []
  @positive_vertices = []
  @negative_vertices = []
  @vertices_cnt = Hash.new
  @vect_fa = nil
  
  # constructor
  def initialize
    @edges = []
    @all_vertices = []
    @sorted_vertices = []
    @positive_vertices = []
    @negative_vertices = []
    @vertices_cnt = Hash.new
    @vect_fa = nil
  end
  
  # Filter edges from the selected entities
  def get_edges(sel)
    @edges = sel.select { |e| e.is_a? Sketchup::Edge }
  end
  
  # Get all vertices from selected edges
  def get_all_vertices(edges)
    edges.each do |e|
      @all_vertices.concat e.vertices
    end
  end
  
  # Statistic the count of each vertex
  def count_vertex(vertices)
    # count the vertices
    vertices.each do |e|
      if @vertices_cnt.has_key?(e)
        @vertices_cnt[e] += 1
      else
        @vertices_cnt.store e, 1
      end
    end
  end
  
  # Judge whether all the edges are connected
  def is_all_connected(vertices_cnt)
    start_vertices_cnt = vertices_cnt.select { |k, v| v == 1 }
    return (2 == start_vertices_cnt.length)
  end
  
  def find_start_vertex(vertices_cnt)
    start_vertices_cnt = vertices_cnt.select { |k, v| v == 1 }
    return start_vertices_cnt.keys[0]
  end
  
  # Sort vertices from one start to the relative end
  def sort_vertices(edges, start_vertex)
    @sorted_vertices << start_vertex
    start_edge = edges.select { |e| e.vertices.include? start_vertex }[0]
    conn_vertex = start_edge.other_vertex start_vertex
    @sorted_vertices << conn_vertex
    
    conn_edge = nil
    begin
      conn_edge = get_connected_edge edges, start_edge, conn_vertex
      if nil == conn_edge
        break
      else
        conn_vertex = conn_edge.other_vertex conn_vertex
        @sorted_vertices << conn_vertex
        start_edge = conn_edge
      end
    end while true
=begin
    ents = Sketchup.active_model.entities
    for i in 0...@sorted_vertices.length do
      ents.add_text "spt#{i}", @sorted_vertices[i]
    end
=end
  end
  
  # Get the connected egde from the selected edges
  def get_connected_edge(edges, edge, con_vertex)
    conn_edge = nil
    conn_edges= edges.select { |e| (e.vertices.include? con_vertex) && (e != edge) }
    if conn_edges.length > 0
      conn_edge = conn_edges[0]
    end
    return conn_edge
  end
  
  # Judge whether all edges are on one face
  def all_one_face(edges)
    is_all_one_face = true
    # check other edges
    for i in (0...edges.length-1)
      vect1 = edges[i].end.position - edges[i].start.position
      vect2 = edges[i+1].end.position - edges[i+1].start.position
      v_fa = vect1.cross vect2
      # avoid connected parallel edges
      unless 0 == v_fa.length
        if @vect_fa != nil
          unless v_fa.parallel? @vect_fa
            is_all_one_face = false
            break
          end
        else
          @vect_fa = v_fa
        end
      end
      
    end # end of for
    
    return is_all_one_face
  end # all_one_face
  
  # Main interface to draw width line
  def width_line
    model = Sketchup.active_model
    ents = model.entities
    sel = model.selection
  
    #all_one_face sel
    get_edges sel
    if @edges.length < 2
      UI.messagebox "Please select at least 2 connected edges"
      return
    end
    if all_one_face @edges
      get_all_vertices @edges
      count_vertex @all_vertices
      
      if is_all_connected @vertices_cnt
        # judge all edges are parallel
        unless @vect_fa
          UI.messagebox "All edges are connected and parallel"
          return
        end
        # create parameters inputbox
        prompts = ["With(mm):"]
        defaults = ["500"]
        results = UI.inputbox prompts, defaults, "Please input double line width"
        # convert the parameters string
        wlen = results[0].to_i
        wlen = wlen / 2
        wlen = wlen.mm
        
        start_vertex = find_start_vertex @vertices_cnt
        sort_vertices @edges, start_vertex
        
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
        ents.add_face all_new_vertices     
      else
        UI.messagebox "所有的线段未连续连接"
      end # end of if all connected
      
    else
      UI.messagebox "所有的线段不在一个平面上"
    end # end of if on one face
    
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



