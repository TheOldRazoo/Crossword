
import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'CoreLibs/crank'
import 'Utility/State'
import 'Utility/StateManager'
import 'utility'
import 'loadpuz'
import 'screen'
import 'music'
import 'options'
import 'states/StateStart'
import 'states/StatePlay'
import 'states/StatePuz'

local firstTime = true

loadOptions()

stateStart = StateStart()
statePlay = StatePlay()
stateManager = StateManager(stateStart)

function playdate.update()
    if firstTime then
        math.randomseed(playdate.getSecondsSinceEpoch())
        playdate.setMenuImage(getMenuImage())
        firstTime = false
    end

    playdate.timer.updateTimers()
    stateManager:getCurrentState():update()
end

function playdate.gameWillTerminate()
    if stateManager:getCurrentState() == statePlay then
        statePlay:savePuzzle()
    end

    saveOptions()
end
