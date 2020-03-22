--[[
	-------------------------------
	-- Waypoint highlight script --
	-------------------------------
	This script is meant to highlight the position of waypoints when debugging a mission.
	Waypoints within the same path will use the same color.
	Additional information such as the waypoint's position  and distance to selected
	target will also be displayed.
]]

------------------------
--- Global Variables ---
------------------------

waypointHighlight_colors = {}

waypointHighlight_enableDebugPrint = true

-----------------------
-- utility functions --
-----------------------

function dPrint_waypointHighlight(message)
	if (waypointHighlight_enableDebugPrint) then
		ba.print("[waypointHighlight.lua] "..message.."\n")
	end
end

----------------------
--- Core functions ---
----------------------

--- Initializes global vars for a mission
function waypointHighlight_init()
	-- Reset global vars
	waypointHighlight_colors = {}
	
	dPrint_waypointHighlight("Initializing highlight colors...")
	for i = 1, #mn.WaypointLists do
		local wpList = mn.WaypointLists[i]
		-- Set waypoint path color
		local red = math.random(255)
		local green = math.random(255)
		local blue = math.random(255)
		waypointHighlight_colors[wpList.Name] = {red, green , blue}
		dPrint_waypointHighlight("\t"..wpList.Name.." : {red="..red.."; green="..green.."; blue="..blue.."}")
	end
end

--- Highlight mission waypoints
--- Must be called per frame
function waypointHighlight_highlight()
	dPrint_waypointHighlight("Beginning waypoint highlight...")
	for i = 1, #mn.WaypointLists do
		local wpList = mn.WaypointLists[i]
		local color = waypointHighlight_colors[wpList.Name]
		dPrint_waypointHighlight("Highlighting "..wpList.Name)
		
		gr.setColor(color[1], color[2], color[3])
		
		for j = 1, #wpList do
			local waypoint = wpList[j]
			local position = waypoint.Position
			-- local coordinates = position:getScreenCoords()
			local coordinates = getScreenCoordsActuallyWorks(position)
			
			if (coordinates) then
				dPrint_waypointHighlight("\tPoint "..j.." ("..coordinates[1]..", "..coordinates[2]..")")
				-- draw sphere & brackets
				-- lol doesn't work on waypoints... (cf.graphics.cpp)
				-- local coordinates = gr.drawTargetingBrackets(waypoint, true)
				
				gr.drawSphere(5.0, waypoint.Position)
					
				-- draw name
				gr.drawString(wpList.Name..":"..j, coordinates[1], coordinates[2]+15)
				
				-- draw coordinates
				gr.drawString("x:"..position[1])
				gr.drawString("y:"..position[2])
				gr.drawString("z:"..position[3])
				
				-- draw distance to waypoint
				local playerShip = mn.Ships[0]
				local distance = playerShip.Position:getDistance(position)
				-- gr.drawString("distance = "..distance)
			else
				dPrint_waypointHighlight("\tPoint "..j.." is offscreen")
			end
		end
		
	end

end

-- cf.g3_rotate_vertex() & g3_project_vertex() in 3dmath.cpp
function getScreenCoordsActuallyWorks(targetPosition)
	dPrint_waypointHighlight("getScreenCoordsActuallyWorks begins")
	-- rotation
	local camera = gr.getCurrentCamera(true)
	-- local tx = targetPosition.x - camera.Position.x
	-- local ty = targetPosition.y - camera.Position.y
	-- local tz = targetPosition.z - camera.Position.z
	-- dPrint_waypointHighlight("\tTarget position: "..targetPosition.x..","..targetPosition.y..","..targetPosition.z)
	-- dPrint_waypointHighlight("\tCamera position: "..camera.Position.x..","..camera.Position.y..","..camera.Position.z)
	-- dPrint_waypointHighlight("\tt vars: "..tx..","..ty..","..tz)

	-- rx = tx * camera.Orientation:getRvec().x
	-- rx = rx + ty * camera.Orientation:getRvec().y
	-- rx = rx + tz * camera.Orientation:getRvec().z

	-- ry = tx * camera.Orientation:getUvec().x
	-- ry = ry + ty * camera.Orientation:getUvec().y
	-- ry = ry + tz * camera.Orientation:getUvec().z

	-- rz = tx * camera.Orientation:getFvec().x;
	-- rz = rz + ty * camera.Orientation:getFvec().y
	-- rz = rz + tz * camera.Orientation:getFvec().z
	-- dPrint_waypointHighlight("\tr vars: "..rx..","..ry..","..rz)
	
	--
	local rvec = camera.Orientation:rotateVector(targetPosition)
	rx = rvec.x
	ry = rvec.y
	rz = rvec.z
	
	-- projection
	local width = gr.getScreenWidth()
	local height = gr.getScreenHeight()
	local w = 1.0 / rz
	dPrint_waypointHighlight("\t"..width.."x"..height)
	dPrint_waypointHighlight("\tw="..w)
	
	local x = (width + (rx * width * w)) * 0.5
	-- local y = (height - (ry * height * w)) * 0.5
	local y = (height - (ry * height * w)) * 0.5
	dPrint_waypointHighlight("\tx="..x..", y="..y)
	return {x, y}
end
