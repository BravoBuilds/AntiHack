local HttpService=game:GetService("HttpService")
local U=require(game.ReplicatedStorage.AntiHack.Utilities)
local S={};S.__index=S
function S.new(c)return setmetatable({C=c,R={},E={},M={},B={},X={},Q={}},S)end
local function state(t,k)local x=t[k];if not x then x={};t[k]=x end;return x end
function S:detect(p,d)
 d=d or{};d.Type=tostring(d.Type or"Unknown");d.Category=tostring(d.Category or"Other");d.Severity=math.clamp(tonumber(d.Severity)or 1,1,5);d.Confidence=math.clamp(tonumber(d.Confidence)or .5,0,1)
 local r=state(self.R,p);local now=os.clock();r.score=math.max(0,(r.score or 0)-(now-(r.last or now))*self.C.Risk.DecayPerSecond);r.last=now;r.cats=r.cats or{};r.signals=(r.signals or 0)+1
 local w=d.Severity*(.35+d.Confidence);if not r.cats[d.Category]then r.cats[d.Category]=true;w*=1.35 end;r.score=math.clamp(r.score+w,0,1000)
 local n=0;for _ in pairs(r.cats)do n+=1 end;local a="Log"
 if r.score>=self.C.Risk.AutoBanThreshold and n>=self.C.Risk.AutoBanIndependentSignals then a=self.C.Punishment.AutoBanEnabled and"PermanentBan"or"Restrict"elseif r.score>=self.C.Risk.RestrictThreshold then a="Restrict"elseif r.score>=self.C.Risk.FlagThreshold then a="Flag"elseif r.score>=self.C.Risk.WarningThreshold then a="Warn"end
 d.Id=HttpService:GenerateGUID(false);d.PlayerId=p.UserId;d.Timestamp=os.time();d.Action=a;local e=state(self.E,p);table.insert(e,U.Sanitize(d));while #e>self.C.Evidence.MaxTimeline do table.remove(e,1)end
 if self.C.Logging.PrintDetections then print("[AntiHack]",p.Name,d.Type,"risk",r.score,"action",a)end
 return d,{Score=r.score,SignalCount=r.signals,Action=a}
end
function S:remote(p,name,args,rule)
 rule=rule or{};local b=state(self.B,tostring(p.UserId)..":"..tostring(name));local now=os.clock();local win=rule.Window or self.C.RemoteSecurity.DefaultWindow
 b.started=b.started or now;if now-b.started>=win then b.started=now;b.count=0 end;b.count=(b.count or 0)+1
 if b.count>(rule.RateLimit or self.C.RemoteSecurity.DefaultRateLimit)then return false,"RateLimited"end
 if type(args)~="table"or #args>(rule.MaxArguments or self.C.RemoteSecurity.MaxArguments)then return false,"InvalidArgumentCount"end
 for i,t in ipairs(rule.ArgumentTypes or{})do local v=args[i];if t=="number"and not U.IsFiniteNumber(v)then return false,"InvalidNumber"elseif t=="string"and(type(v)~="string"or#v>self.C.RemoteSecurity.MaxStringLength)then return false,"InvalidString"elseif t=="Vector3"and not U.IsFiniteVector3(v)then return false,"InvalidVector3"elseif t=="Instance"and typeof(v)~="Instance"then return false,"InvalidInstance"end end
 return true
end
function S:authorize(p,reason,duration)self.X[p]={untilTime=os.clock()+(duration or self.C.Movement.GraceWindow),reason=tostring(reason or"authorized")}end
function S:heartbeat(p,seq)
 local s=state(self.Q,p);local now=os.clock()
 if type(seq)~="number"or seq%1~=0 or seq<=(s.seq or 0)or seq>(s.seq or 0)+self.C.Session.MaxSequenceJump then self:detect(p,{Type="HeartbeatSequence",Category="Network",Severity=2,Confidence=.72});return false end
 s.seq=seq;s.last=now;return true
end
function S:movement(p,dt)
 if not self.C.Movement.Enabled then return end
 local c=p.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 if not root or not h or h.Health<=0 then self.M[p]=nil;return end
 local s=state(self.M,p);local now=os.clock();if not s.time then s.pos=root.Position;s.vel=root.AssemblyLinearVelocity;s.time=now;s.bad=0;return end
 local ex=self.X[p];if ex and ex.untilTime>now then s.pos=root.Position;s.vel=root.AssemblyLinearVelocity;s.time=now;s.bad=0;return elseif ex then self.X[p]=nil end
 local elapsed=math.max(now-s.time,dt or .25);local vel=root.AssemblyLinearVelocity;local hs=Vector3.new(vel.X,0,vel.Z).Magnitude;local accel=(vel-s.vel).Magnitude/elapsed;local dist=(root.Position-s.pos).Magnitude;local typ,conf
 if dist>self.C.Movement.TeleportDistance then typ,conf="ImpossibleMovement",.94 elseif hs>self.C.Movement.MaxHorizontalSpeed and h:GetState()~=Enum.HumanoidStateType.Freefall then typ,conf="MovementSpeed",.82 elseif math.abs(vel.Y)>self.C.Movement.MaxVerticalSpeed then typ,conf="VerticalVelocity",.78 elseif accel>self.C.Movement.MaxAcceleration then typ,conf="MovementAcceleration",.76 end
 if typ then s.bad+=1 else s.bad=math.max(0,s.bad-1)end
 if typ and s.bad>=self.C.Movement.SuspiciousSamples then self:detect(p,{Type=typ,Category="Movement",Severity=s.bad>=self.C.Movement.HardSamples and 5 or 3,Confidence=conf,Evidence={Distance=dist,HorizontalSpeed=hs,Acceleration=accel,Samples=s.bad}});s.bad=0 end
 s.pos=root.Position;s.vel=vel;s.time=now
end
function S:combat(p,weapon,target,damage)
 local c=p.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local tr=target and target:IsA("Model")and target:FindFirstChild("HumanoidRootPart");local h=target and target:IsA("Model")and target:FindFirstChildOfClass("Humanoid")
 if not root or not tr or not h or h.Health<=0 then self:detect(p,{Type="InvalidTarget",Category="Combat",Severity=3,Confidence=.92});return false end
 local range=(weapon and weapon:GetAttribute("AttackRange"))or self.C.Combat.DefaultRange;local dist=(root.Position-tr.Position).Magnitude
 if dist>range+self.C.Combat.RangeTolerance then self:detect(p,{Type="CombatRange",Category="Combat",Severity=4,Confidence=.96,Evidence={Distance=dist}});return false end
 local s=state(self.Q,p);local now=os.clock();local min=1/self.C.Combat.MaxAttacksPerSecond
 if s.attack and now-s.attack+self.C.Combat.CooldownTolerance<min then self:detect(p,{Type="AttackRate",Category="Combat",Severity=4,Confidence=.9});return false end
 if not U.IsFiniteNumber(tonumber(damage))or damage<=0 or damage>self.C.Combat.MaxDamage then self:detect(p,{Type="InvalidDamage",Category="Combat",Severity=5,Confidence=.99});return false end
 s.attack=now;return true
end
return S
