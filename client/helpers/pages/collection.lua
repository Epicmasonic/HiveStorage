---@diagnostic disable: undefined-global, undefined-field, trailing-space

local ui = require("helpers.ui")

local function printItemOverview(line, width, name, amount, selected)
	if type(name) ~= "string" then name = textutils.serialize(name) end
	if selected then name = ">"..name end
	
	ui.borderedPrint(2, width, line + 2, ui.shortenString(name, width - 7).."|"..ui.shortenNumber(amount))
end

local function drawFullItemOverview(startX, startY, width, height, items, selected)
	ui.drawBorder(startX, startY, width, height)
	local pageSize = height - 2
	local currentPage = math.floor((selected - 1) / pageSize)
	local pageOffset = currentPage * pageSize
	
	local modifyedSelected = selected % pageSize
	if modifyedSelected == 0 then modifyedSelected = pageSize end
	
	for i = 1, pageSize do
		-- printItemOverview(i, width, textutils.serialize(modifyedSelected), 1, i == selected)
		local item = items[i + pageOffset]
		
		if item then
			printItemOverview(i, width, item.displayName, item.count, i == modifyedSelected)
		else
			printItemOverview(i, width, "", nil, false)
		end
	end
	
	term.setCursorPos(startX + 2, startY)
	write(" "..math.floor(selected / pageSize)+1 .." / "..math.floor(#items / pageSize)+1 .." ")
end

local function infoLog(message)
	if type(message) ~= "string" then message = textutils.serialize(message) end
	local screenWidth, screenHeight = term.getSize()
	
	term.setCursorPos(1, screenHeight)
	write(ui.shortenString(message, screenWidth))
	sleep(1)
end

local function navagateUp(itemList, selection)
	selection = selection - 1
	if selection <= 0 then selection = #itemList end

	return selection
end

local function navagateDown(itemList, selection)
	selection = selection + 1
	if selection > #itemList then selection = 1 end

	return selection
end

local function navagateLeft(itemList, selection)
	local _, screenHeight = term.getSize()
	local listHeight = screenHeight - 4
	
	selection = selection - listHeight
	if selection <= 0 then
		local lastPageSize = #itemList % listHeight
		if lastPageSize == 0 then lastPageSize = #itemList end
		selection = #itemList - lastPageSize + selection + listHeight
		if selection > #itemList then selection = #itemList end
	end
	
	return selection
end

local function navagateRight(itemList, selection)
	local _, screenHeight = term.getSize()
	local listHeight = screenHeight - 4
	
	selection = selection + listHeight
	if selection > #itemList then selection = selection % listHeight end
	
	return selection
end

return {
	draw = function(itemList, currentSelection)
		assert(type(itemList) == "table", "There's something wrong with your items? It should be a table, but it's a "..type(itemList).." for some reason.")
		assert(type(currentSelection) == "number", "I can't pick the "..textutils.serialize(currentSelection).."th item! Please use a number instead of a "..type(currentSelection)..".")
		assert(currentSelection >= 1 and currentSelection <= #itemList, "Your selection is out of bounds.")
		
		local screenWidth, screenHeight = term.getSize()
		drawFullItemOverview(2, 2, screenWidth - 2, screenHeight - 2, itemList, currentSelection)
	end,
	infoLog = infoLog,
	navagate = {
		up = navagateUp,
		down = navagateDown,
		left = navagateLeft,
		right = navagateRight
	}
}