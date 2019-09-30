--[[
	----------------------------------
	-- Shivan HUD activation script --
	----------------------------------
	This script activate Shivan-specific elements of the HUD.
]]

function activateShivanHUD()
	mn.evaluateSEXP([[( when
	( true )
	( hud-set-custom-gauge-active 
      ( true ) 
      "ShivTaskStatusTop" 
      "ShivTaskStatusBody1" 
      "ShivTaskStatusBody2" 
      "ShivTaskStatusBody3" 
      "ShivTaskStatusBottom" 
   )
)]])
	gr.Cameras[0].FOV = 0.80
	gr.setPostEffect("saturation", 200)
end