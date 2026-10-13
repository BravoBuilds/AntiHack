local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local heartbeat=ReplicatedStorage:WaitForChild("AntiHack"):WaitForChild("Remotes"):WaitForChild("Heartbeat")
local seq=0
while player.Parent do seq+=1;pcall(function()heartbeat:FireServer(seq)end);task.wait(8)end
