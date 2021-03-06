--[[
	-----------------------
	-- Respawn Framework --
	-----------------------
	This script provides a framework to re-spawn the player by either
	jumping to a ship in another wing, or to warp back into the
	battle space.
]]


----------------------
-- Global variables --
----------------------

spawnTickets = 0
respawnActive = false
validWings = {}

----------------------------
-- Getters/Setters/Adders --
----------------------------

function enableRespawn()
	respawnActive = true
end

function disableRespawn()
	respawnActive = false
end

function setSpawnTickets(tickets)
	spawnTickets = tickets
end

--- Adds a new wing at the 'end' of the array
function addValidWing(wingName)
	local size = #validWings
	validWings[size] = wingName
end

function clearValidWings()
	validWings = {}
end


-------------------------
-- Respawn subroutines --
-------------------------

--- Swaps the position and stats of the specified ships
--- @param origin : ship handle
--- @param target : ship handle
function swapShips(origin, target)
	local buffer
	
	-- swap class if necessary
	buffer = origin.Class.Name
	mn.evaluateSEXP([[
		(when (true)
			(change-ship-class
				"]]..target.Class.Name..[["
				"]]..origin.Name..[["
		)
	]])
	mn.evaluateSEXP([[
		(when (true)
			(change-ship-class
				"]]..buffer..[["
				"]]..target.Name..[["
		)
	]])
	
	-- swap position & orientation
	buffer = origin.Position
	origin.Position = target.Position
	target.Position = buffer
	buffer = origin.Orientation
	origin.Orientation = target.Orientation
	target.Orientation = buffer
	
	-- swap momentum
	buffer = origin.Physics
	origin.Physics = target.Physics
	target.Physics = buffer
	
	-- swap weapon loadout
	buffer = origin.PrimaryBanks
	origin.PrimaryBanks = target.PrimaryBanks
	target.PrimaryBanks = buffer
	buffer = origin.SecondaryBanks
	origin.SecondaryBanks = target.SecondaryBanks
	target.SecondaryBanks = buffer
	
	-- swap cm loadout
	buffer = origin.CountermeasureClass
	origin.CountermeasureClass = target.CountermeasureClass
	target.CountermeasureClass = buffer
	buffer = origin.CountermeasureLeft
	origin.CountermeasureLeft = target.CountermeasureLeft
	target.CountermeasureLeft = buffer
	
	-- swap damage
	buffer = origin.HitpointsLeft
	mn.evaluateSEXP([[
		(when (true)
			(ship-copy-damage
				"]]..target.Name..[["
				"]]..origin.Name..[["
			)
		)
	]])
	target.HitpointsLeft = buffer -- not perfect, but that will have to do for now
	
	-- swap weapon energy & afterburner energy
	buffer = origin.WeaponEnergyLeft
	origin.WeaponEnergyLeft = target.WeaponEnergyLeft
	target.WeaponEnergyLeft = buffer
	buffer = origin.AfterburnerFuelLeft
	origin.AfterburnerFuelLeft = target.AfterburnerFuelLeft
	target.AfterburnerFuelLeft = buffer
end

--- Triggers the jump-to-ship cutscene and call swapShips() on the player and the target ship.
--- @param targetShip : ship handle
function jumpToShip(targetShip)
	local cam = gr.createCamera("jumpCam")
	local playerShip = mn.Ships[0]
	cam.Position = playerShip.Position
	local vector = playerShip.Position:getCrossProduct(targetShip.Position)
	gr:setCamera(cam)
	
	-- face target ship
	cam.setOrientation(vector:getOrientation(), 0.5)
	
	-- go to target ship
	cam.setPosition(targetShip.Position, 1.5, 0.3, 0.1)
	
	-- fade out
	mn.evaluateSEXP([[
		(when (true)
			(fade-out 200)
		)
	]])
	
	-- swap ships
	swapShips(playerShip, targetShip)
	
	-- reset camera
	gr:setCamera()
	
	-- fade in
	mn.evaluateSEXP([[
		(when (true)
			(fade-in 100)
		)
	]])
end

--- Called whenever the player needs to respawn
function respawn()
	if spawnTickets > 0 then
		local targetWing = nil
		local targetShip = nil
		
		for i = 0, #validWings do
			--go through ships in wing
		end
		
		if (targetShip == nil) then
			-- trigger warp in
		else
			mn.runSEXP("set-time-compression !0.01!")
			jumpToShip(targetShip)
			mn.runSEXP("set-time-compression !1.0!")
		end
	end
end

-- idea:
-- var: spawn-tickets
-- when reaching 1% hull, trigger respawn function
--   if spawn-tickets > 0
--     if friendly fighters in wing
--       select target ship
--       freeze & jump to that fighter
--     else
--       create warp in effect & respawn the player there


-- also: parse spawn data from separate files? call parser method & file via script eval? getMissionFileName() + .stuff
