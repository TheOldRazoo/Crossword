
--[[
    An interface class for the major states in the game.  This class doesn't
    implement any code but defines all the methods available to state classes
    which extend it.

    Bob Withers
    bwit@pobox.com
    06/10/2023
]]

import 'CoreLibs/object'

class('State').extends()

function State:update()
end

function State:enter(prevState)
end

function State:exit()
end
