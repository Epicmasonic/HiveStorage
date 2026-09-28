---@diagnostic disable: undefined-global, undefined-field, trailing-space

local function copyTable(table)
	local copy = textutils.serialise(table)
	return textutils.unserialise(copy)
end

local function sortByAmount(itemList)
	table.sort(itemList, function (a, b)
		if a.count ~= b.count then
			return a.count > b.count
		end
		
		-- Sort alphabetically
		return string.lower(a.displayName) < string.lower(b.displayName) -- You can just do that!?!?
	end)
end

local function splitItemId(itemId)
	return string.match(itemId, "([^:]+):(.+)")
end

local function search(itemList, query)
	query = string.lower(query)
	local firstChar = string.sub(query, 1, 1)
	local result = {}
	
	if firstChar == "@" then
		query = string.sub(query, 2)
		for _, item in ipairs(itemList) do
			local modName, _ = splitItemId(item.name)
			if string.find(modName, query) then
				table.insert(result, item)
			end
		end
	elseif firstChar == "#" then
		
	else
		for _, item in ipairs(itemList) do
			local itemName = string.lower(item.displayName)
			if string.find(itemName, query) then
				table.insert(result, item)
			end
		end
	end
	
	return result
end

return {
	copyTable = copyTable,
	sort = {
		byAmount = sortByAmount
	},
	search = search
}