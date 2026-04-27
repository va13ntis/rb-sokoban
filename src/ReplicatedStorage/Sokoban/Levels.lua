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
		name = "Lift puzzle",
		floors = {
			[[
#########
#@  ^   #
# $$ .  #
#########
]],
			[[
#########
# . v . #
#   $   #
#########
]],
		},
	},
	{
		name = "Three floor relay",
		floors = {
			[[
#########
#@ ^    #
# $ .   #
#########
]],
			[[
#########
# v ^   #
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
