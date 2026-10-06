return [[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- SPLIT --
local Reliable: RemoteEvent
local Unreliable: UnreliableRemoteEvent

local PlayersMap: {[Player]: typeof(Save())} = {}

local function SendToAll()
    local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
    for _, Player in Players:GetPlayers() do
        Load(PlayersMap[Player])
        local Position = Allocate(Size)
        buffer.copy(SendBuffer, Position, Buffer, 0, Size)
        table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
        PlayersMap[Player] = Save()
    end
end

local function SendToList(List: {Player})
    local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
    for _, Player in List do
        Load(PlayersMap[Player])
        local Position = Allocate(Size)
        buffer.copy(SendBuffer, Position, Buffer, 0, Size)
        table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
        PlayersMap[Player] = Save()
    end
end

local function SendToAllExcept(Except: Player)
    local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
    for _, Player in Players:GetPlayers() do
        if Player == Except then
            continue
        end
        Load(PlayersMap[Player])
        local Position = Allocate(Size)
        buffer.copy(SendBuffer, Position, Buffer, 0, Size)
        table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
        PlayersMap[Player] = Save()
    end
end

local function SendUnreliable(Player: Player)
    local Buffer = CopySendBuffer()
    Unreliable:FireClient(Player, Buffer, SendInstances)
end

local function SendUnreliableToAll()
    local Buffer = CopySendBuffer()
    Unreliable:FireAllClients(Buffer, SendInstances)
end

local function SendUnreliableToList(List: {Player})
    local Buffer = CopySendBuffer()
    for _, Player in List do
        Unreliable:FireClient(Player, Buffer, SendInstances)
    end
end

local function SendUnreliableToAllExcept(Except: Player)
    local Buffer = CopySendBuffer()
    for _, Player in Players:GetPlayers() do
        if Player == Except then
            continue
        end
        Unreliable:FireClient(Player, Buffer, SendInstances)
    end
end

-- SPLIT --
if not RunService:IsServer() then
    error("Server network module can only be required from the server.")
end

Reliable = ReplicatedStorage:FindFirstChild(BASE_EVENT_NAME .. "_RELIABLE_REMOTE") :: RemoteEvent
if not Reliable then
    local RemoteEvent = Instance.new("RemoteEvent")
    RemoteEvent.Name = BASE_EVENT_NAME .. "_RELIABLE_REMOTE"
    RemoteEvent.Parent = ReplicatedStorage
    Reliable = RemoteEvent
end

Unreliable = ReplicatedStorage:FindFirstChild(BASE_EVENT_NAME .. "_UNRELIABLE_REMOTE") :: UnreliableRemoteEvent
if not Unreliable then
    local UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
    UnreliableRemoteEvent.Name = BASE_EVENT_NAME .. "_UNRELIABLE_REMOTE"
    UnreliableRemoteEvent.Parent = ReplicatedStorage
    Unreliable = UnreliableRemoteEvent
end

Players.PlayerRemoving:Connect(function(Player)
    PlayersMap[Player] = nil
end)

local function StepReplication()
    for Player, Send in PlayersMap do
        if Send.Cursor <= 0 then
            continue
        end

        local Buffer = buffer.create(Send.Cursor)
        buffer.copy(Buffer, 0, Send.Buffer, 0, Send.Cursor)
        Reliable:FireClient(Player, Buffer, Send.Instances)

        Send.Size = 64
        Send.Cursor = 0
        Send.Buffer = buffer.create(64)
        table.clear(Send.Instances)
    end
end
]]
