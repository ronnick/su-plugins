def get_edges(sel)
  edges = sel.select { |e| e.is_a? Sketchup::Edge }
end

def is_all_connected(edges)
  is_connected = false
  if edges.length < 2
    is_connected = false
  else
    con_edges = edges[0].all_connected.select { |e| edges.include? e }
    is_connected = con_edges.length == edges.length
  end
  return is_connected
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



model = Sketchup.active_model
ents = model.entities
sel = model.selection

#all_one_face sel
sel_edges = get_edges sel
is_all_connected sel_edges



=begin
vect1 = sel[0].end.position - sel[0].start.position
vect2 = sel[1].end.position - sel[1].start.position
vect3 = vect1.cross vect2
vect4 = vect1.cross vect3
vect5 = vect4.normalize
vect5.length = 50

pt = sel[0].start.position.offset vect5

ents.add_line sel[0].start.position, pt

trans = Geom::Transformation.new vect5

ents.transform_entities trans, sel[]
=end
