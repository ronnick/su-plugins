# Common use for ine plugins

module BFZH

# common operation for lines
class Common4Line
  
  # constructor
  def initialize
    @vect_fa = nil
  end
  
  # Filter edges from the selected entities
  def get_edges(sel)
    edges = sel.select { |e| e.is_a? Sketchup::Edge }
  end
  
  # Get all vertices from selected edges
  def get_all_vertices(edges)
    all_vertices = []
    edges.each do |e|
      all_vertices.concat e.vertices
    end
    return all_vertices
  end
  
  # Statistic the count of each vertex
  def count_vertex(vertices)
    vertices_cnt = Hash.new
    # count the vertices
    vertices.each do |e|
      if vertices_cnt.has_key?(e)
        vertices_cnt[e] += 1
      else
        vertices_cnt.store e, 1
      end
    end
    return vertices_cnt
  end
  
  # Judge whether all the edges are connected
  def is_all_connected(vertices_cnt)
    start_vertices_cnt = vertices_cnt.select { |k, v| v == 1 }
    return (2 == start_vertices_cnt.length)
  end
  
  # find start vertex
  def find_start_vertex(vertices_cnt)
    start_vertices_cnt = vertices_cnt.select { |k, v| v == 1 }
    return start_vertices_cnt.keys[0]
  end
  
  # Sort vertices from one start to the relative end
  def sort_vertices(edges, start_vertex)
    sorted_vertices = []
    sorted_vertices << start_vertex
    start_edge = edges.select { |e| e.vertices.include? start_vertex }[0]
    conn_vertex = start_edge.other_vertex start_vertex
    sorted_vertices << conn_vertex
    
    conn_edge = nil
    begin
      conn_edge = get_connected_edge edges, start_edge, conn_vertex
      if nil == conn_edge
        break
      else
        conn_vertex = conn_edge.other_vertex conn_vertex
        sorted_vertices << conn_vertex
        start_edge = conn_edge
      end
    end while true
=begin
    ents = Sketchup.active_model.entities
    for i in 0...sorted_vertices.length do
      ents.add_text "spt#{i}", sorted_vertices[i]
    end
=end
    return sorted_vertices
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
  
  # get the normal line
  def vect_fa
    @vect_fa
  end
  
  # Judge whether all edges are on one face
  def is_all_one_face(edges)
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
  end # is_all_one_face
  
end # class Common4Line

end # module BFZH




