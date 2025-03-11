-- for reference
--[[
function Serialization:LoadDownloadedData()
	local minDiscoveryDay = -math.huge
	if Harvest.GetMaxTimeDifference() > 0 then
		local currentDay = GetTimeStamp() / (60 * 60 * 24)
		minDiscoveryDay = currentDay - Harvest.GetMaxTimeDifference() / 24
	end

	local mapCache = self.mapCache
	local pinTypeId = self.pinTypeId

	local x1, x2, y1, y2, d1, d2
	local worldX, worldY, worldZ, discoveryDay

	local numAddedNodes = 0
	local downloadedData = self.downloadedData
	assert(#downloadedData % 8 == 0)
	for dataIndex = 1, #downloadedData, 8 do
		x1, x2, y1, y2, z1, z2, d1, d2 = downloadedData:byte(dataIndex, dataIndex+7)

		discoveryDay = d1 * 256 + d2
		if discoveryDay >= minDiscoveryDay then
			worldX = (x1 * 256 + x2) * 0.2
			worldY = (y1 * 256 + y2) * 0.2
			worldZ = (z1 * 256 + z2) * 0.2
			mapCache:Add(pinTypeId, worldX, worldY, worldZ)
			numAddedNodes = numAddedNodes + 1
		end
	end

	self:Debug("added %d nodes", numAddedNodes)

	return numAddedNodes
end

-- ----------------------------------------------------------------------------

local pinTypeId, mapCache

mapCache:InitializePinType(pinTypeId)
local mapMetaData = mapCache.mapMetaData
local map = mapMetaData.map

local submodule = SubmoduleManager:GetSubmoduleForMap(map)
local downloadedVars = submodule.downloadedVars
self.downloadedData = downloadedVars[zoneId][map][pinTypeId]
]]