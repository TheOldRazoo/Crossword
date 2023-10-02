
import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'Utility/State'
import 'Utility/StateManager'
import 'loadpuz'
import 'screen'
import 'utility'
import 'states/StateStart'
import 'states/StatePlay'
import 'states/StatePuz'

local firstTime = true

stateStart = StateStart()
statePuz = StatePuz()
statePlay = StatePlay()
stateManager = StateManager(stateStart)

function playdate.update()
    if firstTime then
        firstTime = false
    end

    playdate.graphics.sprite.update()
    stateManager:getCurrentState():update()
end