---@diagnostic disable: undefined-global, undefined-field, trailing-space

---------------------------------------------------
--                    Imports                    --
---------------------------------------------------

local server = require("helpers.remotes")
local ui = require("helpers.ui")
local pages = {
	collection = require("helpers.pages.collection")
}

---------------------------------------------------
--                     Setup                     --
---------------------------------------------------

local itemList = server.getItems()

table.sort(itemList, function (a, b)
	if a.count ~= b.count then
		return a.count > b.count
	end
	
	-- Sort alphabetically
	return string.lower(a.displayName) < string.lower(b.displayName) -- You can just do that!?!?
end)

---------------------------------------------------
--       The stuff that will actually run        --
---------------------------------------------------

local currentSelection = 1

while true do
	term.clear()
	pages.collection.draw(itemList, currentSelection)
	
	-- Wait for a key press event
	local _, param = os.pullEvent("key")
	
	-- Check which key was pressed
	if param == keys.q then
		pages.collection.infoLog("Quitting program.")
		break
	elseif param == keys.r then
		pages.collection.infoLog("Rebooting.")
		os.reboot()
	elseif param == keys.up then
		currentSelection = pages.collection.navagate.up(itemList, currentSelection)
	elseif param == keys.down then
		currentSelection = pages.collection.navagate.down(itemList, currentSelection)
	elseif param == keys.left then
		currentSelection = pages.collection.navagate.left(itemList, currentSelection)
	elseif param == keys.right then
		currentSelection = pages.collection.navagate.right(itemList, currentSelection)
	elseif param == keys.f then
		server.emptyPocket()
		pages.collection.infoLog("Emptied the pocket")
	elseif param == keys.enter then
		server.requestItem(itemList[currentSelection])
		pages.collection.infoLog("Requested "..itemList[currentSelection].displayName)
--	else
--		pages.collection.infoLog("Key code pressed: " .. keys.getName(param))
	end
end

term.clear()
term.setCursorPos(1, 1)