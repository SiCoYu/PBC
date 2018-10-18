require "message"
local path = "C:/Users/win10/Desktop/LuaPBC/protobuf.so"
local f = package.loadlib(path, "luaopen_protobuf_c")
package.path = "?.lua;"
package.cpath = "?.so;"
require "protobuf"

RegisterProtocol = {}

local PBFileList = 
{
	"protocol",
	"player",	
}

local PBFilePath = "%s.pb"

local function GetProtoFullPath(fileName)
	local fixFileName = string.format(PBFilePath,fileName)
	local fullPath = "C:/Users/win10/Desktop/LuaPBC/"..fixFileName
	return fullPath
end

local function LoadPBFile(fileName,mode)
	local fullPath = GetProtoFullPath(fileName)
	local file,err = io.open(fullPath,mode)
	if file == nil then
		print(err)
		return nil
	end
	local buff = file:read "*a"
	file:close()
	return buff
end

function RegisterProtocol.Register()
	if PBFileList ~= nil then
		for i,v in ipairs(PBFileList) do
			local buff = LoadPBFile(v,"rb")
			if buff ~= nil then
				-- print(buff)
				GProtobuf.register(buff)
			else
				print("Can't find PBFile, name = "..v)
			end
		end
	end
end

RegisterProtocol.Register()

local data = { account = "101", version = "0.0.1", server_id = "192.168.0.1", channel_name = "dummy" }
local msg = nil
local pack = nil
if data ~= nil then
	msgId = 100001
	local proto = get_message_by_id(msgId)
	if proto == nil then print("Get Message Failed, msgId = "..tostring(msgId)) return end
	local proto_all = "uranus." .. proto
	local payload = GProtobuf.encode(proto_all,data)
	msg = {id = msgId, payload = payload}
else		
	msg = {id = msgId}
end
print(msg)
local pack = GProtobuf.encode("uranus.PBMessage", msg)
