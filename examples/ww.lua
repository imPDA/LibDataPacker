local Log = LibDataPacker_Logger()

local LDP = LibDataPacker
LDP.examples = LDP.examples or {}
LDP.examples.WW = {}

local example = LDP.examples.WW

-- ----------------------------------------------------------------------------

local WW = WizardsWardrobe

-- ----------------------------------------------------------------------------

--- https://stackoverflow.com/questions/20325332/how-to-check-if-two-tablesobjects-have-the-same-value-in-lua
--- @param o1 any|table First object to compare
--- @param o2 any|table Second object to compare
--- @param ignore_mt boolean True to ignore metatables (a recursive function to tests tables inside tables)
local function equals(o1, o2, ignore_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or equals(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

-- ----------------------------------------------------------------------------

-- function WW.SaveGear( setup )
local function getGear()
    local gearTable = { mythic = nil }

    for _, gearSlot in ipairs( WW.GEARSLOTS ) do
        gearTable[ gearSlot ] = {
            id = Id64ToString( GetItemUniqueId( BAG_WORN, gearSlot ) ),
            link = GetItemLink( BAG_WORN, gearSlot, LINK_STYLE_DEFAULT ),
        }
        if WW.IsMythic( BAG_WORN, gearSlot ) then
            gearTable.mythic = gearSlot
        end
        if GetItemLinkItemType( gearTable[ gearSlot ].link ) == ITEMTYPE_TABARD then
            gearTable[ gearSlot ].creator = GetItemCreatorName( BAG_WORN, gearSlot )
        end
    end

    return {
        GetGearInSlot = function(slot)
            return gearTable[slot]
        end
    }
end


local indexedTableOfItems = {}
do
    for item, ability in pairs(WW.BUFFFOOD) do
        indexedTableOfItems[#indexedTableOfItems+1] = item
    end
    table.sort(indexedTableOfItems)
end

local function collectData()
    local data = {}
    data.decimal = {}
    data.raw = {}

    -- GEAR -------------------------------------------------------------------
    local gear = getGear()
    data.decimal.gear = {}
    data.raw.gear = {}

    for _, gearSlot in ipairs( WW.GEARSLOTS ) do
		if gearSlot ~= EQUIP_SLOT_COSTUME then
			local gearPiece = gear.GetGearInSlot( gearSlot ) or { id = "0", link = "" }

			local link = gearPiece.link
			local itemId = GetItemLinkItemId( link )
            local traitId = GetItemLinkTraitInfo( link )

            table.insert( data.decimal.gear, {string.format( "%06d", itemId ), WW.PREVIEW.TRAITS[ traitId ] } )
			table.insert( data.raw.gear, {itemId, traitId} )
		end
	end

    -- SKILLS -----------------------------------------------------------------
    local skillTable = {}
    skillTable.decimal = {}
    skillTable.raw = {}

	for hotbarCategory = 0, 1 do
		skillTable.decimal[ hotbarCategory ] = {}
		skillTable.raw[ hotbarCategory+1 ] = {}
		for slotIndex = 3, 8 do
			local hotbarData = ACTION_BAR_ASSIGNMENT_MANAGER:GetHotbar( hotbarCategory )
			local slotData = hotbarData:GetSlotData( slotIndex )
			local abilityId = 0
			-- Cant save cryptcanons special ult.
			if slotData.abilityId == 195031 then
				abilityId = slotData.abilityId
			elseif
				not slotData:IsEmpty() then -- check if there is even a spell
				if abilityId == 39012 or abilityId == 39018 or abilityId == 39028 then
					abilityId = 39011
				end
				abilityId = slotData:GetEffectiveAbilityId()
			end

			skillTable.decimal[ hotbarCategory ][ slotIndex ] = string.format( "%06d", abilityId )
			skillTable.raw[ hotbarCategory+1 ][ slotIndex-2 ] = abilityId
		end
	end

    data.decimal.skills = skillTable.decimal
    data.raw.skills = skillTable.raw

    -- CP ---------------------------------------------------------------------
    data.decimal.stars = {}
    data.raw.stars = {}

    for slotIndex = 1, 12 do
        local cpId = GetSlotBoundId(slotIndex, HOTBAR_CATEGORY_CHAMPION) or 0

		table.insert( data.decimal.stars, string.format( "%03d", cpId ) )
		table.insert( data.raw.stars, cpId )
	end

    -- FOOD -------------------------------------------------------------------
    local foodIndex
    if not foodIndex then
		local currentFood = WW.HasFoodRunning()
		local foodChoice = WW.lookupBuffFood[ currentFood ]
		foodIndex = WW.FindFood( foodChoice )
	end

	local foodLink = GetItemLink( BAG_BACKPACK, foodIndex, LINK_STYLE_DEFAULT )
	local foodId = GetItemLinkItemId( foodLink )

    data.decimal.food = WW.PREVIEW.FOOD[ foodId ]
    data.raw.food = foodId

    return data
end

-- ----------------------------------------------------------------------------

local function WWExample()
    local Field = LDP.Field

    local IGNORE_NAMES = true
    local INVERTED = true

    local gearPiece = Field.Table('gear piece', {
        Field.Number('itemId', 20),
        Field.Number('traitId', 6),
    }, IGNORE_NAMES)

    local skillBar = Field.Array('bar', 6, Field.Number('skill id', 20))
    local foodEnum = Field.Enum('food', indexedTableOfItems, INVERTED)
    example.foodEnum = foodEnum

    local schema = Field.Table(nil, {
        Field.Array('gear', 16, gearPiece),
        Field.Array('skills', 2, skillBar),
        Field.Array('stars', 12, Field.Number(nil, 14)),
        -- Field.Number('food', 20),  -- enum saves 2 characters
        foodEnum,
    })

    local data = collectData()

    example.data = data

    if Zgoo then
        Zgoo.CommandHandler('LibDataPacker.examples.WW')
    end

    example.base64string = LDP.Pack(data.raw, schema)
    Log('Base64 string: %s', example.base64string)

    example.base64stringLength = #example.base64string
    Log('Base64 string length: %s', #example.base64string)

    example.unpackedData = LDP.Unpack(example.base64string, schema)
    example.equals = equals(example.data.raw, example.unpackedData, false)

    if Zgoo then
        Zgoo.CommandHandler('LibDataPacker.examples.WW')
    end
end

example.run = function()
    if not WizardsWardrobe then return end
    WWExample()
end

do
    zo_callLater(example.run, 1000)
end