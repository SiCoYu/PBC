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