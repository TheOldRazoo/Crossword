
import 'loadpuz'
import 'screen'
import 'utility'

local firstTime = true

function playdate.update()
    if firstTime then
        local puz, err = loadPuzzleFile('puz/uc230921.puz')
        puz.grid[1][1] = 'A'
        puz.grid[1][2] = 'B'
        puz.grid[2][1] = 'C'
        displayTitle(puz)
        drawBoard(puz)
        displayBoard()
        displayClue(puz, 1, 1, true)
        firstTime = false
    end
end