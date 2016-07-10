module BFZH

class PathSplit

  def initialize()
    @edge_pair_u = []
    @edge_pair_d = []
    @pt_split_s = []
    @pt_split_l = []
  end  

  def get_edge_pairs(face)
    edges = face.outer_loop.edges
    elen = edges.length 
    len = elen / 2 - 1
    for i in 0...len do
      @edge_pair_u << edges[i]
      @edge_pair_d << edges[elen - i - 2]
    end
  end
  
  def split_path(dist)
    len = @edge_pair_d.length
    left_dist = 0
    move_dist = dist
    bdshort = false
    for i in 0...len do
      short_edge = nil
      long_edge = nil
      
      vect = @edge_pair_u[i].start.position - @edge_pair_u[i].end.position
      vect.length = dist
      
      if @edge_pair_u[i].length > @edge_pair_d.length
        bdshort = true
        short_edge = @edge_pair_d[i]
        long_edge = @edge_pair_u[i]
      else
        bdshort = false
        short_edge = @edge_pair_u[i]
        long_edge = @edge_pair_d[i]
      end
      
      spt = nil
      ept = nil
      if bdshort
        spt = @edge_pair_d[i].end.position
        ept = @edge_pair_d[i].start.position
      else
        spt = @edge_pair_u[i].start.position
        ept = @edge_pair_u[i].end.position
      end
      
      pp_dist = short_edge.length
#=begin
      if pp_dist >= move_dist
        vect.length = move_dist
        pt = spt.offset vect
        @pt_split_s << pt
        ppt = pt.project_to_line long_edge.line
        @pt_split_l << ppt
        pp_dist = ept.distance pt
        if pp_dist < dist
          left_dist = pp_dist
          move_dist = dist - left_dist
        else
          left_dist = 0
          move_dist = dist
          spt = pt
        end
      end # end of split one edge while
#=end      
    end # end of split all edges

    @pt_split_l
=begin   
    # draw split line
    mod = Sketchup.active_model
    ents = mod.entities
    mod.start_operation "draw_split_line", true
    for i in 0...@pt_split_s.length do
      ents.add_line @pt_split_s[i], @pt_split_l[i]
    end
    mod.commit_operation
=end  
  end

  def test()
    pt = get_split_point @edge_pair_d[0], @edge_pair_d[0].start.position, 100
    pt_p = pt.project_to_line @edge_pair_u[0].line
    Sketchup.active_model.entities.add_line pt, pt_p
  end
  
  def show()
    mod = Sketchup.active_model
    ents = mod.entities
    i = 0
    @edge_pair_u.each do |e|
      ents.add_text "pt#{i}", e.start.position
      i = i + 1
    end
  end
  
end



mod = Sketchup.active_model
ents = mod.entities
sel = mod.selection
s = PathSplit.new
s.get_edge_pairs(sel[0])
#s.show
s.split_path 1000.mm
#s.show
#pt = s.test
#ents.add_text "pt", pt
end