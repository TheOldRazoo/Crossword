
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

stateStart = StateStart()
statePuz = StatePuz()
statePlay = StatePlay()
stateManager = StateManager(stateStart)

function playdate.update()
    -- playdate.graphics.sprite.update()
    stateManager:getCurrentState():update()
end

function playdate.gameWillTerminate()
    if stateManager:getCurrentState() == statePlay then
        statePlay:savePuzzle()
    end
end