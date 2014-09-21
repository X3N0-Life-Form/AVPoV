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

-- adds the new wing at the 'end' of the array
function addValidWing(wingName)
	local size = #validWings
	validWings[size] = wingName
end

function clearValidWings()
	validWings = {}
end


-------------------------
-- respawn subroutines --
-------------------------

function jumpToShip(targetShip)
	local cam = createCamera("jumpCam")
end

function respawn()
	if spawnTickets > 0 then
		local targetWing = nil
		local targetShip = nil
		
		for i = 0, #validWings do
			--go through ships in wing
		end
		
		--if targetShip = nil then
			-- trigger warp in
		--else
			-- trigger freeze
		--end
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