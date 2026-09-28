---@diagnostic disable: undefined-global, undefined-field, trailing-space

---------------------------------------------------
--                    Imports                    --
---------------------------------------------------

local server = require("helpers.remotes")
local data = require("helpers.dataHandling")
local ui = require("helpers.ui")
local pages = {
	collection = require("helpers.pages.collection")
}

---------------------------------------------------
--                     Setup                     --
---------------------------------------------------

local itemList = server.getItems()
local modifiedItemList = data.copyTable(itemList) -- A copy of  `itemList` so the original can stay save while searching and whatever else I may add
data.sort.byAmount(modifiedItemList)

local function sort(itemList, sortType)
	if sortType == "amount" then
		data.sort.byAmount(itemList)
	end
end

local function findItemSelection(itemList, selectedItem)
	if not selectedItem then return 1 end

	for index, item in ipairs(itemList) do
		if item.name == selectedItem.name then
			return index
		end
	end

	return 1
end

---------------------------------------------------
--       The stuff that will actually run        --
---------------------------------------------------

local currentSelection = 1
local sortMode = "amount"
local searchQuery = ""
local searchHistory = {}

while true do
	term.clear()
	pages.collection.draw(modifiedItemList, currentSelection)
	
	local _, key = os.pullEvent("key")
	if key == keys.q then
		ui.infoLog("Quitting program.")
		break
	elseif key == keys.r then
		ui.infoLog("Rebooting.")
		os.reboot()
	elseif key == keys.up then
		currentSelection = pages.collection.navagate.up(modifiedItemList, currentSelection)
	elseif key == keys.down then
		currentSelection = pages.collection.navagate.down(modifiedItemList, currentSelection)
	elseif key == keys.left then
		currentSelection = pages.collection.navagate.left(modifiedItemList, currentSelection)
	elseif key == keys.right then
		currentSelection = pages.collection.navagate.right(modifiedItemList, currentSelection)
	elseif key == keys.s then
		-- So that the s you used to open the search bar doesn't get put into it as well
		local releasedKey
		repeat
			_, releasedKey = os.pullEvent("key_up")
		until releasedKey == keys.s

		term.setCursorPos(1, 1)
		write("Search: ")
		searchQuery = read(nil, searchHistory, nil, searchQuery)
		table.insert(searchHistory, searchQuery)
		
		local selectedItem = modifiedItemList[currentSelection]
		modifiedItemList = data.search(itemList, searchQuery)
		sort(modifiedItemList, sortMode)
		
		currentSelection = findItemSelection(modifiedItemList, selectedItem)
	elseif key == keys.f then
		server.emptyPocket()
		ui.infoLog("Emptied the pocket")
	elseif key == keys.enter then
		server.requestItem(modifiedItemList[currentSelection])
		ui.infoLog("Requested "..modifiedItemList[currentSelection].displayName)
--	else
--		ui.infoLog("Key code pressed: " .. keys.getName(param))
	end
end

term.clear()
term.setCursorPos(1, 1)