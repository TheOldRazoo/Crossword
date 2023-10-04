
import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'Utility/State'
import 'Utility/StateManager'
import 'utility'
import 'loadpuz'
import 'screen'
import 'states/StateStart'
import 'states/StatePlay'
import 'states/StatePuz'

stateStart = StateStart()
statePuz = StatePuz()
statePlay = StatePlay()
stateManager = StateManager(stateStart)

function playdate.update()
    playdate.timer.updateTimers()
    stateManager:getCurrentState():update()
end

function playdate.gameWillTerminate()
    if stateManager:getCurrentState() == statePlay then
        statePlay:savePuzzle()
    end
end