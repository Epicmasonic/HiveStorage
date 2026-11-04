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

local function reloadItemList()
	local selectedItem = modifiedItemList[currentSelection]
	
	itemList = server.getItems()
	modifiedItemList = data.copyTable(data.search(itemList, searchQuery))
	sort(modifiedItemList, sortMode)
	currentSelection = findItemSelection(modifiedItemList, selectedItem)
end

local function refreshLoop()
	while true do
		sleep(10) -- Not sure how long to wait between auto refreshing. If it's to short I'll DoS myself but if it's too long I'll be waiting forever...
		reloadItemList()
	end
end

local function inputLoop()
	while true do
		term.clear()
		if #modifiedItemList == 0 then
			modifiedItemList = data.copyTable(server.getItems())
			
			if #modifiedItemList == 0 then
				ui.infoLog("No items in storage!?")
				break
			end
		end
		pages.collection.draw(modifiedItemList, currentSelection)
		
		local _, key = os.pullEvent("key")
		if key == keys.q then
			ui.infoLog("Quitting program.")
			break
		elseif key == keys.r then
			ui.infoLog("Reloading items.")
			reloadItemList()
		elseif key == keys.up then
			currentSelection = pages.collection.navagate.up(modifiedItemList, currentSelection)
		elseif key == keys.down then
			currentSelection = pages.collection.navagate.down(modifiedItemList, currentSelection)
		elseif key == keys.left then
			currentSelection = pages.collection.navagate.left(modifiedItemList, currentSelection)
		elseif key == keys.right then
			currentSelection = pages.collection.navagate.right(modifiedItemList, currentSelection)
		elseif key == keys.s then
			-- So that the key you used to open the search bar doesn't get put into it as well
			local releasedKey
			repeat
				_, releasedKey = os.pullEvent("key_up")
			until releasedKey == keys.s
	
			term.setCursorPos(1, 1)
			write("Search: ")
			searchQuery = read(nil, searchHistory, nil, searchQuery)
			
			resultSize = #data.search(modifiedItemList, searchQuery)
			if resultSize == 0 then
				ui.infoLog("No items found...")
				searchQuery = ""
			else
				ui.infoLog("Found "..resultSize.." items!")
				table.insert(searchHistory, searchQuery)
			end
			
			reloadItemList()
		elseif key == keys.f then
			server.emptyPocket()
			ui.infoLog("Emptied the pocket.")
		elseif key == keys.enter then
			local requestedItem = modifiedItemList[currentSelection]
			
			-- So that the key you used to open the search bar doesn't get put into it as well
			local releasedKey
			repeat
				_, releasedKey = os.pullEvent("key_up")
			until releasedKey == keys.enter
	
			term.setCursorPos(1, 1)
			write("Amount: ")
			local requestedAmount = tonumber(read())
			
			server.requestItem(requestedItem, requestedAmount)
			if requestedAmount then
				ui.infoLog("Requested "..requestedAmount.."x "..requestedItem.displayName..".")
			else
				ui.infoLog("Requested "..requestedItem.displayName..".")
			end
			
			reloadItemList()
	--	else
	--		ui.infoLog("Key code pressed: " .. keys.getName(param))
		end
	end
end

parallel.waitForAny(refreshLoop, inputLoop)
term.clear()
term.setCursorPos(1, 1)
