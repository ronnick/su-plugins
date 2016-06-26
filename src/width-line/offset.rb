=begin rdoc

= Offset.rb
Copyright 2004,2005,2006,2009 by Rick Wilson - All Rights Reserved

== Disclaimer
THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

== License
This software is distributed under the Smustard End User License Agreement
http://www.smustard.com/eula

== Information
Author:: Rick Wilson
Organization:: Smustard
Name:: offset.rb
Version:: 2.201
SU Version:: 4.0
Date:: 2010-10-15
Description:: Offset edges of a selected face (new method for class Sketchup::Face)

Usage::
* 1:: Intended for developers as a method to call from within a script.  Add a "require 'offset.rb'" line right after the "require 'sketchup.rb'" line.  Developers may distribute with their scripts since not everyone will have this already, but best to link to http://www.smustard.com/script/offset for the most current version.  Returns the face created by the offset, or 'nil' if no face can be created.
* 2:: ArcCurve.offset(dist) -- if dist is (+), offsets outside the curve (larger radius); if dist is (-), offsets inside the curve (smaller radius).
* 3:: Curve.offset(dist) -- if dist is (+), offsets to the right of the curve (relative to the first segment direction and plane); if dist is (-), offsets to the left of the curve.

History::
* 2.201:: 2010-10-15
* fixed Face.offset(dist) bug that prevented some faces from being offset
* 2.200:: 2009-02-05
* added point analysis tools and error trapping to the face.offset method
* 2.100:: 2006-06-28
* changed the face creation to parent.entities.add_face to allow for correct creation regardless of nested status
* 2.000:: 2005-08-12
* added offset methods for ArcCurve and Curve objects
* 1.000:: 2004-09-07
* first version

=end


class Sketchup::Face
	def offset(dist)
begin
		pi = Math::PI
		unless ((dist.class == Fixnum || dist.class == Float || dist.class == Length) && dist != 0)
			return nil
		end
		verts=self.outer_loop.vertices
		pts = []
		
		# CREATE ARRAY pts OF OFFSET POINTS FROM FACE
		
		0.upto(verts.length-1) do |a|
			vec1 = (verts[a].position-verts[a-(verts.length-1)].position).normalize
			vec2 = (verts[a].position-verts[a-1].position).normalize
			vec3 = (vec1+vec2).normalize
			if vec3.valid?
				ang = vec1.angle_between(vec2)/2
				ang = pi/2 if vec1.parallel?(vec2)
				vec3.length = dist/Math::sin(ang)
				t = Geom::Transformation.new(vec3)
				if pts.length > 0
					vec4 = pts.last.vector_to(verts[a].position.transform(t))
					if vec4.valid?
						unless (vec2.parallel?(vec4))
							t = Geom::Transformation.new(vec3.reverse)
						end
					end
				end
				
				pts.push(verts[a].position.transform(t))
			end
		end

		# CHECK FOR DUPLICATE POINTS IN pts ARRAY

		duplicates = []
		pts.each_index do |a|
			pts.each_index do |b|
				next if b==a
				duplicates<<b if pts[a]===pts[b]
			end
			break if a==pts.length-1
		end
		duplicates.reverse.each{|a| pts.delete(pts[a])}

		# CREATE FACE FROM POINTS IN pts ARRAY

		(pts.length > 2) ? (parent.entities.add_face(pts)) : (return nil)

rescue
	puts "#{self} did not offset: #{pts}"
	return nil
end
	end
end

class Array
  def offsetPoints(dist)
    #		return nil if dist==0
    pi=Math::PI
    unless ((dist.class == Fixnum || dist.class == Float || dist.class == Length) && dist != 0)
      return nil
    end
    verts=self
    pts=[]
    0.upto(verts.length-1) do |a|
      if verts[a-(verts.length-1)].class==Sketchup::Vertex
      pt2=verts[a-(verts.length-1)].position
      elsif verts[a-(verts.length-1)].class==Geom::Point3d
      pt2=verts[a-(verts.length-1)]
      else
        return nil
      end
      if verts[a-1].class==Sketchup::Vertex
      pt1=verts[a-1].position
      elsif verts[a-1].class==Geom::Point3d
      pt1=verts[a-1]
      else
        return nil
      end
      if verts[a].class==Sketchup::Vertex
      pt3=verts[a].position
      elsif verts[a].class==Geom::Point3d
      pt3=verts[a]
      else
        return nil
      end
      vec1=(pt3-pt2).normalize
      vec2=(pt3-pt1).normalize
      vec3=(vec1+vec2).normalize
      if vec3.valid?
        ang=vec1.angle_between(vec2)/2
        ang=pi/2 if vec1.parallel?(vec2)
        vec3.length=dist/Math::sin(ang)
        t=Geom::Transformation.new(vec3)
        if pts.length > 0
          unless (vec2.parallel?(pts.last.vector_to(verts[a].position.transform(t))))
            t=Geom::Transformation.new(vec3.reverse)
          end
        end
      pts.push(verts[a].position.transform(t))
      end
    end
    pts
  end

  def offset(dist)
    #		return nil if dist==0
    pi=Math::PI
    unless ((dist.class == Fixnum || dist.class == Float || dist.class == Length) && dist != 0)
      return nil
    end
    verts = self
    pts=[]
    0.upto(verts.length-1) do |a|
      vec1=(verts[a]-verts[a-(verts.length-1)]).normalize
      vec2=(verts[a]-verts[a-1]).normalize
      vec3=(vec1+vec2).normalize
      if vec3.valid?
        ang=vec1.angle_between(vec2)/2
        ang=pi/2 if vec1.parallel?(vec2)
        vec3.length=dist/Math::sin(ang)
        t=Geom::Transformation.new(vec3)
        if pts.length > 0
          unless (vec2.parallel?(pts.last.vector_to(verts[a].transform(t))))
            t=Geom::Transformation.new(vec3.reverse)
          end
        end
      pts.push(verts[a].transform(t))
      end
    end
    return pts
  end
end

 class Sketchup::ArcCurve
  def offset(dist)
    return nil if (dist == 0 || (dist.class !=Float && dist.class!=Fixnum && dist.class!=Length))
    radius=self.radius+dist.to_f
    #Sketchup.active_model.active_entities.add_arc self.center, self.xaxis, self.normal, radius, self.start_angle, self.end_angle, self.count_edges
    c=parent.entities.add_arc self.center, self.xaxis, self.normal, radius, self.start_angle, self.end_angle, self.count_edges
    c.first.curve
  end
end

class Sketchup::Curve
	def offset(dist)
		return nil if self.count_edges<2
		pi=Math::PI
	  unless ((dist.class == Fixnum || dist.class == Float || dist.class == Length) && dist != 0)
      return nil
		end
		verts=self.vertices
		pts=[]
		0.upto(verts.length-1) do |a|
			if a==0 #special case for start vertex
				model=self.model
				model.start_operation "offset"
				gp=model.active_entities.add_group
				gpents=gp.entities
				face=gpents.add_face(verts[0].position,verts[1].position,verts[2].position)
				zaxis=face.normal
				v=self.edges[0].line[1]
				f=dist/dist.abs
				t=Geom::Transformation.rotation(verts[0].position,zaxis,(pi/2)*f)
				vec3=v.transform(t)
				vec3.length=dist.abs
				pts.push(verts[0].position.transform(vec3))
				gp.erase!
				model.commit_operation
			elsif a==(verts.length-1) #special case for end vertex
				model=self.model
				model.start_operation "offset"
				gp=model.active_entities.add_group
				gpents=gp.entities
				face=gpents.add_face(verts[a].position,verts[a-1].position,verts[a-2].position)
				zaxis=face.normal
				v=self.edges[a-1].line[1]
				f=dist/dist.abs
				t=Geom::Transformation.rotation(verts[a].position,zaxis,(pi/2)*f)
				vec3=v.transform(t)
				vec3.length=dist.abs
				pts.push(verts[a].position.transform(vec3))
				gp.erase!
				model.commit_operation
			else
				vec1=(verts[a].position-verts[a-(verts.length-1)].position).normalize
				vec2=(verts[a].position-verts[a-1].position).normalize
				vec3=(vec1+vec2).normalize
				if vec3.valid?
					ang=vec1.angle_between(vec2)/2
					ang=pi/2 if vec1.parallel?(vec2)
					vec3.length=dist/Math::sin(ang)
					t=Geom::Transformation.new(vec3)
					if pts.length > 0
						unless (vec2.parallel?(pts.last.vector_to(verts[a].position.transform(t))))
							t=Geom::Transformation.new(vec3.reverse)
						end
					end
					pts.push(verts[a].position.transform(t))
				end
			end
		end
		#Sketchup.active_model.active_entities.add_curve(pts)
		c=parent.entities.add_curve(pts)
		c.first.curve
	end
end
