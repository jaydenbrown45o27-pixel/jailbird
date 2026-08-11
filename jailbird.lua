-- =========================================================
-- Lyzn Hub — Crystal-themed UI + Luarmor key auth
-- =========================================================
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Lucide icons
local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"))()
end)
local function lucideProps(name)
	if not Lucide then return nil end
	local ok, asset = pcall(function() return Lucide.GetAsset(name) end)
	if not ok or not asset then return nil end
	return { Image = asset.Url or asset.Id, ImageRectOffset = asset.ImageRectPosition or asset.ImageRectOffset, ImageRectSize = asset.ImageRectSize }
end

local Cfg = {
	WinSize = Vector2.new(800, 580),
	TopH = 56,
	SidebarW = 190,
	ProfileH = 84,
	CrystalLogo = "rbxassetid://78492884826986",
	ScriptId = "cc39c2c657dcac097bac251bc38de8b2",

	-- Colors sampled from the screenshot
	Bg = Color3.fromRGB(15, 15, 20),           -- deep black with slight blue tint
	Panel = Color3.fromRGB(22, 22, 30),        -- row / card
	PanelHi = Color3.fromRGB(30, 30, 40),
	Row = Color3.fromRGB(26, 26, 34),
	TabBar = Color3.fromRGB(18, 18, 24),
	Stroke = Color3.fromRGB(40, 40, 52),
	StrokeSoft = Color3.fromRGB(32, 32, 44),

	Accent = Color3.fromRGB(255, 255, 255),    -- toggles/sliders fill WHITE
	AccentDim = Color3.fromRGB(200, 200, 210),
	Text = Color3.fromRGB(245, 245, 250),
	TextDim = Color3.fromRGB(160, 160, 175),
	TextFaint = Color3.fromRGB(105, 105, 120),

	FontTitle = Enum.Font.Bangers,
	FontBold = Enum.Font.Bangers,
	FontMed = Enum.Font.Bangers,
	FontReg = Enum.Font.Bangers,

	Tween = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Fade = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	MinScale = 0.4,
	ScaleBase = Vector2.new(880, 660),
	ToggleKey = Enum.KeyCode.LeftControl,
}

local function New(cls, props, kids)
	local o = Instance.new(cls)
	for k, v in pairs(props or {}) do if k ~= "Parent" then o[k] = v end end
	if kids then for _, c in ipairs(kids) do c.Parent = o end end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(p, r) return New("UICorner", { CornerRadius = r or UDim.new(0, 10), Parent = p }) end
local function stroke(p, c, t) return New("UIStroke", { Color = c or Cfg.Stroke, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p }) end
local function padding(p, t, b, l, r) return New("UIPadding", { PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or t or 0), PaddingLeft = UDim.new(0, l or t or 0), PaddingRight = UDim.new(0, r or t or 0), Parent = p }) end

-- =========================================================
-- Luarmor key auth
-- =========================================================
local function getExecutorName()
	local ok, n = pcall(function() return identifyexecutor() end)
	if ok and typeof(n) == "string" and n ~= "" then return n end
	ok, n = pcall(function() return getexecutorname() end)
	if ok and typeof(n) == "string" and n ~= "" then return n end
	return "Unknown"
end
local KeyCheckUrl = "https://sdkapi-public.luarmor.net/library.lua"
local function fetchSecondsLeft()
	if typeof(LuarmorExpiry) == "number" then
		if LuarmorExpiry <= 0 or LuarmorExpiry < 1000000000 then return math.huge end
		return LuarmorExpiry - os.time()
	end
	local key = (typeof(script_key) == "string" and script_key ~= "" and script_key)
	         or (typeof(LuarmorKey)  == "string" and LuarmorKey  ~= "" and LuarmorKey)
	         or nil
	if not key then return nil end
	local ld, api = pcall(function() return loadstring(game:HttpGet(KeyCheckUrl))() end)
	if not ld or typeof(api) ~= "table" then return nil end
	api.script_id = Cfg.ScriptId
	local ok, st = pcall(api.check_key, key)
	if not ok or typeof(st) ~= "table" or st.code ~= "KEY_VALID" then return nil end
	local e = tonumber(st.data and st.data.auth_expire)
	if not e then return nil end
	if e <= 0 then return math.huge end
	return e - os.time()
end
local function formatSecondsLeft(s)
	if typeof(s) ~= "number" or s ~= s then return "—" end
	if s == math.huge then return "Lifetime" end
	if s <= 0 then return "Expired" end
	local d = math.floor(s/86400); local h = math.floor((s%86400)/3600); local m = math.floor((s%3600)/60)
	if d > 0 then return string.format("%dd %dh left", d, h) end
	if h > 0 then return string.format("%dh %dm left", h, m) end
	return string.format("%dm left", math.max(m, 1))
end

local function protectGui(gui)
	local ok = pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent = game:GetService("CoreGui")
		elseif gethui then gui.Parent = gethui()
		else gui.Parent = game:GetService("CoreGui") end
	end)
	if not ok then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
end

-- =========================================================
-- Library
-- =========================================================
local Library = {}; Library.__index = Library

function Library:CreateWindow(opts)
	opts = opts or {}
	local screen = New("ScreenGui", { Name = "\0Crystal\0", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 999 })
	protectGui(screen)

	local root = New("CanvasGroup", {
		Parent = screen, Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Cfg.WinSize.X, Cfg.WinSize.Y),
		BackgroundColor3 = Cfg.Bg, GroupTransparency = 1, ClipsDescendants = true,
	})
	corner(root, UDim.new(0, 14)); stroke(root, Cfg.StrokeSoft, 1)

	-- =====================================================
	-- Background: subtle rotated crystal shapes + gradient
	-- =====================================================
	local bg = New("Frame", { Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Cfg.Bg, BorderSizePixel = 0, ZIndex = 0 })
	-- Vertical gradient
	New("UIGradient", {
		Parent = bg, Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
		}),
	})

	-- Rotated crystal shapes (diamonds) scattered behind everything
	local shapes = {
		{ x = 0.85, y = 0.25, size = 220, rot = 25, alpha = 0.94 },
		{ x = 0.15, y = 0.85, size = 260, rot = -20, alpha = 0.95 },
		{ x = 0.9,  y = 0.75, size = 180, rot = 35, alpha = 0.94 },
		{ x = 0.05, y = 0.15, size = 160, rot = 40, alpha = 0.96 },
		{ x = 0.55, y = 0.55, size = 200, rot = -15, alpha = 0.96 },
	}
	for _, s in ipairs(shapes) do
		local d = New("Frame", {
			Parent = bg, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(s.x, s.y), Size = UDim2.fromOffset(s.size, s.size),
			Rotation = s.rot, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = s.alpha, BorderSizePixel = 0, ZIndex = 0,
		})
		corner(d, UDim.new(0, 24))
		stroke(d, Color3.fromRGB(255, 255, 255), 1).Transparency = 0.9
	end

	-- Faint diagonal line pattern top-right
	for i = 1, 8 do
		local line = New("Frame", {
			Parent = bg, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -20 * i, 0, -30), Size = UDim2.new(0, 1, 0, 90),
			Rotation = 30, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.95, BorderSizePixel = 0, ZIndex = 0,
		})
	end

	local uiScale = New("UIScale", { Parent = root, Scale = 1 })
	local cam = workspace.CurrentCamera
	local function updScale()
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local raw = math.min(vp.X / Cfg.ScaleBase.X, vp.Y / Cfg.ScaleBase.Y)
		-- Mobile: keep floor higher so text stays readable
		local isMobile = vp.X < 900 or vp.Y < 600
		local floor = isMobile and 0.45 or Cfg.MinScale
		uiScale.Scale = math.clamp(raw, floor, 1)
	end
	updScale(); if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(updScale) end

	-- ================================================
	-- TOPBAR
	-- ================================================
	local topbar = New("Frame", { Parent = root, Size = UDim2.new(1, 0, 0, Cfg.TopH), BackgroundTransparency = 1 })

	-- Logo — crystal image, no background, bigger
	local mark = New("CanvasGroup", {
		Parent = topbar, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(46, 46),
		BackgroundTransparency = 1, ClipsDescendants = true,
	})
	corner(mark, UDim.new(0, 10))
	New("ImageLabel", {
		Parent = mark, Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Image = Cfg.CrystalLogo,
		ScaleType = Enum.ScaleType.Stretch,
	})

	-- Centered title with subtle side dashes
	local titleWrap = New("Frame", {
		Parent = topbar, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 340, 0, 30),
		BackgroundTransparency = 1,
	})
	New("Frame", { Parent = titleWrap, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(24, 1), BackgroundColor3 = Cfg.Stroke, BorderSizePixel = 0 })
	New("Frame", { Parent = titleWrap, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(24, 1), BackgroundColor3 = Cfg.Stroke, BorderSizePixel = 0 })
	New("TextLabel", {
		Parent = titleWrap, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1, Font = Cfg.FontTitle,
		Text = string.upper(opts.Title or "Lyzn Hub"),
		TextColor3 = Cfg.Text, TextSize = 24,
	})

	-- Minimize button top-right
	local minBtn = New("TextButton", {
		Parent = topbar, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = Cfg.Panel, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	})
	corner(minBtn, UDim.new(0, 7)); stroke(minBtn, Cfg.Stroke, 1)
	New("Frame", {
		Parent = minBtn, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(12, 2),
		BackgroundColor3 = Cfg.TextDim, BorderSizePixel = 0,
	})
	minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn, Cfg.Tween, { BackgroundColor3 = Cfg.PanelHi }):Play() end)
	minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn, Cfg.Tween, { BackgroundColor3 = Cfg.Panel }):Play() end)

	-- Bottom border with gradient fade
	local topDiv = New("Frame", {
		Parent = topbar, Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Cfg.Text, BorderSizePixel = 0,
	})
	New("UIGradient", { Parent = topDiv, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})})

	-- ================================================
	-- SIDEBAR (tab list + profile card at bottom) — same nebula theme as the profile
	-- ================================================
	local sidebar = New("Frame", {
		Parent = root, Position = UDim2.new(0, 0, 0, Cfg.TopH),
		Size = UDim2.new(0, Cfg.SidebarW, 1, -Cfg.TopH),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	-- Nebula gradient (matches profile card)
	New("UIGradient", {
		Parent = sidebar, Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(24, 12, 26)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 8, 18)),
		}),
	})
	-- Star layer behind everything (drifting)
	do
		local rng = Random.new()
		for i = 1, 40 do
			local sz = rng:NextNumber(0.8, 1.8)
			local base = rng:NextNumber(0.4, 0.8)
			local x0 = rng:NextNumber(0.02, 0.98)
			local y0 = rng:NextNumber(0.02, 0.98)
			local s = New("Frame", {
				Parent = sidebar, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x0, y0), Size = UDim2.fromOffset(sz, sz),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = base, BorderSizePixel = 0, ZIndex = 0,
			})
			corner(s, UDim.new(1, 0))
			TweenService:Create(s, TweenInfo.new(rng:NextNumber(1.5, 3.2), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 2)), { BackgroundTransparency = math.min(1, base + 0.35) }):Play()
			local dy = rng:NextNumber(-3, 3) / 100
			TweenService:Create(s, TweenInfo.new(rng:NextNumber(6, 12), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 3)), { Position = UDim2.fromScale(x0, y0 + dy) }):Play()
		end
	end
	-- Right border
	New("Frame", { Parent = sidebar, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.fromRGB(80, 30, 50), BorderSizePixel = 0, ZIndex = 5 })
	-- Top glow band (accent-tinted, matches profile card feel)
	local topGlow = New("Frame", {
		Parent = sidebar, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1.4, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(180, 40, 80), BorderSizePixel = 0, ZIndex = 0,
	})
	New("UIGradient", { Parent = topGlow, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) }) })

	local tabList = New("ScrollingFrame", {
		Parent = sidebar, Size = UDim2.new(1, 0, 1, -(Cfg.ProfileH + 16)),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2,
	})
	padding(tabList, 10, 10, 10, 10)
	New("UIListLayout", { Parent = tabList, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

	-- Profile card (bottom of sidebar) — nebula bg, avatar, name, online status
	do
		local LP = Players.LocalPlayer
		local uid = LP and LP.UserId or 1
		local un = LP and LP.Name or "Player"
		local disp = (LP and LP.DisplayName ~= "" and LP.DisplayName) or un

		local card = New("TextButton", {
			Parent = sidebar, AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, Cfg.ProfileH),
			BackgroundColor3 = Color3.fromRGB(14, 12, 22), AutoButtonColor = false, Text = "",
			BorderSizePixel = 0, ClipsDescendants = true,
		})
		corner(card, UDim.new(0, 12)); stroke(card, Color3.fromRGB(80, 30, 50), 1)

		-- Nebula gradient
		New("UIGradient", {
			Parent = card, Rotation = 135,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 25, 45)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 15, 30)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 10, 22)),
			}),
		})

		-- Twinkling stars behind
		do
			local rng = Random.new()
			for i = 1, 14 do
				local sz = rng:NextNumber(1, 1.8)
				local base = rng:NextNumber(0.35, 0.7)
				local s = New("Frame", {
					Parent = card, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95)),
					Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = base, BorderSizePixel = 0,
				})
				corner(s, UDim.new(1, 0))
				TweenService:Create(s, TweenInfo.new(rng:NextNumber(1.4, 3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 2)), { BackgroundTransparency = math.min(1, base + 0.35) }):Play()
			end
		end

		-- Avatar with double-ring
		local avatarGlow = New("Frame", {
			Parent = card, AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(54, 54),
			BackgroundColor3 = Cfg.Accent, BackgroundTransparency = 0.85, BorderSizePixel = 0,
		})
		corner(avatarGlow, UDim.new(1, 0))
		local avatar = New("ImageLabel", {
			Parent = card, AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(46, 46),
			BackgroundColor3 = Cfg.Bg, BorderSizePixel = 0, Image = "",
		})
		corner(avatar, UDim.new(1, 0)); stroke(avatar, Cfg.Text, 1.5)
		task.spawn(function()
			local ok, ct = pcall(function() return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
			avatar.Image = ok and ct or ("rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=48&h=48")
		end)

		-- Name
		New("TextLabel", {
			Parent = card, Position = UDim2.fromOffset(72, 12),
			Size = UDim2.new(1, -80, 0, 18),
			BackgroundTransparency = 1, Font = Cfg.FontBold, Text = string.upper(disp),
			TextColor3 = Cfg.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		-- Executor
		New("TextLabel", {
			Parent = card, Position = UDim2.fromOffset(72, 32),
			Size = UDim2.new(1, -80, 0, 14),
			BackgroundTransparency = 1, Font = Cfg.FontMed, Text = getExecutorName(),
			TextColor3 = Cfg.TextDim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		-- Expiry row: green dot + countdown
		local statusWrap = New("Frame", { Parent = card, Position = UDim2.fromOffset(72, 52), Size = UDim2.new(1, -80, 0, 14), BackgroundTransparency = 1 })
		local dot = New("Frame", { Parent = statusWrap, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.fromRGB(80, 220, 130), BorderSizePixel = 0 })
		corner(dot, UDim.new(1, 0))
		TweenService:Create(dot, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.5 }):Play()
		local expiryLbl = New("TextLabel", {
			Parent = statusWrap, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1, Font = Cfg.FontMed, Text = "Checking key…",
			TextColor3 = Color3.fromRGB(120, 220, 160), TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		})
		task.spawn(function()
			local sl = fetchSecondsLeft()
			local mA = os.clock()
			expiryLbl.Text = formatSecondsLeft(sl)
			if typeof(sl) ~= "number" or sl == math.huge then return end
			while expiryLbl.Parent do
				local r = sl - (os.clock() - mA)
				expiryLbl.Text = formatSecondsLeft(r)
				if r <= 0 then expiryLbl.TextColor3 = Cfg.TextFaint; break end
				task.wait(r > 3600 and 30 or 1)
			end
		end)

		-- Click → copy profile link
		card.MouseButton1Click:Connect(function()
			pcall(function()
				local link = "https://www.roblox.com/users/" .. uid .. "/profile"
				if setclipboard then setclipboard(link) end
				local StarterGui = game:GetService("StarterGui")
				StarterGui:SetCore("SendNotification", { Title = "Profile copied", Text = link, Duration = 4 })
			end)
		end)
	end

	-- ================================================
	-- CONTENT (right of sidebar)
	-- ================================================
	local content = New("Frame", {
		Parent = root, Position = UDim2.new(0, Cfg.SidebarW, 0, Cfg.TopH),
		Size = UDim2.new(1, -Cfg.SidebarW, 1, -Cfg.TopH),
		BackgroundTransparency = 1,
	})
	padding(content, 14, 14, 14, 14)

	-- Smooth drag
	local function bindDrag(frame, handle)
		local dragging, dragStart, startPos, target = false
		local rc, ec
		local function stop()
			if rc then rc:Disconnect(); rc = nil end
			if ec then ec:Disconnect(); ec = nil end
			if dragging then dragging = false; if target then frame.Position = target end end
		end
		handle.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; dragStart = i.Position; startPos = frame.Position; target = startPos
				rc = RunService.RenderStepped:Connect(function()
					local c = frame.Position
					frame.Position = UDim2.new(target.X.Scale, c.X.Offset + (target.X.Offset - c.X.Offset) * 0.3, target.Y.Scale, c.Y.Offset + (target.Y.Offset - c.Y.Offset) * 0.3)
				end)
				ec = i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then stop() end end)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - dragStart
				target = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then stop() end
		end)
	end
	bindDrag(root, topbar)

	-- Minimize-to-crystal pill (bottom-left, draggable, tap opens)
	local minPill = New("ImageButton", {
		Parent = screen, Position = UDim2.fromOffset(24, 200),
		Size = UDim2.fromOffset(56, 56),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		AutoButtonColor = false, Image = Cfg.CrystalLogo,
		ScaleType = Enum.ScaleType.Stretch,
		Selectable = false, Modal = false, Active = true,
		Visible = false, ZIndex = 200,
	})
	corner(minPill, UDim.new(0, 12))

	local shown = true
	local function setShown(s)
		shown = s
		if s then
			root.Visible = true; minPill.Visible = false
			TweenService:Create(root, Cfg.Fade, { GroupTransparency = 0 }):Play()
		else
			local f = TweenService:Create(root, Cfg.Fade, { GroupTransparency = 1 }); f:Play()
			f.Completed:Once(function() if not shown then root.Visible = false; minPill.Visible = true end end)
		end
	end
	minBtn.MouseButton1Click:Connect(function() setShown(false) end)

	-- Drag on minimize pill + tap to open
	do
		local dragging, dragStart, startPos, target, moved
		local rc, ec
		local function stop()
			if rc then rc:Disconnect(); rc = nil end
			if ec then ec:Disconnect(); ec = nil end
			if dragging then dragging = false; if target then minPill.Position = target end end
		end
		minPill.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; moved = false; dragStart = i.Position; startPos = minPill.Position; target = startPos
				rc = RunService.RenderStepped:Connect(function()
					local c = minPill.Position
					minPill.Position = UDim2.new(target.X.Scale, c.X.Offset + (target.X.Offset - c.X.Offset) * 0.3, target.Y.Scale, c.Y.Offset + (target.Y.Offset - c.Y.Offset) * 0.3)
				end)
				ec = i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then
						if not moved then setShown(true) end
						stop()
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - dragStart
				if math.abs(d.X) + math.abs(d.Y) > 5 then moved = true end
				target = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
				if not moved then setShown(true) end
				stop()
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Cfg.ToggleKey then setShown(not shown) end
	end)
	task.spawn(function() task.wait(0.1); TweenService:Create(root, Cfg.Fade, { GroupTransparency = 0 }):Play() end)

	local w = setmetatable({ Screen = screen, Root = root, TabList = tabList, Content = content, Tabs = {}, Current = nil }, { __index = Library.Window })
	return w
end

-- =========================================================
-- Tabs — pill with dot indicator on the left (dot = active state)
-- =========================================================
Library.Window = {}
-- Auto-map tab names to Lucide icons
local TabIconMap = {
	main = "home", home = "home", general = "home",
	combat = "swords", fight = "swords", pvp = "swords", kill = "swords",
	player = "user", players = "users", character = "user", char = "user",
	movement = "footprints", move = "footprints", walk = "footprints",
	settings = "settings", config = "settings", options = "settings",
	visuals = "eye", visual = "eye", esp = "eye", render = "eye",
	misc = "box", other = "box", extra = "box",
	world = "globe", server = "server", game = "gamepad-2",
	teleport = "map-pin", tp = "map-pin", location = "map-pin",
	farm = "sprout", auto = "zap", automation = "zap",
	shop = "shopping-cart", store = "shopping-cart",
	inventory = "package", items = "package", inv = "package",
	stats = "bar-chart-3", info = "info",
	credits = "heart", credit = "heart", about = "info",
	throwing = "send", throw = "send",
	catching = "hand", catch = "hand",
	defense = "shield", defence = "shield", block = "shield",
	physics = "atom", magnet = "magnet", magnets = "magnet",
	pull = "move", teleport_vector = "move",
	util = "wrench", utilities = "wrench", tools = "wrench",
	script = "file-code", scripts = "file-code",
	fun = "sparkles", troll = "sparkles",
	admin = "shield-check", dev = "code", developer = "code",
}
local function guessIcon(n)
	local key = string.lower(n or "")
	key = key:gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
	if TabIconMap[key] then return TabIconMap[key] end
	for word in string.gmatch(key, "[%w]+") do
		if TabIconMap[word] then return TabIconMap[word] end
	end
	return "circle"
end

function Library.Window:CreateTab(name, iconName)
	local btn = New("TextButton", {
		Name = name, Parent = self.TabList,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Cfg.Panel, BackgroundTransparency = 1,
		AutoButtonColor = false, Text = "",
	})
	corner(btn, UDim.new(0, 8))

	local iconHolder = New("Frame", {
		Parent = btn, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
	})
	local icon
	local resolved = iconName or guessIcon(name)
	local props = resolved and lucideProps(resolved)
	-- try guess as last resort if user-supplied name isn't a real Lucide
	if (not props or not props.Image or props.Image == "") and iconName then
		props = lucideProps(guessIcon(name))
	end
	-- final fallback to "circle"
	if not props or not props.Image or props.Image == "" then
		props = lucideProps("circle")
	end
	if props and props.Image and props.Image ~= "" then
		icon = New("ImageLabel", {
			Parent = iconHolder, Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1, ImageColor3 = Cfg.TextDim,
			Image = props.Image,
		})
		if props.ImageRectOffset then icon.ImageRectOffset = props.ImageRectOffset end
		if props.ImageRectSize then icon.ImageRectSize = props.ImageRectSize end
	else
		-- Lucide failed to load entirely — use a small dot instead of the letter tile
		icon = New("Frame", {
			Parent = iconHolder, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Cfg.TextDim, BorderSizePixel = 0,
		})
		corner(icon, UDim.new(1, 0))
	end

	local lbl = New("TextLabel", {
		Parent = btn, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -46, 1, 0),
		BackgroundTransparency = 1, Font = Cfg.FontBold, Text = string.upper(name),
		TextColor3 = Cfg.TextDim, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Left accent bar for active tab
	local activeBar = New("Frame", {
		Parent = btn, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -2, 0.5, 0), Size = UDim2.fromOffset(3, 26),
		BackgroundColor3 = Cfg.Accent, BorderSizePixel = 0, Visible = false,
	})
	corner(activeBar, UDim.new(1, 0))

	local page = New("ScrollingFrame", {
		Parent = self.Content, Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
	})
	-- Two columns
	local left = New("Frame", { Parent = page, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
	local right = New("Frame", { Parent = page, Position = UDim2.new(0.5, 6, 0, 0), Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
	New("UIListLayout", { Parent = left, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	New("UIListLayout", { Parent = right, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

	local tab = setmetatable({ Window = self, Btn = btn, Label = lbl, Icon = icon, ActiveBar = activeBar, Page = page, Left = left, Right = right }, { __index = Library.Tab })
	btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	table.insert(self.Tabs, tab)
	if not self.Current then self:SelectTab(tab) end
	return tab
end

function Library.Window:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do
		local active = t == tab
		t.Page.Visible = active
		t.ActiveBar.Visible = active
		TweenService:Create(t.Btn, Cfg.Tween, { BackgroundTransparency = active and 0 or 1, BackgroundColor3 = active and Cfg.Panel or Cfg.Panel }):Play()
		TweenService:Create(t.Label, Cfg.Tween, { TextColor3 = active and Cfg.Text or Cfg.TextDim }):Play()
		if t.Icon:IsA("ImageLabel") then
			TweenService:Create(t.Icon, Cfg.Tween, { ImageColor3 = active and Cfg.Text or Cfg.TextDim }):Play()
		else
			TweenService:Create(t.Icon, Cfg.Tween, { TextColor3 = active and Cfg.Text or Cfg.TextDim }):Play()
		end
	end
	self.Current = tab
end

-- =========================================================
-- Sections (header with dot + uppercase title, then rows)
-- =========================================================
Library.Tab = {}
function Library.Tab:CreateSection(title, side)
	local col = (side == "Right") and self.Right or self.Left

	-- Outer card (groupbox)
	local card = New("Frame", {
		Parent = col, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Cfg.PanelDark or Color3.fromRGB(20, 18, 26),
		BorderSizePixel = 0,
	})
	corner(card, UDim.new(0, 12))
	stroke(card, Cfg.StrokeSoft, 1)
	padding(card, 10, 12, 12, 12)

	-- Header row
	local header = New("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = -1 })
	local hDot = New("Frame", {
		Parent = header, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Cfg.TextDim, BorderSizePixel = 0,
	})
	corner(hDot, UDim.new(1, 0))
	New("TextLabel", {
		Parent = header, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0),
		BackgroundTransparency = 1, Font = Cfg.FontBold,
		Text = string.upper(title), TextColor3 = Cfg.TextDim,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Divider under header
	New("Frame", {
		Parent = card, Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Cfg.StrokeSoft, BorderSizePixel = 0,
		BackgroundTransparency = 0.4, LayoutOrder = 0,
	})

	-- Inner wrap that rows go into
	local wrap = New("Frame", {
		Parent = card, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = 1,
	})
	New("UIListLayout", { Parent = wrap, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

	-- Card's own vertical stack (header, divider, wrap)
	New("UIListLayout", { Parent = card, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

	return setmetatable({ Wrap = wrap, Card = card }, { __index = Library.Section })
end

-- =========================================================
-- Row helpers
-- =========================================================
Library.Section = {}
local function makeRow(sec, h)
	local r = New("Frame", {
		Parent = sec.Wrap, Size = UDim2.new(1, 0, 0, h or 44),
		BackgroundColor3 = Cfg.Panel, BorderSizePixel = 0,
	})
	corner(r, UDim.new(0, 10)); stroke(r, Cfg.StrokeSoft, 1)
	padding(r, 0, 0, 14, 14)
	return r
end

function Library.Section:AddToggle(o)
	local r = makeRow(self, 44)
	New("TextLabel", {
		Parent = r, Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Toggle"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local state = o.Default == true

	-- Track — same nebula theme as profile card
	local track = New("TextButton", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BorderSizePixel = 0,
		AutoButtonColor = false, Text = "", ClipsDescendants = true,
	})
	corner(track, UDim.new(1, 0))
	local trackStroke = stroke(track, Color3.fromRGB(80, 30, 50), 1)

	-- Nebula gradient fill (only visible when ON)
	local trackGrad = New("UIGradient", {
		Parent = track, Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 25, 45)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 15, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 10, 22)),
		}),
	})

	local knob = New("Frame", {
		Parent = track, AnchorPoint = Vector2.new(0, 0.5),
		Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Cfg.TextDim,
		BorderSizePixel = 0,
	})
	corner(knob, UDim.new(1, 0))

	local ob = { State = state }
	local function render()
		local on = ob.State
		TweenService:Create(track, Cfg.Tween, {
			BackgroundColor3 = on and Color3.fromRGB(140, 30, 50) or Color3.fromRGB(14, 12, 22),
		}):Play()
		TweenService:Create(trackStroke, Cfg.Tween, {
			Color = on and Color3.fromRGB(200, 60, 90) or Color3.fromRGB(80, 30, 50),
		}):Play()
		TweenService:Create(knob, Cfg.Tween, {
			Position = on and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Cfg.TextDim,
		}):Play()
	end
	render()

	function ob:Set(v) ob.State = v and true or false; render(); if o.Callback then task.spawn(o.Callback, ob.State) end end
	track.MouseButton1Click:Connect(function() ob:Set(not ob.State) end)
	if state and o.Callback then task.spawn(o.Callback, true) end
	return ob
end

function Library.Section:AddSlider(o)
	local min, max = o.Min or 0, o.Max or 100
	local dec = o.Decimals or 1
	local val = math.clamp(o.Default or min, min, max)
	local function round(n) local m = 10^dec; return math.floor(n*m+0.5)/m end

	local r = makeRow(self, 52)
	local topRow = New("Frame", { Parent = r, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
	New("TextLabel", {
		Parent = topRow, Size = UDim2.new(1, -64, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Slider"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valLbl = New("TextLabel", {
		Parent = topRow, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(60, 20),
		BackgroundTransparency = 1, Font = Cfg.FontBold,
		Text = tostring(round(val)), TextColor3 = Cfg.Text,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track = New("Frame", {
		Parent = r, AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = Cfg.Bg, BorderSizePixel = 0,
	})
	corner(track, UDim.new(1, 0))
	local fill = New("Frame", { Parent = track, Size = UDim2.fromScale((val - min) / (max - min), 1), BackgroundColor3 = Cfg.Accent, BorderSizePixel = 0 })
	corner(fill, UDim.new(1, 0))
	local knob = New("Frame", {
		Parent = track, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((val - min) / (max - min), 0, 0.5, 0),
		Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Cfg.Accent, BorderSizePixel = 0, ZIndex = 2,
	})
	corner(knob, UDim.new(1, 0))

	local ob = { Value = val }
	local function apply(a, fire)
		a = math.clamp(a, 0, 1); ob.Value = round(min + (max - min) * a)
		local t = (ob.Value - min) / (max - min)
		fill.Size = UDim2.fromScale(t, 1); knob.Position = UDim2.new(t, 0, 0.5, 0)
		valLbl.Text = tostring(ob.Value)
		if fire and o.Callback then task.spawn(o.Callback, ob.Value) end
	end
	function ob:Set(v) apply((math.clamp(v, min, max) - min) / (max - min), true) end
	local d = false
	local function upd(i) apply((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, true) end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true; upd(i) end end)
	UserInputService.InputChanged:Connect(function(i) if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end end)
	return ob
end

function Library.Section:AddDropdown(o)
	local list = o.List or {}
	local selected = o.Default or list[1] or "None"

	local r = makeRow(self, 44)
	New("TextLabel", {
		Parent = r, Size = UDim2.new(1, -110, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Dropdown"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valLbl = New("TextButton", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.fromOffset(90, 24),
		BackgroundTransparency = 1, AutoButtonColor = false,
		Font = Cfg.FontBold, Text = string.upper(tostring(selected)),
		TextColor3 = Cfg.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local chev = New("TextLabel", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(14, 20),
		BackgroundTransparency = 1, Font = Cfg.FontBold, Text = "V",
		TextColor3 = Cfg.Text, TextSize = 12,
	})

	local menu = New("Frame", { Parent = self.Wrap, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Cfg.Panel, Visible = false, BorderSizePixel = 0 })
	corner(menu, UDim.new(0, 10)); stroke(menu, Cfg.StrokeSoft, 1); padding(menu, 4)
	New("UIListLayout", { Parent = menu, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })

	local ob = { Value = selected }; local open = false
	local function setOpen(s) open = s; menu.Visible = s end
	local function sel(it) ob.Value = it; valLbl.Text = string.upper(tostring(it)); setOpen(false); if o.Callback then task.spawn(o.Callback, it) end end
	for _, it in ipairs(list) do
		local ib = New("TextButton", { Parent = menu, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Cfg.Panel, BackgroundTransparency = 1, AutoButtonColor = false, Font = Cfg.FontBold, Text = string.upper(tostring(it)), TextColor3 = Cfg.TextDim, TextSize = 13 })
		corner(ib, UDim.new(0, 5))
		ib.MouseEnter:Connect(function() TweenService:Create(ib, Cfg.Tween, { BackgroundTransparency = 0, BackgroundColor3 = Cfg.PanelHi, TextColor3 = Cfg.Text }):Play() end)
		ib.MouseLeave:Connect(function() TweenService:Create(ib, Cfg.Tween, { BackgroundTransparency = 1, TextColor3 = Cfg.TextDim }):Play() end)
		ib.MouseButton1Click:Connect(function() sel(it) end)
	end
	valLbl.MouseButton1Click:Connect(function() setOpen(not open) end)
	function ob:Set(it) sel(it) end
	return ob
end

-- =========================================================
-- DEMO — mirrors the Lyzn Hub reference
function Library.Section:AddButton(o)
	local r = makeRow(self, 32)
	local b = New("TextButton", {
		Parent = r, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Cfg.Panel, BorderSizePixel = 0, AutoButtonColor = false,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Button"),
		TextColor3 = Cfg.Text, TextSize = 14,
	})
	corner(b, UDim.new(0, 8)); stroke(b, Cfg.StrokeSoft, 1)
	New("UIGradient", { Parent = b, Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 26)),
		})})
	b.MouseEnter:Connect(function() TweenService:Create(b, Cfg.Tween, { BackgroundColor3 = Color3.fromRGB(140, 30, 50) }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, Cfg.Tween, { BackgroundColor3 = Cfg.Panel }):Play() end)
	b.MouseButton1Click:Connect(function() if o.Callback then task.spawn(o.Callback) end end)
	return b
end

function Library.Section:AddLabel(t)
	local r = makeRow(self, 20)
	local lbl = New("TextLabel", {
		Parent = r, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Font = Cfg.FontMed, Text = t, TextColor3 = Cfg.TextDim,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	})
	return { Set = function(_, v) lbl.Text = v end }
end

function Library.Section:AddKeybind(o)
	local r = makeRow(self, Cfg.RowHeight or 30)
	New("TextLabel", {
		Parent = r, Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Keybind"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	})
	local cur = o.Default
	local btn = New("TextButton", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(74, 24),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BorderSizePixel = 0,
		AutoButtonColor = false, Font = Cfg.FontBold,
		Text = cur and cur.Name or "NONE",
		TextColor3 = Cfg.TextDim, TextSize = 12,
	})
	corner(btn, UDim.new(0, 6)); stroke(btn, Color3.fromRGB(80, 30, 50), 1)
	local ob = { Key = cur }; local listening = false; local cn
	btn.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true; btn.Text = "..."; btn.TextColor3 = Cfg.Accent
		cn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			listening = false; cn:Disconnect(); cn = nil
			if input.KeyCode == Enum.KeyCode.Escape then ob.Key = nil; btn.Text = "NONE"
			elseif input.UserInputType == Enum.UserInputType.Keyboard then ob.Key = input.KeyCode; btn.Text = input.KeyCode.Name end
			btn.TextColor3 = Cfg.TextDim
			if o.Callback then task.spawn(o.Callback, ob.Key) end
		end)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or listening or not ob.Key then return end
		if input.KeyCode == ob.Key and o.OnPress then task.spawn(o.OnPress) end
	end)
	function ob:Set(k) ob.Key = k; btn.Text = k and k.Name or "NONE" end
	return ob
end


-- ===== Converted by gemini (gemini-flash-lite-latest) =====

shared._lyzn_stop = true
task.wait(0.2)
if shared._lyzn_cleanup then shared._lyzn_cleanup() end
shared._lyzn_stop = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local pg = LP:WaitForChild("PlayerGui")
local conns = {}
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local guiParent
do
    local ok, hui = pcall(gethui)
    if ok and hui then guiParent = hui else guiParent = game:GetService("CoreGui") end
end

local CFG = {
    aimbot = false, aim_fov = 350, aim_smoothing = 0, aim_part = "Head",
    aim_team_check = false, aim_wall_check = false, aim_show_fov = false,
    skeleton_esp = false, skeleton_color = Color3.fromRGB(0,255,255), skeleton_team_check = false, skeleton_thickness = 2.5,
    box_esp = false, box_name = false, box_distance = false, box_health = false, box_team_check = false, box_color = Color3.fromRGB(75,0,10),
    outlines = false, outline_team_check = false, outline_team_color = false, outline_fill = Color3.fromRGB(75,0,10), outline_fill_trans = 0, outline_outline_color = Color3.fromRGB(0,0,0), outline_outline_trans = 0, outline_always_top = true,
    tracers = false, tracer_team_check = false, tracer_team_color = false, tracer_color = Color3.fromRGB(0,255,255),
    hitbox = false, hitbox_size = 10, hitbox_team_check = true,
    stretch_res = false,
}

local skeletonLines = {}
local highlightGuis = {}
local boxGuis = {}
local tracerDrawings = {}
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(100,0,100); fovCircle.Thickness = 1; fovCircle.Filled = false
fovCircle.Transparency = 0.6; fovCircle.NumSides = 64; fovCircle.Visible = false
local stretchConn = nil

shared._lyzn_cleanup = function()
    shared._lyzn_stop = true
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end; conns = {}
    if stretchConn then pcall(function() stretchConn:Disconnect() end); stretchConn = nil end
    for _, lines in pairs(skeletonLines) do for _, l in pairs(lines) do pcall(function() l:Remove() end) end end; skeletonLines = {}
    for _, t in pairs(tracerDrawings) do pcall(function() t:Remove() end) end; tracerDrawings = {}
    for _, g in pairs(highlightGuis) do pcall(function() g:Destroy() end) end; highlightGuis = {}
    for _, g in pairs(boxGuis) do pcall(function() g:Destroy() end) end; boxGuis = {}
    pcall(function() fovCircle:Remove() end)
    pcall(function() if guiParent:FindFirstChild("\0Lyzn\0") then guiParent:FindFirstChild("\0Lyzn\0"):Destroy() end end)
    pcall(function() if pg:FindFirstChild("\0Lyzn\0") then pg:FindFirstChild("\0Lyzn\0"):Destroy() end end)
end

local function isVisible(p)
    if not CFG.aim_wall_check then return true end
    return #Camera:GetPartsObscuringTarget({p}, {Camera, LP.Character}) == 0
end

local function getAimTarget()
    local closest, dist = nil, CFG.aim_fov
    local mousePos = UserInputService:GetMouseLocation()
    for _, v in ipairs(Players:GetPlayers()) do
        if v == LP then continue end
        if CFG.aim_team_check and v.Team == LP.Team then continue end
        local char = v.Character
        if char and char:FindFirstChild(CFG.aim_part) and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local sp, on = Camera:WorldToViewportPoint(char[CFG.aim_part].Position)
            local mag = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
            if on and mag < dist and isVisible(char[CFG.aim_part].Position) then dist = mag; closest = v end
        end
    end
    return closest
end

local boneMapR15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local boneMapR6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local function getBoneMap(char)
    if char:FindFirstChild("UpperTorso") then return boneMapR15 end
    return boneMapR6
end

local function addSkeleton(plr)
    if skeletonLines[plr] then return end
    local lines = {}
    for i = 1, #boneMapR15 do
        local l = Drawing.new("Line"); l.Thickness = CFG.skeleton_thickness; l.Color = CFG.skeleton_color; l.Visible = false; l.Transparency = 1
        lines[i] = l
    end
    skeletonLines[plr] = lines
end

local function removeSkeleton(plr)
    if skeletonLines[plr] then
        for _, l in ipairs(skeletonLines[plr]) do pcall(function() l:Remove() end) end
        skeletonLines[plr] = nil
    end
end

local function addHighlight(plr)
    if highlightGuis[plr] then return end
    local h = Instance.new("Highlight")
    h.Name = plr.Name
    highlightGuis[plr] = h
end

local function removeHighlight(plr)
    if highlightGuis[plr] then pcall(function() highlightGuis[plr]:Destroy() end); highlightGuis[plr] = nil end
end

local function addTracer(plr)
    if tracerDrawings[plr] then return end
    local t = Drawing.new("Line"); t.Thickness = 2; t.Transparency = 1; t.Visible = false
    tracerDrawings[plr] = t
end

local function removeTracer(plr)
    if tracerDrawings[plr] then pcall(function() tracerDrawings[plr]:Remove() end); tracerDrawings[plr] = nil end
end

local function addBox(plr)
    if boxGuis[plr] then return end
    local bbg = Instance.new("BillboardGui"); bbg.Name = plr.Name; bbg.AlwaysOnTop = true; bbg.Size = UDim2.new(4,0,5.4,0); bbg.Enabled = false
    local outlines = Instance.new("Frame", bbg); outlines.Size = UDim2.new(1,0,1,0); outlines.BackgroundTransparency = 1
    local left = Instance.new("Frame", outlines); left.Size = UDim2.new(0,1,1,0); left.BorderSizePixel = 1; left.BackgroundColor3 = CFG.box_color
    local right = left:Clone(); right.Parent = outlines; right.Size = UDim2.new(0,-1,1,0); right.Position = UDim2.new(1,0,0,0)
    local up = left:Clone(); up.Parent = outlines; up.Size = UDim2.new(1,0,0,1)
    local down = left:Clone(); down.Parent = outlines; down.Size = UDim2.new(1,0,0,-1); down.Position = UDim2.new(0,0,1,0)

    local info = Instance.new("BillboardGui", bbg); info.Size = UDim2.new(3,0,0,54); info.StudsOffset = Vector3.new(3.6,-3,0); info.AlwaysOnTop = true; info.Enabled = false
    local namelabel = Instance.new("TextLabel", info); namelabel.Size = UDim2.new(0,100,0,18); namelabel.Text = plr.Name; namelabel.BackgroundTransparency = 1; namelabel.TextStrokeTransparency = 0; namelabel.TextColor3 = CFG.box_color; namelabel.Font = Enum.Font.FredokaOne; namelabel.TextSize = 13
    local distlabel = Instance.new("TextLabel", info); distlabel.Size = UDim2.new(0,100,0,18); distlabel.Position = UDim2.new(0,0,0,18); distlabel.BackgroundTransparency = 1; distlabel.TextStrokeTransparency = 0; distlabel.TextColor3 = CFG.box_color; distlabel.Font = Enum.Font.FredokaOne; distlabel.TextSize = 11
    local healthlabel = Instance.new("TextLabel", info); healthlabel.Size = UDim2.new(0,100,0,18); healthlabel.Position = UDim2.new(0,0,0,36); healthlabel.BackgroundTransparency = 1; healthlabel.TextStrokeTransparency = 0; healthlabel.TextColor3 = CFG.box_color; healthlabel.Font = Enum.Font.FredokaOne; healthlabel.TextSize = 11

    local forhealth = Instance.new("BillboardGui", bbg); forhealth.Size = UDim2.new(4.5,0,6,0); forhealth.AlwaysOnTop = true; forhealth.Enabled = false
    local healthbar = Instance.new("Frame", forhealth); healthbar.Size = UDim2.new(0.04,0,0.9,0); healthbar.Position = UDim2.new(0,0,0.05,0); healthbar.BackgroundColor3 = Color3.fromRGB(40,40,40)
    local bar = Instance.new("Frame", healthbar); bar.Size = UDim2.new(1,0,1,0); bar.AnchorPoint = Vector2.new(0,1); bar.Position = UDim2.new(0,0,1,0); bar.BackgroundColor3 = Color3.fromRGB(94,255,69)

    bbg.Parent = guiParent
    boxGuis[plr] = {bbg = bbg, info = info, forhealth = forhealth, outlines = outlines, namelabel = namelabel, distlabel = distlabel, healthlabel = healthlabel, healthbar = healthbar, bar = bar, left = left, right = right, up = up, down = down}
end

local function removeBox(plr)
    if boxGuis[plr] then pcall(function() boxGuis[plr].bbg:Destroy() end); boxGuis[plr] = nil end
end

local function expandHitboxes()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if CFG.hitbox_team_check and plr.Team == LP.Team then continue end
        local char = plr.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and (part.Name == "Head" or part.Name == "UpperTorso" or part.Name == "HumanoidRootPart") then
                    part.Size = Vector3.new(CFG.hitbox_size, CFG.hitbox_size, CFG.hitbox_size)
                    part.CanCollide = false
                    part.Transparency = 0.7
                end
            end
        end
    end
end

local function initPlayer(plr)
    if plr == LP then return end
    addSkeleton(plr)
    addHighlight(plr)
    addTracer(plr)
    addBox(plr)
end

local function removePlayer(plr)
    removeSkeleton(plr)
    removeHighlight(plr)
    removeTracer(plr)
    removeBox(plr)
end

for _, plr in ipairs(Players:GetPlayers()) do initPlayer(plr) end
table.insert(conns, Players.PlayerAdded:Connect(initPlayer))
table.insert(conns, Players.PlayerRemoving:Connect(removePlayer))

table.insert(conns, RunService.RenderStepped:Connect(function()
    if shared._lyzn_stop then return end

    if CFG.aimbot and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (isMobile and UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch))) then
        local target = getAimTarget()
        if target and target.Character then
            local part = target.Character:FindFirstChild(CFG.aim_part)
            if part then
                if CFG.aim_smoothing > 0 then
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, part.Position), 1 - CFG.aim_smoothing)
                else
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, part.Position)
                end
            end
        end
    end

    if CFG.aim_show_fov then
        fovCircle.Visible = true
        local mouse = UserInputService:GetMouseLocation()
        fovCircle.Position = mouse
        fovCircle.Radius = CFG.aim_fov / 2
    else
        fovCircle.Visible = false
    end

    if CFG.hitbox then expandHitboxes() end

    for plr, lines in pairs(skeletonLines) do
        local char = plr.Character
        local show = CFG.skeleton_esp and char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
        if show and CFG.skeleton_team_check and plr.Team == LP.Team then show = false end

        if show then
            local bm = getBoneMap(char)
            for i = 1, #boneMapR15 do
                if i <= #bm then
                    local bone = bm[i]
                    local p1 = char:FindFirstChild(bone[1])
                    local p2 = char:FindFirstChild(bone[2])
                    if p1 and p2 then
                        local s1, on1 = Camera:WorldToViewportPoint(p1.Position)
                        local s2, on2 = Camera:WorldToViewportPoint(p2.Position)
                        if on1 and on2 then
                            lines[i].From = Vector2.new(s1.X, s1.Y)
                            lines[i].To = Vector2.new(s2.X, s2.Y)
                            lines[i].Color = CFG.skeleton_color
                            lines[i].Thickness = CFG.skeleton_thickness
                            lines[i].Visible = true
                        else
                            lines[i].Visible = false
                        end
                    else
                        lines[i].Visible = false
                    end
                else
                    lines[i].Visible = false
                end
            end
        else
            for i = 1, #lines do lines[i].Visible = false end
        end
    end

    for plr, tracer in pairs(tracerDrawings) do
        local char = plr.Character
        local show = CFG.tracers and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
        if show and CFG.tracer_team_check and plr.Team == LP.Team then show = false end
        if show then
            local sp, on = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if on then
                tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                tracer.To = Vector2.new(sp.X, sp.Y)
                tracer.Color = (CFG.tracer_team_color and plr.TeamColor) and plr.TeamColor.Color or CFG.tracer_color
                tracer.Visible = true
            else
                tracer.Visible = false
            end
        else
            tracer.Visible = false
        end
    end

    for plr, h in pairs(highlightGuis) do
        local char = plr.Character
        local show = CFG.outlines and char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
        if show and CFG.outline_team_check and plr.Team == LP.Team then show = false end
        if show then
            h.Adornee = char; h.Parent = char; h.Enabled = true
            h.FillColor = (CFG.outline_team_color and plr.TeamColor) and plr.TeamColor.Color or CFG.outline_fill
            h.OutlineColor = CFG.outline_outline_color
            h.FillTransparency = CFG.outline_fill_trans
            h.OutlineTransparency = CFG.outline_outline_trans
            h.DepthMode = CFG.outline_always_top and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        else
            h.Enabled = false
        end
    end

    for plr, b in pairs(boxGuis) do
        local char = plr.Character
        local show = char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
        if show and CFG.box_team_check and plr.Team == LP.Team then show = false end
        if show then
            b.bbg.Adornee = char.HumanoidRootPart
            b.info.Adornee = char.HumanoidRootPart
            b.forhealth.Adornee = char.HumanoidRootPart
            b.outlines.Visible = CFG.box_esp
            b.namelabel.Visible = CFG.box_name
            b.left.BackgroundColor3 = CFG.box_color; b.right.BackgroundColor3 = CFG.box_color
            b.up.BackgroundColor3 = CFG.box_color; b.down.BackgroundColor3 = CFG.box_color
            b.namelabel.TextColor3 = CFG.box_color; b.distlabel.TextColor3 = CFG.box_color; b.healthlabel.TextColor3 = CFG.box_color
            if CFG.box_distance and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                b.distlabel.Visible = true
                b.distlabel.Text = "Dist: "..math.floor((LP.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude)
            else b.distlabel.Visible = false end
            if CFG.box_health then
                b.healthlabel.Text = "HP: "..math.floor(char.Humanoid.Health)
                b.bar.Size = UDim2.new(1,0, char.Humanoid.Health / char.Humanoid.MaxHealth, 0)
                b.healthbar.Visible = true; b.healthlabel.Visible = true
            else b.healthbar.Visible = false; b.healthlabel.Visible = false end
            local anyBox = CFG.box_esp or CFG.box_name or CFG.box_distance or CFG.box_health
            b.bbg.Enabled = anyBox; b.info.Enabled = CFG.box_name or CFG.box_distance or CFG.box_health; b.forhealth.Enabled = CFG.box_health
        else
            b.bbg.Enabled = false; b.info.Enabled = false; b.forhealth.Enabled = false
        end
    end
end))

local Window = Library:CreateWindow({ Title = "Lyzn Hub", SubTitle = "Jailbird" })

local Combat = Window:CreateTab("Aimbot")

local aimSection = Combat:CreateSection("Aimbot", "Left")
aimSection:AddToggle({ Text = "Enable Aimbot", Default = CFG.aimbot, Callback = function(v) CFG.aimbot = v end })
aimSection:AddToggle({ Text = "Show FOV", Default = CFG.aim_show_fov, Callback = function(v) CFG.aim_show_fov = v end })
aimSection:AddToggle({ Text = "Team Check", Default = CFG.aim_team_check, Callback = function(v) CFG.aim_team_check = v end })
aimSection:AddToggle({ Text = "Wall Check", Default = CFG.aim_wall_check, Callback = function(v) CFG.aim_wall_check = v end })
aimSection:AddSlider({ Text = "FOV", Min = 50, Max = 800, Default = CFG.aim_fov, Decimals = 0, Callback = function(v) CFG.aim_fov = v end })
aimSection:AddSlider({ Text = "Smoothing", Min = 0, Max = 1, Default = CFG.aim_smoothing, Decimals = 2, Callback = function(v) CFG.aim_smoothing = v end })
aimSection:AddDropdown({ Text = "Aim Part", List = {"Head", "HumanoidRootPart", "UpperTorso"}, Default = CFG.aim_part, Callback = function(v) CFG.aim_part = v end })

local hitboxSection = Combat:CreateSection("Hitbox", "Right")
hitboxSection:AddToggle({ Text = "Hitbox Expander", Default = CFG.hitbox, Callback = function(v) CFG.hitbox = v end })
hitboxSection:AddSlider({ Text = "Hitbox Size", Min = 2, Max = 30, Default = CFG.hitbox_size, Decimals = 1, Callback = function(v) CFG.hitbox_size = v end })
hitboxSection:AddToggle({ Text = "Team Check", Default = CFG.hitbox_team_check, Callback = function(v) CFG.hitbox_team_check = v end })

local Visuals = Window:CreateTab("Visuals")

local skelSection = Visuals:CreateSection("Skeleton ESP", "Left")
skelSection:AddToggle({ Text = "Skeleton", Default = CFG.skeleton_esp, Callback = function(v) CFG.skeleton_esp = v end })
skelSection:AddToggle({ Text = "Team Check", Default = CFG.skeleton_team_check, Callback = function(v) CFG.skeleton_team_check = v end })
skelSection:AddSlider({ Text = "Thickness", Min = 1, Max = 5, Default = CFG.skeleton_thickness, Decimals = 1, Callback = function(v) CFG.skeleton_thickness = v end })

local outlineSection = Visuals:CreateSection("Outlines", "Left")
outlineSection:AddToggle({ Text = "Outlines", Default = CFG.outlines, Callback = function(v) CFG.outlines = v end })
outlineSection:AddToggle({ Text = "Team Check", Default = CFG.outline_team_check, Callback = function(v) CFG.outline_team_check = v end })
outlineSection:AddToggle({ Text = "Team Color", Default = CFG.outline_team_color, Callback = function(v) CFG.outline_team_color = v end })
outlineSection:AddToggle({ Text = "Always On Top", Default = CFG.outline_always_top, Callback = function(v) CFG.outline_always_top = v end })
outlineSection:AddSlider({ Text = "Fill Transparency", Min = 0, Max = 1, Default = CFG.outline_fill_trans, Decimals = 2, Callback = function(v) CFG.outline_fill_trans = v end })
outlineSection:AddSlider({ Text = "Outline Transparency", Min = 0, Max = 1, Default = CFG.outline_outline_trans, Decimals = 2, Callback = function(v) CFG.outline_outline_trans = v end })

local boxSection = Visuals:CreateSection("Box ESP", "Right")
boxSection:AddToggle({ Text = "Box", Default = CFG.box_esp, Callback = function(v) CFG.box_esp = v end })
boxSection:AddToggle({ Text = "Name", Default = CFG.box_name, Callback = function(v) CFG.box_name = v end })
boxSection:AddToggle({ Text = "Distance", Default = CFG.box_distance, Callback = function(v) CFG.box_distance = v end })
boxSection:AddToggle({ Text = "Health", Default = CFG.box_health, Callback = function(v) CFG.box_health = v end })
boxSection:AddToggle({ Text = "Team Check", Default = CFG.box_team_check, Callback = function(v) CFG.box_team_check = v end })

local tracerSection = Visuals:CreateSection("Tracers", "Right")
tracerSection:AddToggle({ Text = "Tracers", Default = CFG.tracers, Callback = function(v) CFG.tracers = v end })
tracerSection:AddToggle({ Text = "Team Check", Default = CFG.tracer_team_check, Callback = function(v) CFG.tracer_team_check = v end })
tracerSection:AddToggle({ Text = "Team Color", Default = CFG.tracer_team_color, Callback = function(v) CFG.tracer_team_color = v end })

local Misc = Window:CreateTab("Misc")

local miscSection = Misc:CreateSection("Visuals", "Left")
miscSection:AddToggle({ Text = "Stretch Res", Default = CFG.stretch_res, Callback = function(v)
    CFG.stretch_res = v
    if v then
        Camera.FieldOfView = 120
        if not stretchConn then
            stretchConn = Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                if CFG.stretch_res then Camera.FieldOfView = 120 end
            end)
        end
    else
        if stretchConn then stretchConn:Disconnect(); stretchConn = nil end
    end
end })