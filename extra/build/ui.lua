local Build = LibDataPacker.Extra.Build

local SLOT_NAMES = {
    [EQUIP_SLOT_HEAD]           = 'Head',       -- 0  
    [EQUIP_SLOT_CHEST]          = 'Chest',      -- 2
    [EQUIP_SLOT_SHOULDERS]      = 'Shoulders',  -- 3
    [EQUIP_SLOT_HAND]           = 'Hand',       -- 16
    [EQUIP_SLOT_WAIST]          = 'Waist',      -- 6
    [EQUIP_SLOT_LEGS]           = 'Legs',       -- 8
    [EQUIP_SLOT_FEET]           = 'Feet',       -- 9

    [EQUIP_SLOT_NECK]           = 'Neck',       -- 1
    [EQUIP_SLOT_RING1]          = 'Ring',       -- 11
    [EQUIP_SLOT_RING2]          = 'Ring',       -- 12

    [EQUIP_SLOT_MAIN_HAND]      = 'Front (R)',  -- 4
    [EQUIP_SLOT_OFF_HAND]       = 'Front (L)',  -- 5

    [EQUIP_SLOT_BACKUP_MAIN]    = 'Back (R)',   -- 20
    [EQUIP_SLOT_BACKUP_OFF]     = 'Back (L)',   -- 21
}

function LibDataPacker_Build_InitializeGearSlots(control)
    local previousGearSlotControl

    for _, gearSlot in ipairs(Build.GEAR_SLOTS) do
        local gearSlotControl = CreateControlFromVirtual('$(parent)Slot', control, 'LibDataPacker_Build_GearPeaceTemplate', gearSlot)
        gearSlotControl:GetNamedChild('SlotName'):SetText(SLOT_NAMES[gearSlot])

        if previousGearSlotControl then
            gearSlotControl:SetAnchor(TOPLEFT, previousGearSlotControl, BOTTOMLEFT)
        end

        previousGearSlotControl = gearSlotControl
    end
end

local function GetItemLinkQualityColor(itemLink)
    return GetItemQualityColor(GetItemLinkDisplayQuality(itemLink)):UnpackRGBA()
end

local ARMOR_TYPE_COLOR = {
    [ARMORTYPE_NONE]    = {1, 1, 1},
    [ARMORTYPE_HEAVY]   = {1, 0, 0},
    [ARMORTYPE_MEDIUM]  = {0, 1, 0},
    [ARMORTYPE_LIGHT]   = {0, 0, 1},
}

local function GetArmorTypeColor(armorType)
    return unpack(ARMOR_TYPE_COLOR[armorType])
end

-- ----------------------------------------------------------------------------

local function LayoutGearSlot(slotControl, itemLink)
    local armorType = GetItemLinkArmorType(itemLink)
    slotControl:GetNamedChild('SlotName'):SetColor(GetArmorTypeColor(armorType))

    local level = GetItemLinkRequiredLevel(itemLink)
    local CPPoints = GetItemLinkRequiredChampionPoints(itemLink)

    if CPPoints > 0 then
        slotControl:GetNamedChild('Level'):SetText(CPPoints)
        slotControl:GetNamedChild('CPIcon'):SetHidden(false)
    else
        slotControl:GetNamedChild('Level'):SetText(level)
        slotControl:GetNamedChild('CPIcon'):SetHidden(true)
    end

    slotControl:GetNamedChild('GearName'):SetText(GetItemLinkName(itemLink))
    slotControl:GetNamedChild('GearName'):SetColor(GetItemLinkQualityColor(itemLink))

    local trait = GetItemLinkTraitInfo(itemLink)
    slotControl:GetNamedChild('Trait'):SetText(GetString("SI_ITEMTRAITTYPE", trait))

    -- local enchantmentSearchCategory = GetEnchantSearchCategoryType(gearPiece[4])
    -- slotControl:GetNamedChild('Enchantment'):SetText(GetString("SI_ENCHANTMENTSEARCHCATEGORYTYPE", enchantmentSearchCategory))

    local hasCharges, enchantHeader, enchantDescription = GetItemLinkEnchantInfo(itemLink)
    slotControl:GetNamedChild('Enchantment'):SetText(enchantHeader)
end

function LibDataPacker_Build_LayoutBuild(build)
    local GEAR_CONTROL = LibDataPacker_Build_TLCGear

    build = build or Build.GetLocalPlayerBuild()
    local gear = build[Build.GEAR]

    for slot, gearPiece in pairs(gear) do
        if gearPiece[1] ~= 0 then
            local itemLink = ('|H1:item:%i:%i:50:%i:370:50:%i:0:0:0:0:0:0:0:2049:9:0:1:0:2900:0|h|h'):format(gearPiece[1], 359 + gearPiece[2], gearPiece[4], gearPiece[3])

            local slotControl = GEAR_CONTROL:GetNamedChild('Slot' .. slot)
            slotControl.itemLink = itemLink

            LayoutGearSlot(slotControl, itemLink)
        end
    end
end

-- do
--     zo_callLater(function() LibDataPacker_Build_LayoutBuild() end, 2000)
-- end