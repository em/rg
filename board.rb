#!/usr/bin/env ruby

require_relative 'lib/general.rb'

GcodeGenerator.new do
  margin = 10
  mini_itx_width = 500
  sheet_width = mini_itx_width + margin*2
  sheet_height = 200 + margin*2
  sheet_depth = 0.5

  mount_holes = [
    [12,23],
    [45,66]
  ]

  #jump_to 10,10

  line 10.cm, 0, -0.5.cm
  
  #rect 10.cm, 10.cm, -0.8.cm, corner_radius:2.cm

  # mount_holes.each do |h| 
  #   drill(*h)
  # end
end
