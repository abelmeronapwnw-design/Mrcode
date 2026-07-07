 -- ============================================================
--  SISTEMA DE LLAVES CON VERIFICACIÓN REMOTA (Gist)
--  Integración con ChiperHub - Carga el hub tras validar la llave
-- ============================================================

-- ⚠️ COMPLETA ESTOS DOS DATOS CON LOS TUYOS ⚠️
local GIST_ID = "d0801495daa4d6b52aa4f0f101d03946"
local GITHUB_TOKEN = ""  -- ← AÑADE TU TOKEN AQUÍ

local function getHubContent()
    local url = "https://api.github.com/repos/abelmeronapwnw-design/Mrcode/contents/ChiperPremium"
    local headers = {
        ["Authorization"] = "token " .. GITHUB_TOKEN,
        ["Accept"] = "application/vnd.github.v3.raw"
    }
    local ok, response = pcall(function()
        return HttpService:GetAsync(url, true, headers)
    end)
    if ok then
        return response
    end
    return nil
end

-- Colores (misma temática que tu hub)
local KEY_COLORS = {
    BG = Color3.fromRGB(8, 8, 15),
    PANEL = Color3.fromRGB(12, 12, 18),
    CARD = Color3.fromRGB(14, 14, 24),
    ACCENT = Color3.fromRGB(99, 102, 241),
    PURPLE = Color3.fromRGB(139, 92, 246),
    ICE = Color3.fromRGB(56, 189, 248),
    TEXT = Color3.fromRGB(235, 235, 245),
    SECONDARY = Color3.fromRGB(165, 165, 185),
    STROKE = Color3.fromRGB(30, 30, 45),
    OFF = Color3.fromRGB(22, 22, 32)
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local TS = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Función para mostrar error (shake + flash) - CORREGIDA
local function showError(box, btn, label, msg)
    label.Text = msg or "❌ Clave incorrecta"
    label.TextColor3 = Color3.fromRGB(255, 70, 70)
    -- Guardar la posición original UNA SOLA VEZ
    local origPos = UDim2.new(box.Position.X.Scale, box.Position.X.Offset, box.Position.Y.Scale, box.Position.Y.Offset)
    for i = 1, 4 do
        local offset = (i % 2 == 0) and 8 or -8
        TS:Create(box, TweenInfo.new(0.06, Enum.EasingStyle.Linear), {
            Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + offset, origPos.Y.Scale, origPos.Y.Offset)
        }):Play()
        task.wait(0.06)
    end
    -- Restaurar SIEMPRE a la posición original guardada
    TS:Create(box, TweenInfo.new(0.06), {Position = origPos}):Play()
    task.wait(0.1)
    label.Text = "🔑 Ingresa tu llave"
    label.TextColor3 = KEY_COLORS.TEXT
end

-- Función para leer el Gist
local function getGistContent()
    local url = "https://api.github.com/gists/" .. GIST_ID
    local headers = {
        ["Authorization"] = "token " .. GITHUB_TOKEN,
        ["Accept"] = "application/vnd.github.v3+json"
    }
    local ok, response = pcall(function()
        return HttpService:GetAsync(url, false, headers)
    end)
    if not ok then return nil end
    local data = HttpService:JSONDecode(response)
    if data and data.files and data.files["keys.json"] then
        return data.files["keys.json"].content
    end
    return nil
end

-- Función para actualizar el Gist
local function updateGistContent(newContent)
    local url = "https://api.github.com/gists/" .. GIST_ID
    local headers = {
        ["Authorization"] = "token " .. GITHUB_TOKEN,
        ["Accept"] = "application/vnd.github.v3+json",
        ["Content-Type"] = "application/json"
    }
    local payload = {
        files = {
            ["keys.json"] = {
                content = newContent
            }
        }
    }
    local body = HttpService:JSONEncode(payload)
    local ok, response = pcall(function()
        return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false, headers)
    end)
    return ok
end

-- Función para validar la llave
local function validateKey(input, label, box, btn)
    local content = getGistContent()
    if not content then
        showError(box, btn, label, "❌ Error al conectar con el servidor")
        return
    end

    local keysData = HttpService:JSONDecode(content)
    if not keysData then
        showError(box, btn, label, "❌ Error al leer las llaves")
        return
    end

    local foundKey = nil
    local foundIndex = nil
    for i, entry in ipairs(keysData) do
        if entry.key == input then
            foundKey = entry
            foundIndex = i
            break
        end
    end

    if not foundKey then
        showError(box, btn, label, "❌ Llave no válida")
        return
    end

    if foundKey.used then
        local user = foundKey.user or "desconocido"
        showError(box, btn, label, "❌ Llave ya usada por " .. user)
        return
    end

    foundKey.used = true
    foundKey.user = LP.Name .. " (" .. LP.UserId .. ")"
    keysData[foundIndex] = foundKey

    local newContent = HttpService:JSONEncode(keysData)
    local success = updateGistContent(newContent)
    if not success then
        showError(box, btn, label, "❌ Error al actualizar el servidor")
        return
    end

    local screen = box:FindFirstAncestorOfClass("ScreenGui")
    if screen then
        TS:Create(screen, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.35)
        screen:Destroy()
    end

    local hubContent = getHubContent()
    if hubContent then
        local successLoad, err = pcall(function()
            loadstring(hubContent)()
        end)
        if not successLoad then
            warn("Error al cargar el hub: " .. tostring(err))
        end
    else
        warn("Error al obtener el contenido del hub")
    end
end

-- Crear la interfaz de la llave
local function createKeyGui()
    local old = CoreGui:FindFirstChild("ChiperKeyScreen")
    if old then old:Destroy() end

    local screen = Instance.new("ScreenGui")
    screen.Name = "ChiperKeyScreen"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 100
    screen.IgnoreGuiInset = true
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(screen) end
    end)
    screen.Parent = CoreGui

    local backdrop = Instance.new("Frame", screen)
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0

    local W, H = 320, 180
    local panel = Instance.new("Frame", screen)
    panel.Size = UDim2.new(0, W, 0, H)
    panel.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    panel.BackgroundColor3 = KEY_COLORS.BG
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = KEY_COLORS.ACCENT
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    local gradStroke = Instance.new("UIGradient", stroke)
    gradStroke.Color = ColorSequence.new(KEY_COLORS.ACCENT, KEY_COLORS.ICE)
    gradStroke.Rotation = 45

    local title = Instance.new("TextLabel", panel)
    title.Size = UDim2.new(1, -40, 0, 36)
    title.Position = UDim2.new(0, 20, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "🔑 ACCESO AL HUB"
    title.TextColor3 = KEY_COLORS.TEXT
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    local titleGrad = Instance.new("UIGradient", title)
    titleGrad.Color = ColorSequence.new(KEY_COLORS.ACCENT, KEY_COLORS.ICE)

    local label = Instance.new("TextLabel", panel)
    label.Size = UDim2.new(1, -40, 0, 22)
    label.Position = UDim2.new(0, 20, 0, 62)
    label.BackgroundTransparency = 1
    label.Text = "🔑 Ingresa tu llave"
    label.TextColor3 = KEY_COLORS.TEXT
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", panel)
    box.Size = UDim2.new(1, -40, 0, 44)
    box.Position = UDim2.new(0, 20, 0, 92)
    box.BackgroundColor3 = KEY_COLORS.CARD
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = "Escribe la clave..."
    box.TextColor3 = KEY_COLORS.TEXT
    box.PlaceholderColor3 = KEY_COLORS.SECONDARY
    box.Font = Enum.Font.GothamBold
    box.TextSize = 18
    box.ClearTextOnFocus = true
    box.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)
    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Color = KEY_COLORS.ACCENT
    boxStroke.Thickness = 1.5
    boxStroke.Transparency = 0.4
    local boxGrad = Instance.new("UIGradient", boxStroke)
    boxGrad.Color = ColorSequence.new(KEY_COLORS.ACCENT, KEY_COLORS.ICE)
    boxGrad.Rotation = 0

    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(0, 110, 0, 44)
    btn.Position = UDim2.new(1, -130, 0, 92)
    btn.BackgroundColor3 = KEY_COLORS.ACCENT
    btn.BorderSizePixel = 0
    btn.Text = "ENTER"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 16
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    local btnGrad = Instance.new("UIGradient", btn)
    btnGrad.Color = ColorSequence.new(KEY_COLORS.ACCENT, KEY_COLORS.PURPLE)
    btnGrad.Rotation = 35
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(255, 180, 230)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.4

    btn.MouseEnter:Connect(function()
        TS:Create(btnStroke, TweenInfo.new(0.12), {Transparency = 0.05}):Play()
        TS:Create(btn, TweenInfo.new(0.12), {Size = UDim2.new(0, 114, 0, 46), Position = UDim2.new(1, -134, 0, 91)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btnStroke, TweenInfo.new(0.12), {Transparency = 0.4}):Play()
        TS:Create(btn, TweenInfo.new(0.12), {Size = UDim2.new(0, 110, 0, 44), Position = UDim2.new(1, -130, 0, 92)}):Play()
    end)

    local function onValidate()
        local input = box.Text:gsub("%s+", "")
        if input == "" then
            showError(box, btn, label, "⚠️ Ingresa un código")
            return
        end
        validateKey(input, label, box, btn)
    end

    btn.Activated:Connect(onValidate)
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then onValidate() end
    end)

    panel.BackgroundTransparency = 1
    panel.Size = UDim2.new(0, W * 0.8, 0, H * 0.8)
    panel.Position = UDim2.new(0.5, -W * 0.4, 0.5, -H * 0.4)
    TS:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        Size = UDim2.new(0, W, 0, H),
        Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    }):Play()

    return screen
end

createKeyGui()
