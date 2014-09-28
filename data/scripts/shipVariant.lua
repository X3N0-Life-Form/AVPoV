--[[
		---------------------------------
		-- ship variant manager script --
		---------------------------------
In order to work, this script needs:
	- a descriptor text file
	- the global variable variantFileName needs to point to this file, eg. "data/config/ship_variants.txt"
	- call the setVariant() or sv() function via scrip-eval, with the name of the ship you want to alter and the name of the variant of the appropriate class as the function's argument.
		For instance "sv(Colly, bunny)" means you want Colly to be of the "bunny" variant.
		Keep in mind that, as of this writing, script-eval suffers from FSO's infamous 32 character limit, so you may want to keep your variant names short for the time being.
	- alternatively, you can set the lua variable g_sn (global ship name) and g_vn (global variant name) and call the setVariant_g() function:
		( script-eval
			"g_sn = Colly"
			"g_vn = bunny"
			"setVariant_g()"
		)
		
Descriptor file logic:
	- A new variant is identified by a '$', followed by the ship class, a ':' and then the variant's name, like this:
		$GTC Aeolus:	nerfed		--> defines the "nerf" variant for the GTC Aeolus
	- Following the variant definition is a list of attributes or turret names, potentially with their own sub-attributes.
		
			
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
variantFileName = "ship_variants.txt" -- change this
variantMatrix = {}

shipsToSet = {}

-- these variables need to be set through FRED's script-eval SEXP
g_sn = nil -- global ship name
g_vn = nil -- global variant name


-----------------------
-- utility functions --
-----------------------

function trim(str)
	return str:find'^%s*$' and '' or str:match'^%s*(.*%S)'
end

function removeComments(line)
	return line:gsub("--(.)*|//(.)*|;;(.)*", "")
end

function extractLeft(attribute)
	local line = attribute
	local cut = string.find(line, ":")
	return trim(string.sub(line, 2, cut - 1))
end

function extractRight(attribute)
	local line = attribute
	local cut = string.find(line, ":")
	return trim(string.sub(line, cut + 1))
end

-- screw you, 32 char limit
function sv(shipName, variantName)
	setVariant(shipName, variantName)
end


--------------------
-- core functions --
--------------------

function parseVariantFile(fileName)
	if (matrix == nil) then
		matrix = {}
	end
	if cf.fileExists(fileName, "", true) then
		local file = cf.openFile(fileName, "r")
		
		local line = file:read("*l")
		i = 0
		while (not (line == nil)) do
			i = i+1
			line = removeComments(line)
			line = trim(line)
			
			cut = string.find(line, ":")
			if not (cut == nil) then -- we've got a parsable line
				if not (string.find(line, "[+]") == nil) then
					if (attributeName == nil) then
						ba.warning("parseVariantFile: assigning a sub-attribute without a super-attribute: "..line)
					else
						subAttributeName = trim(string.sub(line, 2, cut - 1))	-- armor, texture
						subAttributeValue = trim(string.sub(line, cut + 1))		-- armor type, texture name
						ba.print("parseVariantFile: subAttributeName="..subAttributeName.."; subAttributeValue="..subAttributeValue)
						matrix[className][variantName]["+"..attributeName..":"..subAttributeName] = subAttributeValue
					end
				elseif not (string.find(line, "[$]") == nil) then
					className = trim(string.sub(line, 2, cut - 1))
					variantName = trim(string.sub(line, cut + 1))
					
					-- init class & variant maps
					if (matrix[className] == nil) then
						matrix[className] = {}
					end
					ba.print("parseVariantFile: className="..className.."; variantName="..variantName)
					matrix[className][variantName] = {}
					
					-- clean up potential leftovers
					attributeName = nil
					attributeValue = nil
				else
					attributeName = trim(string.sub(line, 0, cut - 1))		-- turret, hull, armor, texture, team color
					attributeValue = trim(string.sub(line, cut + 1))		-- weapon type, armor type, hull value, texture name, color name
					
					-- special case: texture attribute
					if (attributeName == "texture") then
						equal = string.find(line, "=")
						attributeName = trim(string.sub(line, 0, equal - 1))	-- attributeName = texture:name
						attributeValue = trim(string.sub(line, equal + 1))		-- attributeValue = replacement name
					end
					
					ba.print("parseVariantFile: attributeName="..attributeName.."; attributeValue="..attributeValue)
					matrix[className][variantName][attributeName] = attributeValue
				end
				--TODO: error check results of previous if then else block?
			end
			
			line = file:read("*l")
		end -- while
		file:close()
		return matrix
	else
		ba.warning("parseVariantFile: Variant file not found "..filename)
		return nil
	end
end

function setVariant(shipName, variantName)
	if (variantMatrix == nil) then
		variantMatrix = parseVariantFile(variantFileName)
	end
	-- get ship class
	-- lookup variant for that class
	-- start going through the attributes
	local ship = mn.Ships[shipName]
	if not (ship:isValid()) then
		ba.print("setVariant: Could not find ship "..shipName)
		ba.print("setVariant: adding ship/variant to shipsToSet")
		shipsToSet[shipName] = variantName
		return nil
	end
	
	local className = ship.Class.Name
	local variantInfo = variantMatrix[className][variantName]
	if (variantInfo == nil) then
		ba.warning("setVariant: Could not find variant info for "..className..":"..variantName)
		return nil
	end
	
	local turretArmor = ""
	local subsystemArmor = ""
	local subToSkip = {}
	for attribute, value in pairs(variantInfo) do
		--Note: value = variantInfo[attribute]
		if (attribute == "armor") then
			ba.print("setVariant: Armor ==> "..value)
			ship.armorClass = value
		elseif (attribute == "shield armor") then
			ba.print("setVariant: Shield Armor ==> "..value)
			ship.ShieldArmorClass = value
		elseif (attribute == "turret armor") then
			turretArmor = value
		elseif (attribute == "subsystem armor") then
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
			ba.print("setVariant: hull ==> "..value)
			ratio = value / ship.HitpointsMax
			ship.HitpointsMax = value
			ship.HitpointsLeft = ship.HitpointsLeft * ratio
			
		elseif (attribute == "team color") then
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
			mn.evaluateSEXP([[[
				(when (true)
					(change-ai-class
						"]]..shipName..[["
						"]]..value..[["
					)
				)
			]])
			
		elseif not (string.find(attribute, "texture") == nil) then --note: this doesn't work
			local textureName = extractRight(attribute)
			local texture = gr.loadTexture(textureName)
			if (texture:isValid()) then
				ba.print("setVariant: Replacing texture '"..textureName.."' with texture '"..value.."'.")
				ship.Textures[textureName] = texture
			else
				ba.warning("setVariant: Texture "..value.." is invalid.")
			end
			
		elseif not (string.find(attribute, "+") == nil) then -- sub-attribute
			local line = attribute
			attribute = extractLeft(line)
			local subAttribute = extractRight(line)
			ba.print("setVariant: Setting sub attribute for "..attribute)
			ba.print("setVariant:     "..subAttribute.." ==> "..value)
			
			if (subAttribute == "armor") then
				ship[attribute].ArmorClass = value
				-- also, need to make sure general armor settings don't override this
				subToSkip[attribute] = true
				
			elseif (subAttribute == "RoF") then
				mn.evaluateSEXP([[
					(when (true)
						(turret-set-rate-of-fire
							"]]..shipName..[["
							]]..value..[[
							"]]..attribute..[["
						)
					)
				]])
				
			else
				ba.warning("setVariant: Unrecognised sub attribute: "..subAttribute)
			end
			
		else -- turret
			if (ship[attribute].PrimaryBanks) then -- primary banks
				for i = 0, #ship[attribute].PrimaryBanks do
					ba.print("setVariant: Prim "..attribute.." - "..ship[attribute].PrimaryBanks[i].WeaponClass.Name.." ==> "..tb.WeaponClasses[value].Name)
					ship[attribute].PrimaryBanks[i].WeaponClass = tb.WeaponClasses[value]
				end
			else -- secondary banks
				for i = 0, #ship[attribute].SecondaryBanks do
					ba.print("setVariant: Sec "..attribute.." - "..ship[attribute].SecondaryBanks[i].WeaponClass.Name.." ==> "..tb.WeaponClasses[value].Name)
					ship[attribute].SecondaryBanks[i].WeaponClass = tb.WeaponClasses[value]
				end
			end
		end
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
	for shipName, variantName in pairs(shipsToSet) do
		local ship = mn.Ships[shipName]
		if not (ship == nil) then
			ba.print("setVariantDelayed: setting ship variant "..shipName.." ==> "..variantName)
			shipsToSet[shipName] = nil
			setVariant(shipName, variantName)
		end
	end
end


--[[
	set variant using global variables g_sn & g_vn
]]--
function setVariant_g()
	if (g_sn == nil) then
		ba.warning("setVariant_g: global variable g_sn unset.")
	elseif (g_vn == nil) then
		ba.warning("setVariant_g: global variable g_vn unset.")
	else
		setVariant(g_sn, g_vn)
		g_sn = nil
		g_vn = nil
	end
end
----------
-- main --
----------

variantMatrix = parseVariantFile(variantFileName)
