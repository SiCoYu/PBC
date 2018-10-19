local path = "E:/SelfWorkSpace/PBC/PBC/protobuf.so"
local f = package.loadlib(path, "luaopen_protobuf_c")
package.path = "?.lua;"
package.cpath = "?.so;"
local GProtobuf = require "protobuf"
require "message"

local serpent = require("serpent")
_G.decode_tb = function(tb)
    return serpent.block(tb,{comment = false,custom = 
        function(tag,head,body,tail)
            if not string.find(body,"%a+") then
                body = string.gsub(body,"[\n%s]", "")
            end
            return string.format('%s%s%s%s',tag,head,body,tail)
        end
    })
end

local function print_r(root)
	local srep = string.rep
	local tconcat = table.concat
	local tinsert = table.insert
	local cache = { [root] = "." }
	local function _dump(t, space, name)
		local temp = {}
		for k, v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				tinsert(temp, "+" .. key .. " {" .. cache[v] .. "}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				tinsert(temp, "+" .. key .. _dump(v, space .. (next(t, k) and "|" or " ") .. srep(" ", #key), new_key))
			else
				tinsert(temp, "+" .. key .. " [" .. tostring(v) .. "]")
			end
		end
		return tconcat(temp, "\n" .. space)
	end

	print(_dump(root, "", ""))
end
-- decode_tb = print_r
-- 第1步Register Proto

RegisterProtocol = {}

local PBFileList =
{
	"protocol",
	"player",
}

local PBFilePath = "%s.pb"

local function GetProtoFullPath(fileName)
	local fixFileName = string.format(PBFilePath,fileName)
	local fullPath = "E:/SelfWorkSpace/PBC/PBC/"..fixFileName
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
				print(buff)
				GProtobuf.register(buff)
			else
				print("Can't find PBFile, name = "..v)
			end
		end
	end
	-- local data = { account = "101", version = "0.0.1", server_id = "192.168.0.1", channel_name = "dummy" }
	local player_list = {}
	local player1 = {uid = "101",career = 1,name = "yxk",level = 10,create_time = 123}
	local player2 = {uid = "102",career = 2,name = "wdg",level = 20,create_time = 456}
	local player3 = {uid = "103",career = 3,name = "gcq",level = 30,create_time = 789}
	table.insert(player_list,player1)
	table.insert(player_list,player2)
	table.insert(player_list,player3)

	local data = {uid = "123", player_list = player_list}

	RegisterProtocol.SendNetMsg(110001, data)
end

-- 第2步注册消息
local id_to_message = {

	[100001] = "PBLoginREQ",
	[100002] = "PBLoginACK",

	[100003] = "PBHeartBeatREQ",
	[100004] = "PBHeartBeatACK",

	[100005] = "PBCreatePlayerREQ",
	[100006] = "PBCreatePlayerACK",

	[100005] = "PBSelectPlayerREQ",
	[100006] = "PBSelectPlayerACK",

	[100009] = "PBPlayerEnterGameNotify",

	[110001] = "PBUserInfoNOTIFY",


}

local message_to_id = {}

for id, message in pairs(id_to_message) do
	message_to_id[message] = id
end

function get_message_by_id(id)
	return id_to_message[id]
end

function get_id_by_message(message)
	return message_to_id[message]
end

-- 第3步使用Send  PBLoginREQ
-- message PBLoginREQ
-- {
-- 	required string account = 1;
-- 	required string version = 2;
-- 	required string server_id = 3;
-- 	required string channel_name = 4;
-- }

--第4步发送 SendHandle

function RegisterProtocol.SendNetMsg(msgId, data)
	local msg = nil
	local pack = nil
	if data ~= nil then
		local proto = get_message_by_id(msgId)
		if proto == nil then print("Get Message Failed, msgId = "..tostring(msgId)) return end
		local proto_all = "uranus." .. proto
		local payload = GProtobuf.encode(proto_all,data)
		msg = {id = msgId, payload = payload}
	else
		msg = {id = msgId}
	end
	local pack = GProtobuf.encode("uranus.PBMessage", msg)
	local size = #pack
	local str = string.pack(size)
	local package = str..pack
	RegisterProtocol.HandleNew(package)
end

--第5步Receive Handle
function RegisterProtocol.HandleNew(pack)
	local size = #pack
	local content = tostring(pack)
	local s = pack:byte(1)*256+pack:byte(2) --大端方式解析消息头，取得处理msg的长度
	local body = pack:sub(3,2+s)
	local leftpack = pack:sub(3+s)
	if body ~= nil then
		local bodyLength = #body
		local content = tostring(body)
		local msg = GProtobuf.decode("uranus.PBMessage",content)
		local message = get_message_by_id(msg.id)
		if message and msg.payload and string.len(msg.payload) > 0 then
			local t = GProtobuf.decode("uranus." .. message, msg.payload)
			for i,v in ipairs(t.player_list) do
				print("type v = "..type(v))
				print(i.."======"..decode_tb(v))
				print("v.uid = "..v.uid)
				print("v.career = "..v.career)
				print("v.name = "..v.name)
				print("v.level = "..v.level)
				print("v.create_time = "..v.create_time)
			end
		end
	end
end

--工具类
-- 大端编码2个字节
function string.pack(num)
	local byte1 = math.floor(num/256)
	local byte2 = num%256
	local char1 = string.char(byte1)
	local char2 = string.char(byte2)
	return char1..char2
end

-- 大端解码2个字节
function string.unpack(str)
	local k1,k2 = string.byte(str,1,2)
	local num1 = tonumber(k1)
	local num2 = tonumber(k2)
	return num1*256+num2
end

RegisterProtocol.Register()