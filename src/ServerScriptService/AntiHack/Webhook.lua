local HttpService=game:GetService("HttpService")
local W={};W.__index=W
function W.new(config)return setmetatable({Config=config,Last=0},W)end
function W:Send(event,d)
 if not self.Config.Webhook.Enabled or self.Config.Webhook.Url==""or os.clock()-self.Last<(self.Config.Webhook.Cooldown or 10)then return false end
 self.Last=os.clock()
 local payload={username="AntiHack",embeds={{title="ANTI-CHEAT ALERT",description=tostring(event),fields={{name="Player",value=tostring(d.PlayerName or"?")},{name="UserId",value=tostring(d.UserId or"?")},{name="Detection",value=tostring(d.Detection or"?")},{name="Risk",value=tostring(d.RiskScore or 0)},{name="Action",value=tostring(d.Action or"Log")}}}}}
 task.spawn(function()pcall(function()HttpService:RequestAsync({Url=self.Config.Webhook.Url,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)})end)end)
 return true
end
return W
