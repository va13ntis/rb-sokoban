--!strict
--[[ Microban-style levels (small, suitable for a demo). ]]

export type Level = {
	name: string,
	map: string?,
	floors: { string }?,
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
	{
		name = "Spiral push",
		map = [[
#########
#@  #   #
# $ # # #
# #   # #
# ### # #
#   .   #
#########
]],
	},
	{
		name = "Box lanes",
		map = [[
##########
#@   $   #
# ## ##  #
# .. $$  #
#    ##  #
##########
]],
	},
	{
		name = "Two floors intro",
		floors = {
			[[
########
#@  ^  #
# $ .  #
########
]],
			[[
########
#  v  .#
#  $   #
########
]],
		},
	},
	{
		name = "Ladder transfer",
		floors = {
			[[
#########
#@  H   #
# $$ .  #
#########
]],
			[[
#########
# . h . #
#   $   #
#########
]],
		},
	},
	{
		name = "Three floor drop",
		floors = {
			[[
#########
#@ ^ H  #
# $ .   #
#########
]],
			[[
#########
# v h   #
#   $ . #
#########
]],
			[[
#########
#   v . #
#   $   #
#########
]],
		},
	},
}

return Levels
