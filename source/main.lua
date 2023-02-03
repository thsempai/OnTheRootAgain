import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "game"


local gfx <const> = playdate.graphics
local pd <const> = playdate


math.randomseed(playdate.getSecondsSinceEpoch())

pd.graphics.setBackgroundColor(gfx.kColorBlack)

local function initialize()


end

initialize()

function playdate.update()
	gfx.sprite.update()
	pd.timer.updateTimers()

end
