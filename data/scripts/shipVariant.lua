--[[
		---------------------------------
		-- ship variant manager script --
		---------------------------------
In order to work, this script needs:
	- a descriptor table file in data/config
	- a lua table parser
	- the global variable variantFileName needs to point to this file, eg. "data/config/ship_variants.tbl"
	- call the setVariant() function via scrip-eval, with the name of the ship you want to alter and the name of the variant of the appropriate class as the function's argument.
		For instance "setVariant(Colly, bunny)" means you want Colly to be of the "bunny" variant.
		
Descriptor table logic:
	- Variants are classified by ship category, which starts with '#'
	- Each variant starts with '$Name:', follow by attributes that start with "$"
	- These may be followed by sub attributes, who themselves start with "+"
	
Descriptor table sample:
	#SC Rakshasa
	
	$Name:	Lance Assault Cruiser
	$ai class: Big
	$subsystem armor: Hell Armor
	$hull armor:	 Shivan Destroyer Armor
	$hull:		 80k	;; hull values can be defined using orders of magnitude, eg. 80k = 80,000; 80M = 80,000,000 & 80G = 80,000,000
	$turret01:Shivan Multi Turret Up
		+Rof:200
	$turret02:Shivan Huge Lance
	$turret03:Shivan Huge Lance
	$turret04:Shivan Multi Turret Up
		+Rof:200
	$turret05:Shivan Multi Turret Up
	$turret06:Shivan Multi Turret Up
	$turret07:Shivan Lance
	$turret08:Shivan Lance
	$turret09:Shivan Lance
	$turret10:Shivan Lance
	$turret11:Shivan Multi Turret Up
	$turret12:Shivan Multi Turret Up
	$turret13:Shivan Multi Turret Up
	$turret14:Shivan Multi Turret Up
	
	#End
		
			
Valid attributes:
	hull						: special hit points
	armor						: hull armor type
	turret armor				: ship-wide turret armor type
	subsystem armor				: ship-wide subsystem armor type
	texture:name=replacement	: doesn't work
	team color					: change team color
	ai class					: change ai class
	
Valid sub-attributes:
	armor	: armor type
	RoF		: new rate of fire (in percentage)
	
Sample entry:
	$GTC Aeolus: nerfed
			hull: 15k
			armor: Fancy Armor
			turret armor: Fancy Armor
			subsystem armor: Fancy Armor
			turret01: Terran Huge Turret
				+armor: Weak Armor
			turret02: Terran Huge Turret
				+armor: Weak Armor
			turret03: Terran Huge Turret
			turret04: Terran Huge Turret
			turret05: Terran Huge Turret
]]--
----------------------
-- global variables --
----------------------
variant_enableDebugPrint = false

variantPath = "data/config/"
variantTableName = "ship_variants.tbl"
variantTable = {}

variantShipsToSet = {}


-----------------------
-- utility functions --
-----------------------

function dPrint_shipVariant(message)
	if (variant_enableDebugPrint) then
		ba.print("[shipVariant.lua] "..message)
	end
end

--------------------
-- core functions --
--------------------

function setVariant(shipName, variantName)
	-- get ship class
	-- lookup variant for that class
	-- start going through the attributes
	local ship = mn.Ships[shipName]
	if not (ship:isValid()) then
		dPrint_shipVariant("Could not find ship "..shipName.."\n")
		dPrint_shipVariant("adding ship/variant to variantShipsToSet\n")
		variantShipsToSet[shipName] = variantName
		return nil
	end
	
	local className = ship.Class.Name
	local variantInfo = variantTable[className][variantName]
	if (variantInfo == nil) then
		ba.warning("[shipVariant.lua] Could not find variant info for "..className..":"..variantName.."\n")
		return nil
	end
	
	local turretArmor = ""
	local subsystemArmor = ""
	local subToSkip = {}
	for attribute, prefix in pairs(variantInfo) do
		local value = prefix['value']
		
		if (attribute == "armor") then
			dPrint_shipVariant("Armor ==> "..value.."\n")
			ship.armorClass = value
		elseif (attribute == "shield armor") then
			dPrint_shipVariant("Shield Armor ==> "..value.."\n")
			ship.ShieldArmorClass = value
		elseif (attribute == "turret armor") then
			dPrint_shipVariant("Global Turret Armor ==> "..value.."\n");
			turretArmor = value
		elseif (attribute == "subsystem armor") then
			dPrint_shipVariant("Global Subsystem Armor ==> "..value.."\n");
			subsystemArmor = value
			
		elseif (attribute == "hull") then
			-- deal with orders of magnitude
			if not (string.find(value, "k") == nil) then
				value = string.gsub(value, "k", "")
				value = value * 1000
			elseif not (string.find(value, "M") == nil) then
				value = string.gsub(value, "M", "")
				value = value * 1000000
			elseif not (string.find(value, "G") == nil) then
				value = string.gsub(value, "G", "")
				value = value * 1000000000
			end
			
			-- set max & current hit points
			dPrint_shipVariant("Hull Max Hitpoints ==> "..value.."\n")
			ratio = value / ship.HitpointsMax
			ship.HitpointsMax = value
			ship.HitpointsLeft = ship.HitpointsLeft * ratio
			
		elseif (attribute == "team color") then
			dPrint_shipVariant("Team Color ==> "..value.."\n");
			mn.evaluateSEXP([[
				(when (true)
					(change-team-color
						"]]..value..[["
						0
						"]]..shipName..[["
					)
				)
			]])
			
		elseif (attribute == "ai class") then
			dPrint_shipVariant("AI Class ==> "..value.."\n");
			mn.evaluateSEXP([[[
				(when (true)
					(change-ai-class
						"]]..shipName..[["
						"]]..value..[["
					)
				)
			]])
			
		elseif not (string.find(attribute, "texture") == nil) then --note: this doesn't work
			--local textureName = extractRight(attribute)
			--local texture = gr.loadTexture(textureName)
			--if (texture:isValid()) then
			--	ba.print("[ShipVariant.lua] Replacing texture '"..textureName.."' with texture '"..value.."'.\n")
			--	ship.Textures[textureName] = texture
			--else
			--	ba.warning("[ShipVariant.lua] Texture "..value.." is invalid.\n")
			--end
			
		
			
		elseif not (string.find(attribute, "turret") == nil) then -- turret
			if (ship[attribute].PrimaryBanks) then -- primary banks
				for i = 0, #ship[attribute].PrimaryBanks do
					dPrint_shipVariant("Primary Bank: "..attribute.." - "..ship[attribute].PrimaryBanks[i].WeaponClass.Name.." ==> "..tb.WeaponClasses[value].Name.."\n")
					ship[attribute].PrimaryBanks[i].WeaponClass = tb.WeaponClasses[value]
				end
			else -- secondary banks
				for i = 0, #ship[attribute].SecondaryBanks do
					dPrint_shipVariant("Secondary Bank: "..attribute.." - "..ship[attribute].SecondaryBanks[i].WeaponClass.Name.." ==> "..tb.WeaponClasses[value].Name.."\n")
					ship[attribute].SecondaryBanks[i].WeaponClass = tb.WeaponClasses[value]
				end
			end
		else
			ba.warning("[shipVariant.lua] Unrecognised attribute: "..attribute.."\n")
		end
		
		 -- sub-attributes
		if not (prefix['sub'] == nil) then
			for subAttribute, subValue in pairs(prefix['sub']) do
				dPrint_shipVariant("     "..subAttribute.." ==> "..subValue)
				
				if (subAttribute == "armor") then
					ship[attribute].ArmorClass = subValue
					-- also, need to make sure general armor settings don't override this
					subToSkip[attribute] = true
					
				elseif (subAttribute == "RoF") then
					mn.evaluateSEXP([[
						(when (true)
							(turret-set-rate-of-fire
								"]]..shipName..[["
								]]..subValue..[[
								"]]..attribute..[["
							)
						)
					]])
					
				else
					ba.warning("[shipVariant.lua] Unrecognised sub attribute: "..subAttribute)
				end
			end
		end
		
	end
	dPrint_shipVariant("all attributes set, moving on to global settings...\n");
	if not (turretArmor == "") then
		dPrint_shipVariant("Turret Armor ==> "..turretArmor.."\n")
	end
	if not (subsystemArmor == "") then
		dPrint_shipVariant("Subsystem Armor ==> "..subsystemArmor.."\n")
	end
	
	-- set turrets & subsystems armor
	for subIndex = 0, #ship do
		local subsystem = ship[subIndex]
		if (subsystem:isTurret() and not (turretArmor == "") and not (subToSkip[subsystem])) then
			subsystem.ArmorClass = turretArmor
		elseif not (subsystemArmor == "") then
			subsystem.ArmorClass = subsystemArmor
		end
	end
end



function setVariantDelayed()
	for shipName, variantName in pairs(variantShipsToSet) do
		local ship = mn.Ships[shipName]
		if not (ship == nil) then
			dPrint_shipVariant("setVariantDelayed: setting ship variant "..shipName.." ==> "..variantName)
			variantShipsToSet[shipName] = nil
			setVariant(shipName, variantName)
		end
	end
end


----------
-- main --
----------

variantTable = parseTableFile(variantPath, variantTableName)



