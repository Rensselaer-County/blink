return [[local Invocations = 0

local SendSize = 64
local SendOffset = 0
local SendCursor = 0
local SendBuffer = buffer.create(64)
local SendInstances = {}

local RecieveCursor = 0
local RecieveBuffer = buffer.create(64)

local RecieveInstances = {}
local RecieveInstanceCursor = 0

local Null = newproxy()

--> Internal types are function scoped so user types exported at the top level can never collide with them
--> A do block isn't enough, forward declared locals lose their inferred function types
local Save, Load, CreateQueue, Pop, Push = (function()
    type Entry = {
        value: any,
        next: Entry?
    }

    type Queue = {
        head: Entry?,
        tail: Entry?
    }

    type BufferSave = {
        Size: number,
        Cursor: number,
        Buffer: buffer,
        Instances: {Instance}
    }

    local function Save(): BufferSave
        return {
            Size = SendSize,
            Cursor = SendCursor,
            Buffer = SendBuffer,
            Instances = SendInstances
        }
    end

    local function Load(Save: BufferSave?)
        if Save then
            SendSize = Save.Size
            SendCursor = Save.Cursor
            SendOffset = Save.Cursor
            SendBuffer = Save.Buffer
            SendInstances = Save.Instances
            return
        end

        SendSize = 64
        SendCursor = 0
        SendOffset = 0
        SendBuffer = buffer.create(64)
        SendInstances = {}
    end

    local function CreateQueue(): Queue
        return {
            head = nil,
            tail = nil
        }
    end

    local function Pop(queue: Queue): any
        local head = queue.head
        if head == nil then
            return
        end

        queue.head = head.next
        return head.value
    end

    local function Push(queue: Queue, value: any)
        local entry: Entry = {
            value = value,
            next = nil
        }

        if queue.tail ~= nil then
            queue.tail.next = entry
        end

        queue.tail = entry

        if queue.head == nil then
            queue.head = entry
        end
    end

    return Save, Load, CreateQueue, Pop, Push
end)()

local function Read(Bytes: number)
    local Offset = RecieveCursor
    RecieveCursor += Bytes
    return Offset
end

local function Invoke()
    if Invocations == 255 then
        Invocations = 0
    end

    local Invocation = Invocations
    Invocations += 1
    return Invocation
end

local function Uninvoke()
    Invocations -= 1
end

--> Returns the buffer too since growing replaces it, writers keep it in a local
local function Allocate(Bytes: number): (number, buffer)
    local InUse = (SendCursor + Bytes)
    if InUse > SendSize then
        --> Avoid resizing the buffer for every write
        while InUse > SendSize do
            SendSize *= 1.5
        end

        local Buffer = buffer.create(SendSize)
        buffer.copy(Buffer, 0, SendBuffer, 0, SendCursor)
        SendBuffer = Buffer
    end

    SendOffset = SendCursor
    SendCursor += Bytes

    return SendOffset, SendBuffer
end

local function CurrentInstances(): {Instance}
    return SendInstances
end

local function CopySendBuffer(): buffer
    local Buffer = buffer.create(SendCursor)
    buffer.copy(Buffer, 0, SendBuffer, 0, SendCursor)
    return Buffer
end

local Calls = table.create(256)

local Events: any = {
    Reliable = table.create(256),
    Unreliable = table.create(256)
}

local Queue: any = {
    Reliable = table.create(256),
    Unreliable = table.create(256)
}

]]
