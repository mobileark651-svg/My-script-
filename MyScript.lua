local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = game:GetService("Workspace"):FindFirstChildOfClass("Terrain")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local isFlying = false
local speed = 80
local direction = 1
local dragFactor = 1.0
local isLagFixed = false

-- Lấy phần thân chính của phương tiện/tàu
local function getVehiclePart()
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        local seat = humanoid.SeatPart
        local ship = seat:FindFirstAncestorOfClass("Model")
        return (ship and ship.PrimaryPart) or seat
    end
    return nil
end

-- Chiếm quyền kiểm soát mạng của Part để không bị giật lag
local function claimNetworkOwnership(part)
    pcall(function()
        if part and part.SetNetworkOwner then
            part:SetNetworkOwner(player)
        end
    end)
end

-- Khởi tạo Giao diện Gui
local sg = Instance.new("ScreenGui")
sg.Name = "IY_VehicleFly_Clean"
pcall(function() sg.Parent = game.CoreGui end)
if not sg.Parent then sg.Parent = player:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 180, 0, 340)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "🚁 IY VEHICLE FLY"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
local titleCorner = Instance.new("UICorner", title)
titleCorner.CornerRadius = UDim.new(0, 8)

local speedBox = Instance.new("TextBox", frame)
speedBox.Size = UDim2.new(0.9, 0, 0.1, 0)
speedBox.Position = UDim2.new(0.05, 0, 0.11, 0)
speedBox.PlaceholderText = "Nhập Speed"
speedBox.Text = "80"
speedBox.TextColor3 = Color3.fromRGB(0, 255, 150)
speedBox.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
speedBox.Font = Enum.Font.Code
speedBox.FocusLost:Connect(function() speed = tonumber(speedBox.Text) or 80 end)

local function makeBtn(text, pos, color)
    local btn = Instance.new("TextButton", frame)
    btn.Text = text
    btn.Size = UDim2.new(0.9, 0, 0.1, 0)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 5)
    return btn
end

-- Nút Fix Lag
local lagBtn = makeBtn("FIX LAG: TẮT", UDim2.new(0.05, 0, 0.24, 0), Color3.fromRGB(100, 100, 100))
lagBtn.MouseButton1Click:Connect(function()
    isLagFixed = not isLagFixed
    if isLagFixed then
        lagBtn.Text = "FIX LAG: BẬT"
        lagBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        pcall(function() Lighting.Technology = Enum.Technology.Compatibility end)
        Lighting.GlobalShadows = false
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        if Terrain then Terrain.WaterWaveSize = 0 end
    else
        lagBtn.Text = "FIX LAG: TẮT"
        lagBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        pcall(function() Lighting.Technology = Enum.Technology.Future end)
        Lighting.GlobalShadows = true
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
        if Terrain then Terrain.WaterWaveSize = 0.15 end
    end
end)

-- Các nút điều khiển TIẾN - LÙI - DỪNG
local btnForward = makeBtn("⬆️ TIẾN", UDim2.new(0.05, 0, 0.42, 0), Color3.fromRGB(0, 120, 215))
btnForward.MouseButton1Click:Connect(function() isFlying = true; direction = 1 end)

local btnBackward = makeBtn("⬇️ LÙI", UDim2.new(0.05, 0, 0.55, 0), Color3.fromRGB(80, 80, 100))
btnBackward.MouseButton1Click:Connect(function() isFlying = true; direction = -1 end)

local btnStop = makeBtn("⏹️ DỪNG", UDim2.new(0.05, 0, 0.68, 0), Color3.fromRGB(180, 40, 40))
btnStop.MouseButton1Click:Connect(function()
    isFlying = false
    local part = getVehiclePart()
    if part then
        if part:FindFirstChild("IY_Gyro") then part.IY_Gyro:Destroy() end
        if part:FindFirstChild("IY_Vel") then part.IY_Vel:Destroy() end
        part.AssemblyLinearVelocity = Vector3.zero
    end
end)

-- ================= VÒNG LẶP DI CHUYỂN IY =================
RunService.Heartbeat:Connect(function()
    local part = getVehiclePart()
    
    if isFlying and part then
        claimNetworkOwnership(part)
        
        -- 1. Tạo/Lấy BodyGyro chuẩn IY
        local gyro = part:FindFirstChild("IY_Gyro")
        if not gyro then
            gyro = Instance.new("BodyGyro")
            gyro.Name = "IY_Gyro"
            gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            gyro.P = 10000
            gyro.Parent = part
        end
        
        -- 2. Tạo/Lấy BodyVelocity chuẩn IY
        local vel = part:FindFirstChild("IY_Vel")
        if not vel then
            vel = Instance.new("BodyVelocity")
            vel.Name = "IY_Vel"
            vel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            vel.Parent = part
        end
        
        -- 3. Tính toán hướng di chuyển (Làm phẳng theo mặt đất, triệt tiêu trục Y)
        local camLook = camera.CFrame.LookVector
        local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
        
        if flatLook.Magnitude > 0 then
            flatLook = flatLook.Unit
            
            -- Xoay phương tiện phẳng theo hướng nhìn
            gyro.CFrame = CFrame.lookAt(part.Position, part.Position + flatLook)
            
            -- Tính vận tốc đẩy
            local targetVel = flatLook * (speed * direction * dragFactor)
            vel.Velocity = targetVel
            part.AssemblyLinearVelocity = targetVel
        end
    else
        -- Dọn dẹp lực khi bấm DỪNG hoặc rời tàu
        if part then
            if part:FindFirstChild("IY_Gyro") then part.IY_Gyro:Destroy() end
            if part:FindFirstChild("IY_Vel") then part.IY_Vel:Destroy() end
        end
    end
end)
