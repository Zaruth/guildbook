--[[

]]

local addonName, addon = ...;

local Tradeskills = addon.Tradeskills;
local L = addon.Locales;

addon.playerContainers = {};

local talentBackgroundToSpec = {
    ["DeathKnightBlood"] = "Blood",
    ["DeathKnightFrost"] = "Frost",
    ["DeathKnightUnholy"] = "Unholy",
    ["DruidBalance"] = "Balance",
    ["DruidFeralCombat"] = "Bear",
    ["DruidRestoration"] = "Restoration",
    ["HunterBeastMastery"] = "BeastMaster",
    ["HunterMarksmanship"] = "IMarksmanship",
    ["HunterSurvival"] = "Survival",
    ["MageArcane"] = "Arcane",
    ["MageFire"] = "Fire",
    ["MageFrost"] = "Frost",
    ["PaladinCombat"] = "Retribution",
    ["PaladinHoly"] = "Holy",
    ["PaladinProtection"] = "Protection",
    ["PriestDiscipline"] = "Discipline",
    ["PriestHoly"] = "Holy",
    ["PriestShadow"] = "Shadow",
    ["RogueAssassination"] = "Assassination",
    ["RogueCombat"] = "Combat",
    ["RogueSubtlety"] = "Subtlety",
    ["ShamanElementalCombat"] = "Elemental",
    ["ShamanEnhancement"] = "Enhancement",
    ["ShamanRestoration"] = "Restoration",
    ["WarlockCurses"] = "Affliction",
    ["WarlockDestruction"] = "Destruction",
    ["WarlockSummoning"] = "Demonology",
    ["WarriorArms"] = "Arms",
    ["WarriorFury"] = "Fury",
    ["WarriorProtection"] = "Protection",
}


local statIDs = {
	[1] = 'Strength',
	[2] = 'Agility',
	[3] = 'Stamina',
	[4] = 'Intellect',
	[5] = 'Spirit',
}

local spellSchools = {
	[2] = 'Holy',
	[3] = 'Fire',
	[4] = 'Nature',
	[5] = 'Frost',
	[6] = 'Shadow',
	[7] = 'Arcane',
}

local invSlots = {
    "HEADSLOT",
    "NECKSLOT",
    "SHOULDERSLOT",
    "SHIRTSLOT",
    "CHESTSLOT",
    "WAISTSLOT",
    "LEGSSLOT",
    "FEETSLOT",
    "WRISTSLOT",
    "HANDSSLOT",
    "FINGER0SLOT",
    "FINGER1SLOT",
    "TRINKET0SLOT",
    "TRINKET1SLOT",
    "BACKSLOT",
    "MAINHANDSLOT",
    "SECONDARYHANDSLOT",
    "RANGEDSLOT",
    "TABARDSLOT",

}



Mixin(addon, CallbackRegistryMixin)
addon:GenerateCallbackEvents({
    "OnDatabaseInitialised",
	"OnGuildDataImported",

	"Character_OnDataChanged",

	"OnCommsMessage",
	"OnCommsBlocked",

    "OnCharacterChanged",

    "RosterListviewItem_OnMouseDown",
    
    "OnGuildRosterUpdate",
	"OnGuildRosterScanned",

    "OnAddonLoaded",
    "OnPlayerEnteringWorld",

    "OnPlayerBagsUpdated",
    "OnPlayerTradeskillRecipesScanned",
    "OnPlayerTradeskillRecipesLinked",
    "OnPlayerTradeskillUnlearned",
	"OnPlayerSkillsScanned",
    "OnPlayerTalentSpecChanged",
    "OnPlayerEquipmentChanged",
	"OnPlayerStatsChanged",

    "OnGuildChanged",
    "OnGuildRemoved",

    "OnChatMessageGuild",

    "TradeskillListviewItem_OnMouseDown",
	"TradeskillListviewItem_OnAddToWorkOrder",
	"TradeskillListviewItem_RemoveFromWorkOrder",
	"TradeskillCrafter_SendWorkOrder",

	"AltManagerListviewItem_OnCheckButtonClicked",


});
CallbackRegistryMixin.OnLoad(addon);





--this is to get locale names/links for crafted items
function addon:GetLocaleTradeskillInfo()

	local dbCount = #addon.tradeskillItems
	print("requesting locale data, db size:", dbCount)

	if not tradeskillLocales then
		tradeskillLocales = {
			items = {},
			enchants = {},
		}
	end


	local queriesComplete = 0;
	for k, _item in ipairs(addon.tradeskillItems) do

		print("query:", _item.link)

		if _item.tradeskill == 333 then
			
			if not tradeskillLocales.enchants[GetLocale()] then
				tradeskillLocales.enchants[GetLocale()] = {}
			end

			local spell = Spell:CreateFromSpellID(_item.itemID)
			if not spell:IsSpellEmpty() then
				spell:ContinueOnSpellLoad(function()
					local name = spell:GetSpellName()
					local desc = spell:GetSpellDescription()
	
					tradeskillLocales.enchants[GetLocale()][_item.itemID] = {
						name = name,
						link = string.format("spell:%s", _item.itemID),
						desc = desc,
					}
					queriesComplete = queriesComplete + 1;
					print("completed queries:", queriesComplete)
				end)
			end

		else

			if not tradeskillLocales.items[GetLocale()] then
				tradeskillLocales.items[GetLocale()] = {}
			end

			local item = Item:CreateFromItemID(_item.itemID)
			if not item:IsItemEmpty() then
				item:ContinueOnItemLoad(function()
					local name = item:GetItemName()
					local link = item:GetItemLink()
	
					tradeskillLocales.items[GetLocale()][_item.itemID] = {
						name = name,
						link = link,
					}
					queriesComplete = queriesComplete + 1;
					print("completed queries:", queriesComplete)
				end)
			end
		end
		
	end
end



function addon:FormatNumberForCharacterStats(num)
    if type(num) == 'number' then
        local trimmed = string.format("%.2f", num)
        return tonumber(trimmed)
    else
        return 1.0;
    end
end





















local lastChatMessage;
local lastChatMessageTime;
function addon:PostChatWindowMessage(msg)
    if Database:GetConfigSetting("showChatWindowMessages") then
        print(string.format("[|cffB34BD4%s|r] %s", addonName, msg))
    end
end









function addon:ScanPlayerTalents(...)
    local newSpec, previousSpec = ...;

	if type(newSpec) ~= "number" then
		newSpec = GetActiveTalentGroup()
	end
	if type(newSpec) ~= "number" then
		newSpec = 1
	end

    local tabs, talents = {}, {}
    for tabIndex = 1, GetNumTalentTabs() do
        local _, texture, pointsSpent, fileName = GetTalentTabInfo(tabIndex)
        local engSpec = talentBackgroundToSpec[fileName]
        table.insert(tabs, {
            points = pointsSpent, 
            spec = engSpec,
            texture = fileName,
        });
        for talentIndex = 1, GetNumTalents(tabIndex) do
            local name, iconTexture, row, column, rank, maxRank, isExceptional, available = GetTalentInfo(tabIndex, talentIndex)
            table.insert(talents, {
                Tab = tabIndex,
                Row = row,
                Col = column,
                Rank = rank,
                MxRnk = maxRank,
                Icon = iconTexture,
                Index = talentIndex,
                Link = GetTalentLink(tabIndex, talentIndex),
            });
        end
    end

    local glyphs = {}
    for i = 1, 6 do
        local enabled, glyphType, glyphSpellID, icon = GetGlyphSocketInfo(i);
        if enabled and glyphSpellID then
            local name = GetSpellInfo(glyphSpellID)
            if name then
                for k, item in ipairs(addon.glyphData) do
					local localeData = Tradeskills:GetLocaleData(item)
					if localeData and (localeData.name == name) then
						table.insert(glyphs, {
							socket = i,
							glyphType = item.glyphType,
							itemID = item.itemID,
						})
					end
                end
            end
        end
    end

    if newSpec == 1 then
        self:TriggerEvent("OnPlayerTalentSpecChanged", "primary", talents, glyphs)
    elseif newSpec == 2 then
        self:TriggerEvent("OnPlayerTalentSpecChanged", "secondary", talents, glyphs)
    end

    self:PostChatWindowMessage(L["GB_CHAT_MSG_SCANNED_TALENTS_GLYPHS"])
end


function addon:GetCharacterStats(setID)

	local equipmentSetName = "";
	local sets = C_EquipmentSet.GetEquipmentSetIDs();
    for k, v in ipairs(sets) do
        local name, iconFileID, _setID, isEquipped, numItems, numEquipped, numInInventory, numLost, numIgnored = C_EquipmentSet.GetEquipmentSetInfo(v)
		if _setID == setID then
			equipmentSetName = name;
		end
    end

    if equipmentSetName == "" then
        equipmentSetName = "gb-char-cur-equip-stats"
    end

    local stats = {};

    ---go through getting each stat value
    local numSkills = GetNumSkillLines();
    local skillIndex = 0;
    local currentHeader = nil;

    for i = 1, numSkills do
        local skillName = select(1, GetSkillLineInfo(i));
        local isHeader = select(2, GetSkillLineInfo(i));

        if isHeader ~= nil and isHeader then
            currentHeader = skillName;
        else
            if (currentHeader == "Weapon Skills" and skillName == 'Defense') then
                skillIndex = i;
                break;
            end
        end
    end

    local baseDef, modDef;
    if (skillIndex > 0) then
        baseDef = select(4, GetSkillLineInfo(skillIndex));
        modDef = select(6, GetSkillLineInfo(skillIndex));
    else
        baseDef, modDef = UnitDefense('player')
    end

    local posBuff = 0;
    local negBuff = 0;
    if ( modDef > 0 ) then
        posBuff = modDef;
    elseif ( modDef < 0 ) then
        negBuff = modDef;
    end
    stats.Defence = {
        Base = self:FormatNumberForCharacterStats(baseDef),
        Mod = self:FormatNumberForCharacterStats(modDef),
    }

    local baseArmor, effectiveArmor, armr, posBuff, negBuff = UnitArmor('player');
    stats.Armor = self:FormatNumberForCharacterStats(baseArmor)
    stats.Block = self:FormatNumberForCharacterStats(GetBlockChance());
    stats.Parry = self:FormatNumberForCharacterStats(GetParryChance());
    stats.ShieldBlock = self:FormatNumberForCharacterStats(GetShieldBlock());
    stats.Dodge = self:FormatNumberForCharacterStats(GetDodgeChance());

    --local expertise, offhandExpertise, rangedExpertise = GetExpertise();
    stats.Expertise = self:FormatNumberForCharacterStats(GetExpertise()); --will display mainhand expertise but it stores offhand expertise as well, need to find a way to access it
    --local base, casting = GetManaRegen();

    --to work with all versions we have to adjust the values we get
    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        stats.SpellHit = self:FormatNumberForCharacterStats(GetSpellHitModifier());
        stats.MeleeHit = self:FormatNumberForCharacterStats(GetHitModifier());
        stats.RangedHit = self:FormatNumberForCharacterStats(GetHitModifier());
        
    elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        stats.SpellHit = self:FormatNumberForCharacterStats(GetCombatRatingBonus(CR_HIT_SPELL) + GetSpellHitModifier());
        stats.MeleeHit = self:FormatNumberForCharacterStats(GetCombatRatingBonus(CR_HIT_MELEE) + GetHitModifier());
        stats.RangedHit = self:FormatNumberForCharacterStats(GetCombatRatingBonus(CR_HIT_RANGED));

    else
        stats.SpellHit = self:FormatNumberForCharacterStats(GetCombatRatingBonus(CR_HIT_SPELL));
        stats.MeleeHit = self:FormatNumberForCharacterStats(GetCombatRatingBonus(CR_HIT_MELEE));
        stats.RangedHit = self:FormatNumberForCharacterStats(GetCombatRatingBonus(CR_HIT_RANGED));
    end

    stats.RangedCrit = self:FormatNumberForCharacterStats(GetRangedCritChance());
    stats.MeleeCrit = self:FormatNumberForCharacterStats(GetCritChance());

    stats.Haste = self:FormatNumberForCharacterStats(GetCombatRatingBonus(20));
    local base, casting = GetManaRegen()
    base = base*5;
    casting = casting*5;
    stats.ManaRegen = base and self:FormatNumberForCharacterStats(base) or 0;
    stats.ManaRegenCasting = casting and self:FormatNumberForCharacterStats(casting) or 0;

    local minCrit = 100
    for id, school in pairs(spellSchools) do
        if GetSpellCritChance(id) < minCrit then
            minCrit = GetSpellCritChance(id)
        end
        stats['SpellDmg'..school] = self:FormatNumberForCharacterStats(GetSpellBonusDamage(id));
        stats['SpellCrit'..school] = self:FormatNumberForCharacterStats(GetSpellCritChance(id));
    end
    stats.SpellCrit = self:FormatNumberForCharacterStats(minCrit)

    stats.HealingBonus = self:FormatNumberForCharacterStats(GetSpellBonusHealing());

    local lowDmg, hiDmg, offlowDmg, offhiDmg, posBuff, negBuff, percentmod = UnitDamage("player");
    local mainSpeed, offSpeed = UnitAttackSpeed("player");
    local mlow = (lowDmg + posBuff + negBuff) * percentmod
    local mhigh = (hiDmg + posBuff + negBuff) * percentmod
    local olow = (offlowDmg + posBuff + negBuff) * percentmod
    local ohigh = (offhiDmg + posBuff + negBuff) * percentmod
    if mainSpeed < 1 then mainSpeed = 1 end
    if mlow < 1 then mlow = 1 end
    if mhigh < 1 then mhigh = 1 end
    if olow < 1 then olow = 1 end
    if ohigh < 1 then ohigh = 1 end

    if offSpeed then
        if offSpeed < 1 then 
            offSpeed = 1
        end
        stats.MeleeDmgOH = self:FormatNumberForCharacterStats((olow + ohigh) / 2.0)
        stats.MeleeDpsOH = self:FormatNumberForCharacterStats(((olow + ohigh) / 2.0) / offSpeed)
    else
        --offSpeed = 1
        stats.MeleeDmgOH = self:FormatNumberForCharacterStats(0)
        stats.MeleeDpsOH = self:FormatNumberForCharacterStats(0)
    end
    stats.MeleeDmgMH = self:FormatNumberForCharacterStats((mlow + mhigh) / 2.0)
    stats.MeleeDpsMH = self:FormatNumberForCharacterStats(((mlow + mhigh) / 2.0) / mainSpeed)

    local speed, lowDmg, hiDmg, posBuff, negBuff, percent = UnitRangedDamage("player");
    local low = (lowDmg + posBuff + negBuff) * percent
    local high = (hiDmg + posBuff + negBuff) * percent
    if speed < 1 then speed = 1 end
    if low < 1 then low = 1 end
    if high < 1 then high = 1 end
    local dmg = (low + high) / 2.0
    stats.RangedDmg = self:FormatNumberForCharacterStats(dmg)
    stats.RangedDps = self:FormatNumberForCharacterStats(dmg/speed)

    local base, posBuff, negBuff = UnitAttackPower('player')
    stats.AttackPower = self:FormatNumberForCharacterStats(base + posBuff + negBuff)

    for k, stat in pairs(statIDs) do
        local a, b, c, d = UnitStat("player", k);
        stats[stat] = self:FormatNumberForCharacterStats(b)
    end

	--ViragDevTool:AddData(stats, "Guildbook_CharStats_"..equipmentSetName)

	addon:TriggerEvent("OnPlayerStatsChanged", equipmentSetName, stats)

    self:PostChatWindowMessage(L["GB_CHAT_MSG_SCANNED_CHARACTER_STATS_S"]:format(equipmentSetName))
end



function addon:ScanPlayerEquipment()
    local sets = C_EquipmentSet.GetEquipmentSetIDs();

    local equipment = {
        sets = {},
        current = {},
    };

    for k, v in ipairs(sets) do
        
        local name, iconFileID, setID, isEquipped, numItems, numEquipped, numInInventory, numLost, numIgnored = C_EquipmentSet.GetEquipmentSetInfo(v)

        local setItemIDs = C_EquipmentSet.GetItemIDs(setID)

        equipment.sets[name] = setItemIDs;
    end


    --lets grab the current gear
    local t = {}
    for k, slot in ipairs(invSlots) do
        local link = GetInventoryItemLink('player', GetInventorySlotInfo(slot)) or false;
        if link ~= nil then
            t[k] = link;
        end
    end
    equipment.current = t;

    self:TriggerEvent("OnPlayerEquipmentChanged", equipment)

    self:PostChatWindowMessage(L["GB_CHAT_MSG_SCANNED_EQUIPMENT_SETS"])
end


function addon:ScanPlayerCharacter()

	self:ScanPlayerEquipment()
	self:ScanPlayerTalents({})
	
end



function addon:ScanSkills()
	local secondarySkills = {
		[185] = 0,
		[129] = 0,
		[356] = 0,
	}

    local primarySkillIDs = {
        [164] = 0,
		[165] = 0,
		[171] = 0,
		[182] = 0,
		[186] = 0,
		[197] = 0,
		[202] = 0,
		[333] = 0,
		[393] = 0,
		[755] = 0,
		[773] = 0,
    }
    local primarySkills = {}

	for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank = GetSkillLineInfo(i);

		if name and type(rank) == "number" then
			local tradeskillID = Tradeskills:GetTradeskillIDFromLocale(name)

			if tradeskillID and secondarySkills[tradeskillID] and (type(rank) == "number") and (rank > 0) then
				secondarySkills[tradeskillID] = rank;
			end

			if tradeskillID and primarySkillIDs[tradeskillID] and (type(rank) == "number") and (rank > 0) then
				primarySkills[tradeskillID] = rank;
			end

		end

	end

	addon:TriggerEvent("OnPlayerSkillsScanned", secondarySkills, primarySkills)

    self:PostChatWindowMessage(L["GB_CHAT_MSG_SCANNED_SKILLS"])
end


function addon:debug(...)
    local data = ...;
    if (data) then
        if (type(data) == "table") then
            UIParentLoadAddOn("Blizzard_DebugTools");
            --DevTools_Dump(data);
            DisplayTableInspectorWindow(data);
        else
            print("GuildBook Debug:", ...);
        end
    end
end


function addon:ADDON_LOADED(...)

    if ... == addonName then

        --self.e:UnregisterEvent("ADDON_LOADED");

        addon.Database:Init()
		addon.Comms:Init()

	end

	-- if ... == "ViragDevTool" then
	-- 	ViragDevTool:AddData(GUILDBOOK_GLOBAL, "GUILDBOOK_GLOBAL")
	-- end

	self:RegisterCallback("Character_OnDataChanged", self.ScanPlayerCharacter, self)

end


function addon:PLAYER_ENTERING_WORLD()
	
	self.e:UnregisterEvent("PLAYER_ENTERING_WORLD");

    self:TriggerEvent("OnPlayerEnteringWorld")

	--grab the latest character info
	self:ScanPlayerCharacter()

	--set up some hooks
	PlayerTalentFrame:HookScript("OnHide", function()
		self:ScanPlayerTalents({})
	end)
	SkillFrame:HookScript("OnShow", function()
		self:ScanSkills()
	end)
    CharacterFrame:HookScript("OnHide", function()
        self:GetCharacterStats()
    end)

	hooksecurefunc(C_EquipmentSet, "CreateEquipmentSet", function()
		self:ScanPlayerEquipment()
	end)
	hooksecurefunc(C_EquipmentSet, "DeleteEquipmentSet", function()
		self:ScanPlayerEquipment()
	end)

    -- C_Timer.After(5, function()
    --     self:GetLocaleTradeskillInfo()
    -- end)
end


function addon:CHAT_MSG_GUILD(...)
    self:TriggerEvent("OnChatMessageGuild", ...)
end


function addon:BAG_UPDATE_DELAYED()
    self:TriggerEvent("OnPlayerBagsUpdated")
end


function addon:GUILD_ROSTER_UPDATE()
    self:TriggerEvent("OnGuildRosterUpdate")
end

function addon:PLAYER_EQUIPMENT_CHANGED(...)
    self:ScanPlayerEquipment()
end

function addon:TRADE_SKILL_UPDATE(...)

    local englishProf = nil;

    local localeProf, currentLevel, maxLevel = GetTradeSkillLine();

    --if no prof name/level were returned lets try to get it from the ui 
    if type(localeProf) ~= "string" then

        --we need this fontstring to exist before trying
        if TradeSkillFrameTitleText then
            localeProf = TradeSkillFrameTitleText:GetText()
        end
        
        --now try to get the current/max levels
        local rankText = TradeSkillRankFrameSkillRank and TradeSkillRankFrameSkillRank:GetText() or nil;
        if rankText and rankText:find("/") then
            local currentLevel, maxLevel = strsplit("/", rankText)
            if type(currentLevel) == "string" then
                currentLevel = tonumber(currentLevel)
            end
            if type(maxLevel) == "string" then
                maxLevel = tonumber(maxLevel)
            end
            --addon.DEBUG("characterMixin", "Character:ScanTradeskillRecipes", string.format("found prof level [%s] from UI text", currentLevel))
        end
    end

	local tradeskillID = Tradeskills:GetTradeskillIDFromLocale(localeProf)

	if type(tradeskillID) ~= "number" then
		--addon.DEBUG("func", "addon:TRADE_SKILL_UPDATE", "tradeskillID not found")
	end



    local tradeskillRecipes = {}
    if tradeskillID == 333 then
        
        local numCrafts = GetNumTradeSkills()
        for i = 1, numCrafts do
            local name, _type, _, _, _, _ = GetTradeSkillInfo(i)
            if name and (_type == "optimal" or _type == "medium" or _type == "easy" or _type == "trivial") then -- this was a fix thanks to Sigma regarding their addon showing all recipes
                local link = GetTradeSkillRecipeLink(i)
                if link then
                    --thanks to meo for this to get the itemID
                    local itemID = string.match(link, "enchant:(%d+)")
                    if itemID then
                        itemID = tonumber(itemID)
                        table.insert(tradeskillRecipes, itemID)
                    end
                end
            end
        end

    else

        local numTradeskills = GetNumTradeSkills()
        for i = 1, numTradeskills do
            local name, _type, rank, _, _ = GetTradeSkillInfo(i)
    
            if name and (_type == "optimal" or _type == "medium" or _type == "easy" or _type == "trivial") then -- this was a fix thanks to Sigma regarding their addon showing all recipes
                local link = GetTradeSkillItemLink(i)
                if link then
                    local itemID = GetItemInfoInstant(link)
                    if itemID then
                        table.insert(tradeskillRecipes, itemID)
                    end
                end
            end
        end

    end


    --DevTools_Dump({tradeskillRecipes})

    local isLinked, characterName = IsTradeSkillLinked()

    if isLinked == true then
        self:TriggerEvent("OnPlayerTradeskillRecipesLinked", characterName, tradeskillID, currentLevel, tradeskillRecipes)
    else
        self:TriggerEvent("OnPlayerTradeskillRecipesScanned", tradeskillID, currentLevel, tradeskillRecipes)
    end

    self:PostChatWindowMessage(L["GB_CHAT_MSG_SCANNED_TRADESKILL_RECIPES_S"]:format(localeProf))
end


function addon:ACTIVE_TALENT_GROUP_CHANGED(...)
	self:ScanPlayerTalents(...)
end


function addon:EQUIPMENT_SETS_CHANGED()
	self:ScanPlayerEquipment()
end


function addon:EQUIPMENT_SWAP_FINISHED(...)
	local _, setID = ...;
	C_Timer.After(1.0, function()
		self:GetCharacterStats(setID)
	end)
end


function addon:SKILL_LINES_CHANGED(...)
    self:ScanSkills()
end

function addon:CONSOLE_MESSAGE(...)

	local msg, _ = ...;

	local _, tradeskillID, _, _, oldRank, _, newRank = strsplit(" ", msg)

    if tonumber(tradeskillID) and tonumber(oldRank) and tonumber(newRank) then

        tradeskillID = tonumber(tradeskillID)

        local x = Tradeskills:IsTradeskill(nil, tradeskillID)
        if (x == true) and (tonumber(newRank) == 0) then
            --self:TriggerEvent("OnPlayerTradeskillUnlearned", tradeskillID)
        end

    end

end


function addon:CHAT_MSG_SYSTEM(...)

    local msg = ...;

    local tradeskillUnlearned = ERR_SPELL_UNLEARNED_S:gsub("%%s", ".*")
    if msg:find(tradeskillUnlearned) then
        local _, _, _, localeProf = strsplit(" ", msg)

        local x = Tradeskills:IsTradeskill(localeProf)
        if x == true then
            local tradeskillID = Tradeskills:GetTradeskillIDFromLocale(localeProf)
            if type(tradeskillID) == "number" then
                self:TriggerEvent("OnPlayerTradeskillUnlearned", tradeskillID)
            end
        end
    end

end

addon.e = CreateFrame("Frame");
addon.e:RegisterEvent("ADDON_LOADED");
addon.e:RegisterEvent("PLAYER_ENTERING_WORLD");
--addon.e:RegisterEvent("CONSOLE_MESSAGE");
addon.e:RegisterEvent("TRADE_SKILL_UPDATE")
addon.e:RegisterEvent("CRAFT_UPDATE")
addon.e:RegisterEvent("SKILL_LINES_CHANGED")
addon.e:RegisterEvent("CHARACTER_POINTS_CHANGED")
addon.e:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
addon.e:RegisterEvent("CHAT_MSG_SKILL")
addon.e:RegisterEvent("CHAT_MSG_SYSTEM")
addon.e:RegisterEvent("GUILD_ROSTER_UPDATE")
addon.e:RegisterEvent("CHAT_MSG_SYSTEM")
addon.e:RegisterEvent("CHAT_MSG_GUILD")
addon.e:RegisterEvent("CHAT_MSG_WHISPER")
addon.e:RegisterEvent('BANKFRAME_CLOSED')
addon.e:RegisterEvent('BAG_UPDATE_DELAYED')
addon.e:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
addon.e:RegisterEvent('EQUIPMENT_SETS_CHANGED')
addon.e:RegisterEvent('EQUIPMENT_SWAP_FINISHED')
addon.e:SetScript("OnEvent", function(self, event, ...)
    if addon[event] then
        addon[event](addon, ...)
    end
end)