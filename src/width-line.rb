require "sketchup.rb"

unless file_loaded?(__FILE__)
  file_loaded __FILE__
end

def get_edges(sel)
  edges = sel.select { |e| e.is_a? Sketchup::Edge }
end

def get_all_vertices(edges)
  all_vertices = []
  edges.each do |e|
    all_vertices.concat e.vertices
  end
  return all_vertices
end

def count_vertex(vertices)
  Hash vertices_cnt = Hash.new
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

def is_all_connected(vertices_cnt)
  start_vertices_cnt = vertices_cnt.select { |k, v| v == 1 }
  return (2 == start_vertices_cnt.length)
end

def find_start_vertex(vertices_cnt)
  start_vertices_cnt = vertices_cnt.select { |k, v| v == 1 }
  return start_vertices_cnt.keys[0]
end

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

def get_connected_edge(edges, edge, con_vertex)
  conn_edge = nil
  conn_edges= edges.select { |e| (e.vertices.include? con_vertex) && (e != edge) }
  if conn_edges.length > 0
    conn_edge = conn_edges[0]
  end
  return conn_edge
end

def all_one_face(edges)
  is_all_one_face = true
  # find normal vector of a face
  vect1 = edges[0].end.position - edges[0].start.position
  vect2 = edges[1].end.position - edges[1].start.position
  vect_fa = vect1.cross vect2
  # check other edges
  for i in (1...edges.length-1)
    vect1 = edges[i].end.position - edges[i].start.position
    vect2 = edges[i+1].end.position - edges[i+1].start.position
    v_fa = vect1.cross vect2
    unless v_fa.parallel? vect_fa
      is_all_one_face = false
      break
    end
  end # end of for
  return is_all_one_face
end # all_one_face


def double_line
   
  prompts = ["With(mm):"]
  defaults = ["50"]
  results = UI.inputbox prompts, defaults, "Please input double line width"
 
  wlen = results[0].to_i
  wlen = wlen.mm

  model = Sketchup.active_model
  ents = model.entities
  sel = model.selection
  
  #all_one_face sel
  sel_edges = get_edges sel
  if (all_one_face sel_edges)
    all_vertices = get_all_vertices sel_edges
    vertices_cnt = count_vertex all_vertices
    
    if is_all_connected vertices_cnt
      start_vertex = find_start_vertex vertices_cnt
      sorted_vertices = sort_vertices sel_edges,start_vertex
      
      # get the normal vector of the face.
      vect1 = sorted_vertices[1].position - sorted_vertices[0].position
      vect2 = sorted_vertices[2].position - sorted_vertices[1].position
      vect_fa = vect1.cross vect2
      
      positive_vertices = []
      negative_vertices = []
      # offset the start vertex
      vect4 = vect1.cross vect_fa
      vect4.length = wlen
      
      pt = sorted_vertices[0].position.offset vect4
      pt_n = sorted_vertices[0].position.offset vect4.reverse
      positive_vertices << pt
      negative_vertices << pt_n
      
      len = sorted_vertices.length
      # offset the connected vertices
      for i in 1...len-1 do
        vect_l = sorted_vertices[i].position - sorted_vertices[i-1].position
        vect_l_offset = vect_l.cross vect_fa
        vect_l_offset.length = wlen
        
        pt1 = sorted_vertices[i-1].position.offset vect_l_offset
        pt2 = sorted_vertices[i].position.offset vect_l_offset
        edge_l = [pt1, pt2]
        
        pt1_n = sorted_vertices[i-1].position.offset vect_l_offset.reverse
        pt2_n = sorted_vertices[i].position.offset vect_l_offset.reverse
        edge_l_n = [pt1_n, pt2_n]
        
        vect_r = sorted_vertices[i+1].position - sorted_vertices[i].position
        vect_r_offset = vect_r.cross vect_fa
        vect_r_offset.length = wlen
        
        pt1 = sorted_vertices[i].position.offset vect_r_offset
        pt2 = sorted_vertices[i+1].position.offset vect_r_offset
        edge_r = [pt1, pt2]
        
        pt1_n = sorted_vertices[i].position.offset vect_r_offset.reverse
        pt2_n = sorted_vertices[i+1].position.offset vect_r_offset.reverse
        edge_r_n = [pt1_n, pt2_n]
        
        pt_conn = Geom.intersect_line_line edge_l, edge_r
        pt_conn_n = Geom.intersect_line_line edge_l_n, edge_r_n
        
        positive_vertices << pt_conn
        negative_vertices << pt_conn_n
=begin
        vect_conn_offset = vect_l_offset + vect_r_offset
        pt = sorted_vertices[i].position.offset vect_conn_offset
        positive_vertices << pt
=end
      end
      #positive_vertices
      # offset the last vertex
    
      vector_last = sorted_vertices[len-1].position - sorted_vertices[len-2].position
      vect_last_offset = vector_last.cross vect_fa
      vect_last_offset.length = wlen
      
      pt = sorted_vertices[len-1].position.offset vect_last_offset
      positive_vertices << pt
      
      pt_n = sorted_vertices[len-1].position.offset vect_last_offset.reverse
      negative_vertices << pt_n
      
      all_new_vertices = positive_vertices.concat negative_vertices.reverse
      
      ents.add_face all_new_vertices
=begin 
      for i in 0...positive_vertices.length-1 do
        ents.add_line positive_vertices[i], positive_vertices[i+1]
        ents.add_line negative_vertices[i], negative_vertices[i+1]
      end
    
      # connect the start and end vertices
      ents.add_line positive_vertices[0], negative_vertices[0]
      ents.add_line positive_vertices[len-1], negative_vertices[len-1]
=end     
    else
      UI.messagebox "所有的线断未连接"
    end # end of if all connected
  else
    UI.messagebox "不在一个平面上"
  end # end of if on one face
  
end # end of dline

UI.menu.add_item("double line") { double_line }




