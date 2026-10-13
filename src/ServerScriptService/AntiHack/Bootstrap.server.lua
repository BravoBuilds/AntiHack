local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local root=ReplicatedStorage:FindFirstChild("AntiHack") or Instance.new("Folder");root.Name="AntiHack";root.Parent=ReplicatedStorage
local Config=require(root:WaitForChild("Config"))
local Service=require(script.Parent:WaitForChild("Services")).new(Config)
local Moderation=require(script.Parent:WaitForChild("Moderation")).new(Config)
local Webhook=require(script.Parent:WaitForChild("Webhook")).new(Config)
local remotes=root:FindFirstChild("Remotes") or Instance.new("Folder");remotes.Name="Remotes";remotes.Parent=root
local heartbeat=remotes:FindFirstChild("Heartbeat") or Instance.new("RemoteEvent");heartbeat.Name="Heartbeat";heartbeat.Parent=remotes
local whitelist={};for _,id in ipairs(Config.Whitelist)do local n=tonumber(id);if n then whitelist[n]=true end end
local function trusted(p)return whitelist[p.UserId]==true end
local API={}
function API:AuthorizeTeleport(p,reason,duration)if p then Service:authorize(p,reason,duration)end end
function API:AuthorizeImpulse(p,reason,duration)if p then Service:authorize(p,reason or"impulse",duration or .75)end end
function API:AuthorizeMovementOverride(p,duration)if p then Service:authorize(p,"movement-override",duration)end end
function API:RecordLegitimateAction(p,action)if p then print("[AntiHack] legitimate action",p.Name,tostring(action))end end
function API:Flag(p,detection)
 if p and not trusted(p)then local d,r=Service:detect(p,detection);Webhook:Send("Detection",{PlayerName=p.Name,UserId=p.UserId,Detection=d.Type,Severity=d.Severity,Confidence=d.Confidence,RiskScore=r.Score,Action=r.Action});if r.Action=="PermanentBan"and Config.Punishment.AutoBanEnabled then Moderation:Ban(p,d.Type,nil,Service.E[p])end;return d,r end
end
function API:GetPlayerState(p)local r=Service.R[p]or{};return{Risk=r.score or 0,Signals=r.signals or 0,Evidence=Service.E[p]or{},Session=Service.Q[p]}end
function API:ValidateCombat(p,weapon,target,damage)if trusted(p)then return true end;return Service:combat(p,weapon,target,damage)end
function API:ValidateRemote(p,name,args,rule)if trusted(p)then return true end;local ok,reason=Service:remote(p,name,args,rule);if not ok then Service:detect(p,{Type="RemoteRejected",Category="Remote",Severity=3,Confidence=.86,Evidence={Remote=name,Reason=reason}})end;return ok,reason end
_G.AntiHack=API
heartbeat.OnServerEvent:Connect(function(p,seq)if not trusted(p)then Service:heartbeat(p,seq)end end)
Players.PlayerAdded:Connect(function(p)Service.Q[p]={id=HttpService:GenerateGUID(false),last=os.clock(),seq=0};if Moderation:IsBanned(p.UserId)then p:Kick("You are currently banned from this experience.")end end)
Players.PlayerRemoving:Connect(function(p)Service.R[p]=nil;Service.E[p]=nil;Service.Q[p]=nil;Service.M[p]=nil;Service.X[p]=nil end)
local acc=0
RunService.Heartbeat:Connect(function(dt)acc+=dt;if acc<Config.Movement.SampleInterval then return end;local sample=acc;acc=0;local now=os.clock()
 for _,p in ipairs(Players:GetPlayers())do if not trusted(p)then local s=Service.Q[p];if s and now-(s.last or now)>Config.Session.Timeout then Service:detect(p,{Type="HeartbeatTimeout",Category="Network",Severity=1,Confidence=.35});s.last=now end;Service:movement(p,sample)end end
end)
print("[AntiHack] initialized; server-authoritative mode.")
