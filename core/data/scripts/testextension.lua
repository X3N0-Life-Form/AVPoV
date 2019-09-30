
filePath = "data/config/"



function readFile(fileName)
	if cf.fileExists(fileName, filePath, true) then
		local file = cf.openFile(fileName, "r", filePath)
		ba.print("[testextension.lua] Reading file: "..fileName)
		
		local line = file:read("*l")
		
		while (not (line == nil)) do
			ba.print("[testextension.lua] "..line.."\n")
			line = file:read("*l")
		end
	else
		ba.print("[testextension.lua] File not found: "..fileName)
	end
end


readFile("test.tbl")
readFile("test.tbm")
readFile("test.xml")
readFile("test.csv")