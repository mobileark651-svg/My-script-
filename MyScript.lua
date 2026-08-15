local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Trạng thái điều khiển
local Settings = {
    Flying = false,
    ESP = false,
    LagFix = false,
    Speed = 10,
    Mult = 3
}

-- Hàm tạo UI (Đảm bảo các nút luôn nằm trên cùng)
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "IY_Vehicle_Debug"

local function createPanel(name, pos, title)
    local frame = Instance.new("Frame", sg)
    frame.Name = name; frame.Size = UDim2.new(0, 150, 0, 150); frame.Position = pos
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); frame.Active = true; frame.Draggable = true
    Instance.new("UICorner", frame)
    local t = Instance.new("TextLabel", frame); t.Size = UDim2.new(1,0,0,30); t.Text = title; t.TextColor3 = Color3.new(1,1,1)
    t.BackgroundTransparency = 1
    return frame
end

local ctrlPanel = createPanel("CTRL", UDim2.new(0.05, 0, 0.3, 0), "CTRL")
local espPanel = createPanel("ESP", UDim2.new(0.2, 0, 0.3, 0), "ESP & LAG")

-- Nút bấm với kiểm tra
local function makeBtn(parent, text, pos, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Text = text; btn.Size = UDim2.new(0.9, 0, 0, 30); btn.Position = pos
    btn.BackgroundColor3 = color; btn.TextColor3 = Color3.new(1,1,1); btn.ZIndex = 2
    btn.MouseButton1Click:Connect(function()
        print("Đã bấm nút: " .. text) -- Debug: Kiểm tra xem có nhận lệnh không
        callback()
    end)
    return btn
end

-- Bảng CTRL
local speedBox = Instance.new("TextBox", ctrlPanel); speedBox.Size = UDim2.new(0.9, 0, 0, 30); speedBox.Position = UDim2.new(0.05, 0, 0.2, 0); speedBox.Text = "10"
speedBox.FocusLost:Connect(function() Settings.Speed = tonumber(speedBox.Text) or 10 end)

makeBtn(ctrlPanel, "TIẾN", UDim2.new(0.05, 0, 0.5, 0), Color3.fromRGB(0, 100, 200), function() Settings.Flying = true end)
makeBtn(ctrlPanel, "DỪNG", UDim2.new(0.05, 0, 0.7, 0), Color3.fromRGB(200, 50, 50), function() Settings.Flying = false end)

-- Bảng ESP & FIX LAG (Logic mới trực tiếp)
local espBtn = makeBtn(espPanel, "ESP: TẮT", UDim2.new(0.05, 0, 0.3, 0), Color3.fromRGB(100, 100, 100), function()
    Settings.ESP = not Settings.ESP
    espBtn.Text = Settings.ESP and "ESP: BẬT" or "ESP: TẮT"
    espBtn.BackgroundColor3 = Settings.ESP and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
    if not Settings.ESP then -- Xóa khi tắt
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("ESP_Tag") then
                p.Character.Head.ESP_Tag:Destroy()
            end
        end
    end
end)

local lagBtn = makeBtn(espPanel, "LAG: TẮT", UDim2.new(0.05, 0, 0.6, 0), Color3.fromRGB(100, 100, 100), function()
    Settings.LagFix = not Settings.LagFix
    lagBtn.Text = Settings.LagFix and "LAG: BẬT" or "LAG: TẮT"
    lagBtn.BackgroundColor3 = Settings.LagFix and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
    Lighting.GlobalShadows = not Settings.LagFix
    Lighting.EnvironmentDiffuseScale = Settings.LagFix and 0 or 1
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
                if not p.Character.Head:FindFirstChild("ESP_Tag") then
                    local bg = Instance.new("BillboardGui", p.Character.Head); bg.Name = "ESP_Tag"; bg.AlwaysOnTop = true; bg.Size = UDim2.new(0, 100, 0, 50)
                    local lbl = Instance.new("TextLabel", bg); lbl.Size = UDim2.new(1,0,1,0); lbl.TextColor3 = Color3.new(1,0,0); lbl.BackgroundTransparency = 1
                end
                p.Character.Head.ESP_Tag.TextLabel.Text = p.Name
            end
        end
    end
    
    if Settings.Flying then
        local char = player.Character
        if char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.SeatPart then
            local part = char.Humanoid.SeatPart
            if not part:FindFirstChild("IY_Vel") then 
                local v = Instance.new("BodyVelocity", part); v.Name = "IY_Vel"; v.MaxForce = Vector3.new(math.huge, math.huge, math.huge) 
            end
            part.IY_Vel.Velocity = camera.CFrame.LookVector * (Settings.Speed * Settings.Mult)
        end
    end
end)
