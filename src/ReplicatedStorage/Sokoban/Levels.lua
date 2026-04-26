--!strict
--[[ Microban-style levels (small, suitable for a demo). ]]

export type Level = {
	name: string,
	map: string,
}

local Levels: { Level } = {
	{
		name = "Tutorial",
		map = [[
    #####
    #...#
    #@$ #
  ###$  #
  #  $  #
  #  $  #
  ###. ###
    #  ###
    ####
]],
	},
	{
		name = "Corners",
		map = [[
  #######
  #     #
  # .$. #
  # $@$ #
  # .$. #
  #     #
  #######
]],
	},
	{
		name = "Hallway",
		map = [[
########
#      #
# .$$$@#
#      #
########
]],
	},
	{
		name = "Four rooms",
		map = [[
  #######
  #  $  #
### # $ #
#.$ @ $.#
# $ # ###
#  $  #
#######
]],
	},
}

return Levels
