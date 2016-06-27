require "offset.rb"

model = Sketchup.active_model
ents = model.entities
sel = model.selection
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

vect1 = sel[0].end.position - sel[0].start.position
vect2 = sel[1].end.position - sel[1].start.position
vect_fa = (vect1.cross vect2).normalize

all_one_face = true

for i in (1...sel.length-1)
  vect3 = sel[i].end.position - sel[i].start.position
  vect4 = sel[i+1].end.position - sel[i+1].start.position
  v_f = (vect3.cross vect4).normalize
  unless v_f.parallel? vect_fa
    all_one_face = false
  break
  end
end
