class Float
  def mm
    to_f
  end
  def cm
    mm*100.0
  end
  def inches
    mm*25.4
  end
end

class Fixnum
  def mm
    to_f
  end
  def cm
    mm*100.0
  end
  def inches
    mm*25.4
  end
end

class CNCGenerator
end

class GcodeGenerator < CNCGenerator
  attr_accessor :material
	attr_accessor :x, :y, :z
	attr_accessor :cut_depth_limit # Max depth the endmill can be embedded in the material per a cut
	attr_accessor :cut_speed_limit # Max cutting speed for the material in mm/sec

  RAPID     = 'G0'
  LINE      = 'G1'
  CLW_ARC   = 'G2'
  CCW_ARC   = 'G3'
  MODE_ABSOLUTE = 'G90'  
  MOVEMENT_FUNCTIONS = [RAPID,LINE]

  def initialize(&job)
    @x = @y = @z = 0
    g MODE_ABSOLUTE # Intentionally normalizing everything to absolute
    g RAPID, X:x, Y:y, Z:z
    self.instance_eval(&job) if job
    g RAPID, X:0, Y:0, Z:0
  end

  def g(code, args = {})

    args[:F] ||= material_feedrate if MOVEMENT_FUNCTIONS.include?(code)

    args.each do |k,v|
      next if v.nil?

      k = k.upcase
      code += ' %s%s' % [k, v]

      case k
        when :X then @x = v
        when :Y then @y = v
        when :Z then @z = v
      end
    end

    puts ' ' + code

    code
  end

  def retract
    g RAPID, Z:0
  end

  def insert(depth=material_depth, &block)
    g LINE, Z:depth
    
    if block
      yield block
      retract
    end
  end

  def jump_to(x=nil,y=nil)
    retract
    g RAPID, X: x, Y: y
  end

  def line(x=nil,y=nil,depth=nil)
    insert depth
    g LINE, X: x, Y: y
    retract
  end

  def rect(width, height, depth, options = {})
    start_x = @x
    start_y = @y
    start_z = @z

    # Adjust for the bit diameter
    if options[:negative]
      start_x += bit_diameter
      start_y += bit_diameter
    else
      width += bit_diameter
      height += bit_diameter
    end

    corner_radius = options[:corner_radius].to_f || nil

    if corner_radius && corner_radius != 0
      # Round rect      
      g RAPID, X:start_x+corner_radius
      g LINE, Z:start_z+depth # Insert

      g LINE, X:start_x+width-corner_radius
      g CCW_ARC, X:start_x+width, Y:start_y+corner_radius, I:0, J:corner_radius
      g LINE, Y:start_y+height-corner_radius
      g CCW_ARC, X:start_x+width-corner_radius, Y:start_y+height, I: -corner_radius, J: 0
      g LINE, X:start_x+corner_radius
      g CCW_ARC, X:start_x, Y:start_y+height-corner_radius, I: 0, J: -corner_radius
      g LINE, Y:start_x+corner_radius
      g CCW_ARC, X:start_x+corner_radius, Y:start_y, I: corner_radius, J: 0
      
    else
      # Simple rect
      g LINE, X:start_x+width
      g LINE, Y:start_y+height
      g LINE, X:start_x
      g LINE, Y:start_y
    end
  end

  def drill(x=nil,y=nil,depth=nil)
    jump_to x, y
    insert
    retract
  end

  def layers(layer_depth=material_layer_depth, total_depth=material_depth, &block)
    start_z = @z
    depth = 0
    while depth < total_depth
      depth += layer_depth
      yield depth
    end
  end
  
  def config(name)
    yml = YAML::load( File.open('config/'+name) )

    material.merge!(yml.material) if yml.material
    machine.merge!(yml.machine) if yml.machine
  end

  def right(d) y -d end
  def left(d) x -d end
  def down(d) y d end
  def up(d) y -d end
    
private
  def gxyz(x=nil,y=nil,z=nil)
    @x = x
    @y = y
    @y = z
    result = ''
    result += gx(x) if x
    result += gy(y) if y
    result += gz(z) if z
  end
  def gx(x)
    ' X%f' % @x = x
  end
  def gy(y)
    ' Y%f' % @y = y
  end
  def gz(z)
    ' Z%f' % @z = z
  end
  
  def material_feedrate
    2000
  end

  def material_depth
    1.cm
  end

  def material_layer_depth
    10.mm
  end
  
  def material_feedrate
    2200
  end

  def bit_diameter
    (1.0/8.0).inches
  end

  def bit_radius
    bit_diameter / 2
  end
end
