--[[

]]

------------------------
--- Global Variables ---
------------------------

waypointHighlight_colors = {}


----------------------
--- Core functions ---
----------------------

--- Initializes global vars for a mission
function waypointHighlight_init()
	-- Reset global vars
	waypointHighlight_colors = {}
	
	for i = 0, #mn.WaypointLists do
		local wpList = mn.WaypointLists[i]
		-- Set waypoint path color
		local red = math.random(255)
		local green = math.random(255)
		local blue = math.random(255)
		waypointHighlight_colors[wpList.Name] = [red, green , blue]
	end
end

--- Highlight mission waypoints
--- Must be called per frame
function waypointHighlight_highlight()
	for i = 0, #mn.WaypointLists do
		local wpList = mn.WaypointLists[i]
		local color = waypointHighlight_colors[wpList.Name]
		gr.setColor(color[0], color[1], color[2])
		
		for j = 0, #wpList do
			local waypoint = wpList[j]
			local position = waypoint.Position
			
			-- draw sphere & brackets
			local coordinates = gr.drawTargetingBrackets(waypoint, true)
			gr.drawSphere(5.0, waypoint.Position)
			
			-- draw name
			gr.drawString(wpList.Name..":"..j, coordinates[3], coordinates[1])
			
			-- draw coordinates
			gr.drawString("x:"..position[1].." y:"..position[2].." z:"..position[3])
			
			-- draw distance to target
			local playerShip = mn.Ships[0]
			local target = playerShip.Target
			local distance = target.Position.getDistance(position)
			gr.drawString("distance to "..target.Name.." = "..distance)
		end
		
	end

end
