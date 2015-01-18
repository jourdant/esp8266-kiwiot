--
-- Title:     Initialize-Environment.ps1
-- Author:    Jourdan Templeton
-- Email:     hello@jourdant.me
-- Modified:  18/01/2015 05:52PM NZDT
--

-- log() : prints out to the console in a consistent format
function log (name, func, msg) print("    ["..name.."] ("..func..")  "..msg) end

-- getTemp() : Reads temperature from DS18B20 1-wire temperature sensor
-- default to pin 4 (GPIO2) to ensure compatibility with ESP-01
function get_temp()
	pin = 4
	ow.setup(pin)
	count = 0
	repeat
		count = count + 1
		addr = ow.reset_search(pin)
		addr = ow.search(pin)
		tmr.wdclr()
	until((addr ~= nil) or (count > 100))
		if (addr ~= nil) then
		crc = ow.crc8(string.sub(addr,1,7))
		if (crc == addr:byte(8)) then
			if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
				repeat
					ow.reset(pin)
					ow.select(pin, addr)
					ow.write(pin, 0x44, 1)
					tmr.delay(1000000)
					present = ow.reset(pin)
					ow.select(pin, addr)
					ow.write(pin,0xBE,1)
					data = nil
					data = string.char(ow.read(pin))
					for i = 1, 8 do
						data = data .. string.char(ow.read(pin))
					end
					
					crc = ow.crc8(string.sub(data,1,8))
					if (crc == data:byte(9)) then
						t = (data:byte(1) + data:byte(2) * 256) * 625
						t1 = t / 10000
						t2 = t % 10000
						ret = t1.."."..t2..
						log("TEMP", "READ", ret.." degrees celsius")
						return ret
					end
					tmr.wdclr()
				until false
			else log("TEMP", "ERR ", "Device family is not recognized")
			end
		else log("TEMP", "ERR ", "CRC is not valid")
		end
	end
end

-- http_post() : Sends HTTP POST request to Azure
function http_post()
	temp = get_temp()
	
	if (temp ~= nil) then
		sensor_id = 1
		hostname = "XXXX.azure-mobile.net"
		data = "sensor_id="..sensor_id.."&temperature="..temp
		packet = "POST /tables/temperature HTTP/1.1\r\n"
			   .."Host: "..hostname.."\r\n"
			   .."X-ZUMO-APPLICATION: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\r\n"
			   .."Connection: close\r\n"
			   .."Content-Type: application/x-www-form-urlencoded\r\n"
			   .."Content-Length: "..string.len(data).."\r\n\r\n"	
			   ..data
			 
		log("HTTP", "POST", ">\r\n"..packet.."\r\n")
		 
		conn=net.createConnection(net.TCP, 0)
		conn:on("receive", function(conn, payload) log("HTTP", "RESP", ">\r\n"..payload.."\r\n") end)
		--update IP address by nslookup on your XXXX.azure-mobile.net
		--after DNS bug is fixed, this won't be needed.
		conn:connect(80, "XXX.XXX.XXX.XXX")
		conn:send(packet)
		log("HTTP", "POST", "Complete")
	else 
		log("TEMP", "READ", "No temperature could be read.")
	end
end

--start timer to upload temperature every 5 min
tmr.alarm(2, 300000, 1, http_post)

--start telnet server
log("TLNT", "LSTN", "Listening for connections on "..wifi.sta.getip()..":23 ")
s=net.createServer(net.TCP, 180)
s:listen(23, function(c)
   function s_output(str)
	  if(c~=nil)
		 then c:send(str)
	  end
   end
   node.output(s_output, 0)
   c:on("receive", function(c,l)
	  node.input(l)
   end)
   c:on("disconnection", function(c)
	  node.output(nil)
   end)
end)

--post on startup
http_post()