--
-- Title:     Initialize-Environment.ps1
-- Author:    Jourdan Templeton
-- Blog:      http://blog.jourdant.me
-- Email:     hello@jourdant.me
-- Modified:  19/01/2015 08:27PM NZDT
--

print("init.lua")
print("")
print(" _                       _             ")
print("| |                     | |            ")
print("| |_ ___ _ __ ___  _ __ | | ___   __ _ ")
print("| __/ _ \\ '_ ` _ \\| '_ \\| |/ _ \\ / _` |")
print("| ||  __/ | | | | | |_) | | (_) | (_| |")
print(" \\__\\___|_| |_| |_| .__/|_|\\___/ \\__, |")
print("                  | |             __/ |")
print("                  |_|            |___/ ")
print("")
print(" jourdan templeton - 2015")
print(" http://blog.jourdant.me")
print("")
print("")

-- log() : prints out to the console in a consistent format
function log (name, func, msg) print("    ["..name.."] ("..func..")  "..msg) end

--show heap size
log("SYS ", "HEAP", "Size: "..node.heap())

--list filesystem
log("FS  ", "LIST", "Listing files at /")
l = file.list()
for k,v in pairs(l) do
	print("        "..string.format("%-15s", "'"..k.."'").."["..v.."k]")
end
l=nil

--connect to wifi
network = "NETWORK.NAME"
password = "XXXXXXXXXX"

log("WIFI", "CONN", "Connecting to '"..network.."'")
wifi.setmode(wifi.STATION)
wifi.sta.config(network, password)
wifi.sta.connect()

tmr.alarm(1, 1000, 1, function() 
	if wifi.sta.getip()== nil then 
		log("WIFI", "DHCP", "Waiting for IP assignment")
	else 
		tmr.stop(1)
		log("WIFI", "CONN", "Connected to '"..network.."' - "..wifi.sta.getip())
		
		--launch main program
		collectgarbage("collect")
		log("SYS ", "HEAP", "Size: "..node.heap())
		log("INIT", "LOAD", "Bootstrap complete")
		
		--run main program - if it exists
		f = file.open("program.lua", "r")
		if (f ~= nil) then
			f = nil
			file.close()
			log("INIT", "LOAD", "Loading 'program.lua'\r\n")
			dofile("program.lua")
		else 
			log("INIT", "LOAD", "'program.lua' does not exist")
		end
    end 
 end)
 