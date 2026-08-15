local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Trạng thái điều khiển
local Settings = {
    Flying = false,
    Direction = 0,
    Speed = 10,
    Mult = 3,
    ESP = false,
    LagFix = false
}

-- Hàm lấy phần tàu đang ngồi
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

-- Hàm dọn dẹp vật lý để trả lại trọng lực bình thường
local function cleanupPhysics(part)
    if part then
        if part:FindFirstChild("IY_Gyro") then part.IY_Gyro:Destroy() end
        if part:FindFirstChild("IY_Vel") then part.IY_Vel:Destroy() end
        if part:FindFirstChild("FloatFix") then part.FloatFix:Destroy() end
    end
end

-- Khởi tạo ScreenGui duy nhất chứa 2 Bảng
local sg = Instance.new("ScreenGui")
sg.Name = "IY_Vehicle_Master"
pcall(function() sg.Parent = (gethui and gethui()) or game.CoreGui end)
if not sg.Parent then sg.Parent = player:WaitForChild("PlayerGui") end

-- Hàm tạo Panel có chức năng Thu Gọn
local function createPanel(pos, titleText, icon)
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 160, 0, 220)
    frame.Position = pos
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.Active = true
    frame.Draggable = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local titleBar = Instance.new("Frame", frame)
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    titleLabel.Text = icon .. " " .. titleText
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.SourceSansBold

    local minBtn = Instance.new("TextButton", titleBar)
    minBtn.Size = UDim2.new(0.3, 0, 1, 0)
    minBtn.Position = UDim2.new(0.7, 0, 0, 0)
    minBtn.Text = "➖"
    minBtn.BackgroundTransparency = 1
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

    local content = Instance.new("Frame", frame)
    content.Size = UDim2.new(1, 0, 0, 180)
    content.Position = UDim2.new(0, 0, 0, 35)
    content.BackgroundTransparency = 1

    minBtn.MouseButton1Click:Connect(function()
        content.Visible = not content.Visible
        frame.Size = content.Visible and UDim2.new(0, 160, 0, 220) or UDim2.new(0, 160, 0, 32)
    end)
    return content
end

-- Tạo 2 Bảng riêng biệt
local ctrlPanel = createPanel(UDim2.new(0.05, 0, 0.3, 0), "CTRL", "🎮")
local espPanel = createPanel(UDim2.new(0.25, 0, 0.3, 0), "ESP", "👁️")

-- Hàm tạo Nút bấm
local function makeBtn(parent, text, pos, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Text = text; btn.Size = UDim2.new(0.9, 0, 0.18, 0); btn.Position = pos
    btn.BackgroundColor3 = color; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- === BẢNG 1: CTRL (ĐIỀU KHIỂN TÀU) ===
local speedBox = Instance.new("TextBox", ctrlPanel)
speedBox.Size = UDim2.new(0.9, 0, 0.18, 0); speedBox.Position = UDim2.new(0.05, 0, 0.02, 0)
speedBox.PlaceholderText = "Tốc độ"; speedBox.Text = "10"
speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50); speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 5)
speedBox.FocusLost:Connect(function() Settings.Speed = tonumber(speedBox.Text) or 10 end)

makeBtn(ctrlPanel, "⬆️ TIẾN", UDim2.new(0.05, 0, 0.24, 0), Color3.fromRGB(0, 120, 215), function()
    Settings.Flying = true
    Settings.Direction = 1
end)

makeBtn(ctrlPanel, "⬇️ LÙI", UDim2.new(0.05, 0, 0.46, 0), Color3.fromRGB(80, 80, 100), function()
    Settings.Flying = true
    Settings.Direction = -1
end)

makeBtn(ctrlPanel, "⏹️ DỪNG", UDim2.new(0.05, 0, 0.68, 0), Color3.fromRGB(180, 40, 40), function()
    Settings.Flying = false
    Settings.Direction = 0
    cleanupPhysics(getVehiclePart()) -- Trả lại trọng lực ngay khi nhấn Dừng
end)

-- === BẢNG 2: ESP & FIX LAG ===
local espBtn = makeBtn(espPanel, "ESP: TẮT", UDim2.new(0.05, 0, 0.05, 0), Color3.fromRGB(100, 100, 100), function()
    Settings.ESP = not Settings.ESP
    espBtn.Text = Settings.ESP and "ESP: BẬT" or "ESP: TẮT"
    espBtn.BackgroundColor3 = Settings.ESP and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
    
    if not Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("ESP_Tag") then
                p.Character.Head.ESP_Tag:Destroy()
            end
        end
    end
end)

local lagBtn = makeBtn(espPanel, "FIX LAG: TẮT", UDim2.new(0.05, 0, 0.28, 0), Color3.fromRGB(100, 100, 100), function()
    Settings.LagFix = not Settings.LagFix
    lagBtn.Text = Settings.LagFix and "FIX LAG: BẬT" or "FIX LAG: TẮT"
    lagBtn.BackgroundColor3 = Settings.LagFix and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
    
    Lighting.GlobalShadows = not Settings.LagFix
    Lighting.EnvironmentDiffuseScale = Settings.LagFix and 0 or 1
    Lighting.EnvironmentSpecularScale = Settings.LagFix and 0 or 1
end)

-- === VÒNG LẶP XỬ LÝ CHÍNH ===
RunService.RenderStepped:Connect(function()
    -- ESP Logic
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                if not head:FindFirstChild("ESP_Tag") then
                    local bg = Instance.new("BillboardGui", head); bg.Name = "ESP_Tag"; bg.AlwaysOnTop = true; bg.Size = UDim2.new(0, 200, 0, 50)
                    local lbl = Instance.new("TextLabel", bg); lbl.Name = "Label"; lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.new(1,0,0)
                end
                local dist = math.floor((player.Character.Head.Position - head.Position).Magnitude)
                head.ESP_Tag.Label.Text = p.Name .. " [" .. dist .. "m]"
            end
        end
    end
    
    -- Vận hành tàu & Trọng lực
    local part = getVehiclePart()
    if Settings.Flying and part then
        -- Khóa góc quay
        local gyro = part:FindFirstChild("IY_Gyro") or Instance.new("BodyGyro", part)
        gyro.Name = "IY_Gyro"; gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); gyro.P = 10000
        
        -- Tạo lực đẩy di chuyển
        local vel = part:FindFirstChild("IY_Vel") or Instance.new("BodyVelocity", part)
        vel.Name = "IY_Vel"; vel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        
        -- Tạo lực chống chìm tàu khi đang di chuyển
        local bf = part:FindFirstChild("FloatFix") or Instance.new("BodyForce", part)
        bf.Name = "FloatFix"
        bf.Force = Vector3.new(0, workspace.Gravity * part:GetMass(), 0)
        
        local camLook = camera.CFrame.LookVector
        local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit 
        gyro.CFrame = CFrame.lookAt(part.Position, part.Position + flatLook)
        
        vel.Velocity = flatLook * (Settings.Speed * Settings.Mult * Settings.Direction)
    else
        -- Trả lại trọng lực và cơ chế mặc định khi DỪNG
        cleanupPhysics(part)
    end
end)
