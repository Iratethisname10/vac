local vac = {};
local ui = {};
local commands = {};

if (getgenv().vac) then
	getgenv().vac.unload();
end;

local scriptLoadAt = tick();
local scriptVersion = 2;
local discordCode = 'Gxg42Eshpy';

local cloneref = cloneref or function(inst) return inst; end;
local tweenService = cloneref(game:GetService('TweenService'));
local inputService = cloneref(game:GetService('UserInputService'));
local runService = cloneref(game:GetService('RunService'));
local players = cloneref(game:GetService('Players'));
local httpService = cloneref(game:GetService('HttpService'));

do -- vac funcs
	vac.objects = {};
	vac.connections = {};

	function vac.create(name, props)
		if (not name) then return; end;
		props = typeof(props) == 'table' and props or {};

		local draw = name == 'Square' or name == 'Line' or name == 'Text' or name == 'Quad' or name == 'Circle' or name == 'Triangle';
		local obj = draw and Drawing or Instance;

		local inst = obj.new(name);
		for prop, val in next, props do
			inst[prop] = val;
		end;

		table.insert(vac.objects, {obj = inst, drawn = draw});
		return inst;
	end;

	function vac.connect(signal, func)
		local listener = signal:Connect(func);
		table.insert(vac.connections, listener);

		return listener;
	end;

	function vac.allowDraw(gui)
		local doing, dInput, mPos, fPos = false, false, false, false;
		local tInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);

		gui.InputBegan:Connect(function(input)
			if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return; end;
			doing, mPos, fPos = true, input.Position, gui.Position;

			input.Changed:Connect(function()
				if (input.UserInputState ~= Enum.UserInputState.End) then return; end;
				doing = false;
			end);
		end);

		gui.InputChanged:Connect(function(input)
			if (input.UserInputType ~= Enum.UserInputType.MouseMovement) then return; end;
			dInput = input;
		end);

		inputService.InputChanged:Connect(function(input)
			if (input ~= dInput or not doing) then return; end;
			local delta = input.Position - mPos;

			tweenService:Create(gui, tInfo, {
				Position = UDim2.new(fPos.X.Scale, fPos.X.Offset + delta.X, fPos.Y.Scale, fPos.Y.Offset + delta.Y)
			}):Play();
		end);
	end;

	function vac.unload()
		for _, v in next, vac.connections do
			if (v.Disconnect) then pcall(function() v:Disconnect() end); continue; end;
			if (v.disconnect) then pcall(function() v:disconnect() end); continue; end;
		end;

		for _, v in next, vac.objects do
			if (v.drawn) then pcall(function() v.obj:Remove(); end); end;
			if (v.obj.Destroy) then pcall(function() v.obj:Destroy(); end); end;
		end;

		vac, ui, commands = nil, nil, nil;
		getgenv().vac = nil;
	end;

	function vac.log(text, err, color)
		if (not ui.uiDone) then return; end;

		for i = 9, 2, -1 do
			ui['output' .. i].Text = ui['output' .. (i - 1)].Text;
			ui['output' .. i].TextColor3 = ui['output' .. (i - 1)].TextColor3;
		end;

		local prefix = '[?]';
		if (err == 0) then
			prefix = '[*]';
		elseif (err == 1) then
			prefix = '[-]';
		elseif (err == 2) then
			prefix = '[!]';
		end;

		ui.output1.Text = prefix .. ' ' .. text;
		ui.output1.TextColor3 = color or vac.constants.colors.white;
	end;

	function vac.decode(data)
		if (not data) then return; end;

		local suc, res = pcall(httpService.JSONDecode, httpService, data);
		if (not suc) then
			repeat
				suc, res = pcall(httpService.JSONDecode, httpService, data);
				task.wait();
			until suc;
		end;

		return res;
	end;

	function vac.encode(data)
		if (not data) then return; end;

		local suc, res = pcall(httpService.JSONEncode, httpService, data);
		if (not suc) then
			repeat
				suc, res = pcall(httpService.JSONEncode, httpService, data);
				task.wait();
			until suc;
		end;

		return res;
	end;
end;

do -- vac debug
	vac.debug = {};

	function vac.debug.print(data, options)
		if (not data) then
			return print('data is nil');
		end;

		options = typeof(options) == 'table' and options or {};

		if (typeof(data) == 'table') then
			options.indent = typeof(options.indent) == 'number' and options.indent or 0;

			local indent = string.rep('    ', options.indent);

			for k, v in next, data do
				local key = tostring(k);
				if (type(k) == 'string') then
					key = string.format('[%q]', k);
				elseif (type(k) == 'number') then
					key = string.format('[%d]', k);
				end;

				if (type(v) == 'table') then
					print(string.format('%s%s = {', indent, key));
					vac.debug.print(v, {indent = options.indent + 1});
					print(string.format('%s},', indent));
				else
					local val = tostring(v);
					if (type(v) == 'string') then
						val = string.format('%q', v);
					elseif (type(v) == 'number') then
						val = string.format('%g', v);
					end;

					print(string.format('%s%s = %s,', indent, key, val));
				end;
			end;
		elseif (typeof(data) == 'string') then
			print(data);
		end;
	end;

	function vac.debug.executeRaw(url, json)
		if (not url) then return; end;

		local suc, res = pcall(game.HttpGet, game, url);
		if (not suc or res:sub(1, 1) == '4' or res:sub(1, 1) == '5') then
			return '4/5 error', res;
		end;

		if (json) then return res; end;

		local func, err = loadstring(res);
		if (not func) then
			return 'syntax error', err;
		end;

		func();

		return 'ok';
	end;

	function vac.debug.getFunc(func, name)
		if (not func) then
			vac.log(string.format('missing function "%s"', tostring(name)), 1, vac.constants.colors.yellow);
			return false;
		end;

		return true;
	end;
end;

do -- vac store
	vac.constants = {};
	vac.constants.colors = {};

	vac.game = {};
	vac.temp = {};

	vac.saves = {};
	vac.scriptsaves = {};
	vac.globalsaves = {};

	local rng = Random.new(tick() / math.cos(21 * (math.sqrt(2)) + 3));
	vac.constants.rng = rng;
	vac.constants.randomnumber = rng:NextInteger(7, 10e5);

	vac.game.me = players.LocalPlayer;
	vac.game.mouse = players.LocalPlayer:GetMouse();

	vac.game.cam = workspace.CurrentCamera;

	vac.game.id = game.PlaceId;
	vac.game.job = game.JobId;

	task.spawn(function()
		local jsonData = game:HttpGet('https://api.github.com/repos/Iratethisname10/vac/commits?path=main.lua');
		local luaData = vac.decode(jsonData);

		vac.constants.commitversion = luaData[1].sha;
	end);

	task.spawn(function()
		local jsonData = game:HttpGet('https://raw.githubusercontent.com/Iratethisname10/vac/refs/heads/main/version.json');
		local luaData = vac.decode(jsonData);

		vac.constants.scriptversion = luaData.ver;
	end);

	vac.constants.colors.black = Color3.fromRGB(0, 0, 0);
	vac.constants.colors.white = Color3.fromRGB(255, 255, 255);
	vac.constants.colors.red = Color3.fromRGB(255, 0, 0);
	vac.constants.colors.orange = Color3.fromRGB(255, 165, 0);
	vac.constants.colors.yellow = Color3.fromRGB(239, 255, 60);
	vac.constants.colors.green = Color3.fromRGB(0, 255, 0);

	vac.temp.flyspeed = 50;
	vac.temp.speedspeed = 50;
	vac.temp.freecamspeed = 50;
end;

do -- ui
	local coreUi = cloneref(game:GetService('CoreGui'));

	ui.baseUi = vac.create('ScreenGui', {
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = 999,
		OnTopOfCoreBlur = true,
		ResetOnSpawn = false
	});

	ui.holder = vac.create('Frame', {
		Visible = false,
		ZIndex = 999,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 945, 0, 50),
		Size = UDim2.new(0, 525, 0, 277),
		Active = false,
		Parent = ui.baseUi
	});

	ui.outputHolder = vac.create('Frame', {
		BackgroundColor3 = Color3.new(0.117647, 0.117647, 0.117647),
		BorderSizePixel = 0,
		Position = UDim2.new(0, -8, 0, 19),
		Size = UDim2.new(0, 525, 0, 253),
		Style = Enum.FrameStyle.RobloxRound,
		Visible = false,
		Parent = ui.holder
	});

	local START = 0.849240005;
	local INCREMENT = 0.106719374;

	for i = 1, 9, 1 do
		ui['output' .. i] = vac.create('TextLabel', {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.0157605428, 0, START - (i - 1) * INCREMENT, 0),
			Size = UDim2.new(0, 500, 0, 27),
			Font = Enum.Font.Code,
			Text = '',
			TextColor3 = Color3.new(0.698039, 0.698039, 0.698039),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = ui.outputHolder
		});
	end;

	ui.entry = vac.create('Frame', {
		BackgroundColor3 = Color3.new(0.117647, 0.117647, 0.117647),
		BorderSizePixel = 0,
		Position = UDim2.new(-0.0152380951, 0, 0.965582669, 0),
		Size = UDim2.new(0, 525, 0, 38),
		Parent = ui.holder
	});

	ui.entryLabel = vac.create('TextLabel', {
		BackgroundTransparency = 1,
		Position = UDim2.new(-0.0152380941, 0, 0, 0),
		Size = UDim2.new(0, 137, 0, 36),
		Font = Enum.Font.Code,
		Text = 'enter command >',
		TextColor3 = Color3.new(1, 0.333333, 0),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = ui.entry
	});

	ui.commandSuggestion = vac.create('TextLabel', {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.274285644, 0, 0, 0),
		Size = UDim2.new(0, 341, 0, 35),
		Font = Enum.Font.Code,
		Text = '',
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(100,100,100),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ui.entry
	});

	ui.commandLine = vac.create('TextBox', {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(-0, 0, 0, 0),
		Size = UDim2.new(0, 341, 0, 35),
		Font = Enum.Font.Code,
		PlaceholderText = '...',
		Text = '',
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = ui.commandSuggestion
	});

	do -- waypoints ui
		ui.waypointsHolder = vac.create('Frame', {
			Visible = false,
			ZIndex = 999,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 80, 0, 430),
			Size = UDim2.new(0, 430, 0, 277),
			Active = false,
			Parent = ui.baseUi
		});

		ui.waypointsContentHolder = vac.create('ScrollingFrame', {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, -8, 0, 19),
			Size = UDim2.new(0, 425, 0, 253),
			Visible = false,
			BackgroundTransparency = 0.3,
			ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75),
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Parent = ui.waypointsHolder
		});

		ui.waypointsLayout = vac.create('UIListLayout', {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
			Parent = ui.waypointsContentHolder
		});

		ui.waypointsLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			local contentSize = ui.waypointsLayout.AbsoluteContentSize.Y;
			local size = ui.waypointsContentHolder.AbsoluteSize.Y;
			ui.waypointsContentHolder.CanvasSize = UDim2.new(0, 0, 0, contentSize);

			ui.waypointsContentHolder.ScrollBarThickness = contentSize > size and 4 or 0;
		end);

		vac.allowDraw(ui.waypointsHolder);
	end;

	do -- cmds ui
		ui.cmdsHolder = vac.create('Frame', {
			Visible = false,
			ZIndex = 999,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 862, 0, 481),
			Size = UDim2.new(0, 430, 0, 277),
			Active = false,
			Parent = ui.baseUi
		});

		ui.cmdsContentHolder = vac.create('ScrollingFrame', {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, -8, 0, 19),
			Size = UDim2.new(0, 455, 0, 253),
			Visible = false,
			BackgroundTransparency = 0.3,
			ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75),
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Parent = ui.cmdsHolder
		});

		ui.cmdsLayout = vac.create('UIListLayout', {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, -5),
			Parent = ui.cmdsContentHolder
		});

		ui.cmdsDescriptionHolder = vac.create('Frame', {
			BackgroundColor3 = Color3.new(0.117647, 0.117647, 0.117647),
			BorderSizePixel = 0,
			Position = UDim2.new(-0.0152380951, -1, 0.965582669, 0),
			Size = UDim2.new(0, 454, 0, 38),
			Parent = ui.cmdsHolder
		});

		ui.cmdsDescription = vac.create('TextLabel', {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 445, 0, 36),
			Font = Enum.Font.Code,
			Text = '',
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = ui.cmdsDescriptionHolder
		});

		vac.create('UIPadding', {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			Parent = ui.cmdsDescription
		});

		vac.allowDraw(ui.cmdsHolder);
	end;

	vac.allowDraw(ui.holder);

	ui.baseUi.Parent = gethui and gethui() or coreUi;

	ui.holder.Visible = true;
	ui.outputHolder.Visible = true;

	ui.uiDone = true;
end;

do -- connections
	local inputs = {
		semicolon = function()
			ui.commandLine:CaptureFocus();
			runService.RenderStepped:Wait();

			ui.commandLine.Text = '';
		end,
		tab = function()
			if (not ui.commandLine:IsFocused()) then return; end;
			if (ui.commandSuggestion.Text == '') then return; end;

			local suggestion = ui.commandSuggestion.Text;
			runService.RenderStepped:Wait();

			ui.commandLine.Text = suggestion .. ' ';
			ui.commandLine.CursorPosition = #ui.commandLine.Text + 1;
		end
	};

	vac.connect(inputService.InputBegan, function(input)
		local code = input.KeyCode.Name:lower();

		if (code == vac.scriptsaves.uikeybind) then
			ui.holder.Visible = not ui.holder.Visible;
			ui.outputHolder.Visible = not ui.outputHolder.Visible;

			if (ui.cmdsHolder.Visible or ui.cmdsContentHolder.Visible) then
				ui.cmdsHolder.Visible = false;
				ui.cmdsContentHolder.Visible = false;
			end;
		end;

		if (not inputs[code]) then return; end;
		inputs[code]();
	end);

	vac.connect(ui.commandLine.FocusLost, function()
		local args = ui.commandLine.Text:split(' ');

		ui.commandLine.Text = '';
		ui.commandSuggestion.Text = '';

		if (args[1]:len() < 1) then return; end;

		local command = args[1];
		table.remove(args, 1);

		commands.execute(command, unpack(args));
	end);

	vac.connect(ui.commandLine:GetPropertyChangedSignal('Text'), function()
		local input = ui.commandLine.Text:lower();
		if (input:len() < 1) then
			ui.commandLine.Text = '';
			ui.commandSuggestion.Text = '';
			return;
		end;

		local sorted = {};
		for i, v in next, commands.commands do
			table.insert(sorted, { name = i, aliases = v.aliases });
		end
		table.sort(sorted, function(a, b)
			return #a.name < #b.name;
		end);

		for _, v in next, sorted do
			if (v.name:sub(1, #input) == input) then
				ui.commandSuggestion.Text = v.name;
				return;
			end;

			for _, v2 in next, v.aliases do
				if (v2:sub(1, #input) == input) then
					ui.commandSuggestion.Text = v.name;
					return;
				end;
			end;
		end;

		ui.commandSuggestion.Text = '';
	end);
end;

do -- command base
	commands.commands = {};

	function commands.findCommand(command)
		if (commands.commands[command]) then
			return commands.commands[command];
		end;

		for _, v in next, commands.commands do
			if table.find(v.aliases, command) then
				return v;
			end;
		end;

		return nil;
	end;

	function commands.execute(command, ...)
		command = command:gsub('^%s+', ''):gsub('%s+$', '');
		command = command:gsub('%s+', ' ');

		local cmd = commands.findCommand(command);
		if (not cmd) then return; end;

		local suc, res = pcall(cmd.func, ...);
		if (suc) then return; end;

		local err = res:match(':%d+: .+') or '???';
		vac.log(string.format('execution error in command "%s":', command), 2, vac.constants.colors.red);
		vac.log(err, 2, vac.constants.colors.red);
	end;

	function commands.register(name, func, aliases)
		if (not name or not func) then return; end;
		if (typeof(aliases) ~= 'table') then aliases = { name }; end;

		commands.commands[name:lower()] = { aliases = aliases, func = func };
	end;
end;

do -- file system
	if (not isfolder('vocatsadmin')) then makefolder('vocatsadmin'); end;

	if (not isfolder('vocatsadmin/cache')) then makefolder('vocatsadmin/cache'); end;
	if (not isfolder('vocatsadmin/saves')) then makefolder('vocatsadmin/saves'); end;

	if (not isfile('vocatsadmin/saves/_script.json')) then writefile('vocatsadmin/saves/_script.json', '[]'); end; -- script settings; keybind
	if (not isfile('vocatsadmin/saves/_global.json')) then writefile('vocatsadmin/saves/_global.json', '[]'); end; -- global configs / waypoints

	local file = string.format('vocatsadmin/saves/%s.json', vac.game.id);

	if (not isfile(file)) then
		writefile(file, '[]');
	end;

	function vac.updateSaves(where)
		if (where == 'script') then
			writefile('vocatsadmin/saves/_script.json', vac.encode(vac.scriptsaves));
		elseif (where == 'global') then
			writefile('vocatsadmin/saves/_global.json', vac.encode(vac.globalsaves));
		else
			writefile(file, vac.encode(vac.saves));
		end
	end;

	local savesDone, scriptSavesDone, globalSavesDone = false, false, false;
	task.spawn(function()
		local jsonData = readfile(file);
		if (not jsonData) then savesDone = true; return; end;

		local luaData = vac.decode(jsonData);

		vac.saves.waypoints = luaData.waypoints or {};
		vac.saves.configs = luaData.configs or {};

		savesDone = true;
	end);

	task.spawn(function()
		local jsonData = readfile('vocatsadmin/saves/_script.json');
		if (not jsonData) then scriptSavesDone = true; return; end;

		local luaData = vac.decode(jsonData);

		vac.scriptsaves.uikeybind = luaData.uikeybind or 'insert';

		scriptSavesDone = true;
	end);

	--[[
		task.spawn(function()
			local jsonData = readfile('vocatsadmin/saves/_global.json');
			if (not jsonData) then globalSavesDone = true; return; end;

			local luaData = vac.decode(jsonData);

			vac.saves.waypoints = luaData.waypoints or {};

			globalSavesDone = true;
		end);
	]]

	repeat task.wait(); until savesDone and scriptSavesDone; --[[ and globalSavesDone]]
end;

do -- script funcs
	vac.utilfuncs = {};
	vac.funcs = {};

	local funcs, utils, temp = vac.funcs, vac.utilfuncs, vac.temp;
	local lplr = vac.game.me;
	local cam = vac.game.cam;

	local actionService = cloneref(game:GetService('ContextActionService'));

	function utils.getMovePart()
		local root = vac.utilfuncs.getRoot();
		local hum = lplr.Character:FindFirstChildOfClass('Humanoid');
		if (not root or not hum) then return nil; end;

		local seat = hum.SeatPart;
		if (not seat or not seat:IsA('VehicleSeat')) then return root; end;

		return seat.Parent and seat.Parent.PrimaryPart or root;
	end;

	function utils.getPlayer(name, includeAll)
		if (name:len() < 1) then return nil; end;

		if (name == 'me') then
			return lplr;
		elseif (name == 'random') then
			return players:GetPlayers()[vac.constants.rng:NextInteger(2, #players:GetPlayers())];
		elseif (name == 'all' and includeAll) then
			local returns = {};

			for _, v in next, players:GetPlayers() do
				if (v == lplr or table.find(returns, v)) then continue; end;
				table.insert(returns, v);
			end;

			return returns;
		else
			for _, v in next, players:GetPlayers() do
				if (not v.Name:lower():find(name:lower()) and not v.DisplayName:lower():find(name:lower())) then continue; end;
				return v;
			end;
		end;
	end;

	function utils.getRoot()
		local root = lplr.Character and lplr.Character:FindFirstChild('HumanoidRootPart');
		if (not root) then return nil; end;

		return root;
	end;

	function utils.getHum()
		local hum = lplr.Character and lplr.Character:FindFirstChildOfClass('Humanoid');
		if (not hum) then return nil; end;

		return hum;
	end;

	function utils.getBoth()
		return utils.getRoot(), utils.getHum();
	end;

	function funcs.fly(toggle, cframe, vfly)
		if (temp.flyloop) then
			temp.flyloop:Disconnect();
			temp.flyloop = nil;
		end;

		actionService:UnbindAction('vacvflyup');
		actionService:UnbindAction('vacvflydown');

		if (not toggle) then
			local root = vac.utilfuncs.getRoot();
			if (root) then
				root.AssemblyLinearVelocity = Vector3.zero;
				root.AssemblyAngularVelocity = Vector3.zero;
			end;

			return;
		end;

		if (vfly) then
			actionService:BindAction('vacvflyup', function(_, state)
				if (state == Enum.UserInputState.Begin) then
					temp.flyvertical = 1;
				elseif (state == Enum.UserInputState.End) then
					temp.flyvertical = 0;
				end
			end, false, Enum.KeyCode.Space);

			actionService:BindAction('vacvflydown', function(_, state)
				if (state == Enum.UserInputState.Begin) then
					temp.flyvertical = -1;
				elseif (state == Enum.UserInputState.End) then
					temp.flyvertical = 0;
				end
			end, false, Enum.KeyCode.LeftControl);
		end;

		temp.flyloop = vac.connect(runService.Heartbeat, function(dt)
			local root = vac.utilfuncs.getRoot();
			if (not root) then return; end;

			local hum = lplr.Character:FindFirstChildOfClass('Humanoid');
			if (not hum) then return; end;

			if (inputService:IsKeyDown(Enum.KeyCode.Space) and not inputService:GetFocusedTextBox()) then
				temp.flyvertical = 1;
			elseif (inputService:IsKeyDown(Enum.KeyCode.LeftControl) and not inputService:GetFocusedTextBox()) then
				temp.flyvertical = -1;
			else
				temp.flyvertical = 0;
			end;

			local moveDir = hum.MoveDirection;

			if (cframe) then
				root.AssemblyLinearVelocity = Vector3.zero;
				root.AssemblyAngularVelocity = Vector3.zero;

				root.CFrame += Vector3.new(moveDir.X, temp.flyvertical, moveDir.Z) * temp.flyspeed * dt + Vector3.new(0, 0.04, 0);
			else
				if (vfly) then
					utils.getMovePart().AssemblyLinearVelocity = Vector3.new(moveDir.X, temp.flyvertical, moveDir.Z) * temp.flyspeed;
				else
					root.AssemblyLinearVelocity = Vector3.new(moveDir.X, temp.flyvertical, moveDir.Z) * temp.flyspeed + Vector3.new(0, 2.25, 0);
				end;
			end;
		end);
	end;

	function funcs.speed(toggle, cframe)
		if (temp.speedloop) then
			temp.speedloop:Disconnect();
			temp.speedloop = nil;
		end;

		if (not toggle) then
			local root = vac.utilfuncs.getRoot();
			if (root) then
				root.AssemblyLinearVelocity = Vector3.zero;
				root.AssemblyAngularVelocity = Vector3.zero;
			end;

			return;
		end;

		temp.speedloop = vac.connect(runService.Heartbeat, function(dt)
			local root = vac.utilfuncs.getRoot();
			if (not root) then return; end;

			local hum = lplr.Character:FindFirstChildOfClass('Humanoid');
			if (not hum or hum.Sit) then return; end;

			local moveDir = hum.MoveDirection;
			local preVelo = root.AssemblyLinearVelocity;

			if (cframe) then
				root.AssemblyLinearVelocity = Vector3.zero;
				root.AssemblyAngularVelocity = Vector3.zero;

				root.CFrame += Vector3.new(moveDir.X, 0, moveDir.Z) * temp.speedspeed * dt;
			else
				root.AssemblyLinearVelocity = Vector3.new(moveDir.X * temp.speedspeed, preVelo.Y, moveDir.Z * temp.speedspeed);
			end;
		end);
	end;

	do -- role watch
		temp.rolewatch = {};

		local groupService = cloneref(game:GetService('GroupService'));

		local function getGroupInfo()
			local suc, res = pcall(groupService.GetGroupInfoAsync, groupService, tonumber(temp.rolewatch.group));
			if (not suc) then
				repeat
					suc, res = pcall(groupService.GetGroupInfoAsync, groupService, tonumber(temp.rolewatch.group));
				until suc;
			end;

			return res;
		end;

		local function getGroupRank(player)
			local suc, res = pcall(player.GetRankInGroup, player, tonumber(temp.rolewatch.group));
			if (not suc) then
				repeat
					suc, res = pcall(player.GetRankInGroup, player, tonumber(temp.rolewatch.group));
				until suc;
			end;

			return res;
		end;

		local function getRoleId()
			local roles = getGroupInfo().Roles;

			for _, v in next, roles do
				if (v.Name:lower() ~= temp.rolewatch.role:lower()) then continue; end;
				return v.Rank;
			end;

			return nil;
		end;

		local function onPlayerAdded(player, role)
			if (player == lplr) then return; end;

			local rank = getGroupRank(player);
			if (rank < role) then return; end;

			if (temp.rolewatch.action == 'hop') then
				commands.execute('rejoin');
			else
				lplr:Kick(string.format('\n\nkicked by role watcher:\nplayer - %s\nrank - %s\n', player.Name, rank));
			end;
		end;

		function funcs.rwInit()
			local role = getRoleId();
			if (not role) then
				vac.log('role does not exist', 1, vac.constants.colors.orange);
				return;
			end;

			vac.log(string.format('watching group %s for %s', temp.rolewatch.group, temp.rolewatch.role), 0);

			for _, v in next, players:GetPlayers() do
				task.spawn(onPlayerAdded, v, role);
			end;

			temp.rolewatch.loop = vac.connect(players.PlayerAdded, function(player)
				onPlayerAdded(player, role)
			end);
		end;
	end;

	function funcs.nofog(toggle, service)
		if (temp.nofog) then
			temp.nofog:Disconnect();
			temp.nofog = nil;
		end;

		if (not toggle) then return; end;

		temp.nofog = vac.connect(runService.RenderStepped, function()
			service.FogEnd = 10e4;

			for _, v in next, service:GetChildren() do
				if (not v:IsA('Atmosphere')) then continue; end;
				v.Density = 0;
			end;
		end);
	end;

	function funcs.fullbright(toggle, service)
		if (temp.fullbright) then
			temp.fullbright:Disconnect();
			temp.fullbright = nil;
		end;

		if (not toggle) then return; end;

		temp.fullbright = vac.connect(runService.RenderStepped, function()
			service.Brightness = 2;
			service.ClockTime = 14;
			service.FogEnd = 100000;
			service.GlobalShadows = false;
			service.OutdoorAmbient = Color3.fromRGB(128, 128, 128);
		end);
	end;

	do -- esp
		local esp = {};

		do
			esp.__index = esp;

			function esp.new(player)
				local self = setmetatable({}, esp);

				self._player = player;
				self._playerName = player.Name;

				self._visible = false;

				self._label = Drawing.new('Text');
				self._label.Visible = false;
				self._label.Center = true;
				self._label.Outline = true;
				self._label.Text = '';
				self._label.Font = Drawing.Fonts.Plex;
				self._label.Size = 20;
				self._label.Color = vac.constants.colors.white;

				self._box = Drawing.new('Quad');
				self._box.Visible = false;
				self._box.Thickness = 1;
				self._box.Filled = false;
				self._box.Color = vac.constants.colors.white;

				return self;
			end;

			function esp:Hide()
				if (not self._visible) then return; end;
				self._visible = false;

				self._label.Visible = false;
				self._box.Visible = false;
			end;

			function esp:Destroy()
				self._label:Destroy();
				self._label = nil;

				self._box:Destroy();
				self._box = nil;
			end;

			function esp:Update()
				local char = self._player.Character;
				if (not char) then return self:Hide(); end;

				local root = char:FindFirstChild('HumanoidRootPart');
				local hum = char:FindFirstChildOfClass('Humanoid');
				if (not root or not hum) then return self:Hide(); end;

				local rootPos = root.CFrame.Position;

				local pos, visible = cam:WorldToViewportPoint(rootPos + cam.CFrame:VectorToWorldSpace(Vector3.new(0, 3.25, 0)));

				self._visible = visible;

				local boxTopRight = cam:WorldToViewportPoint(rootPos + cam.CFrame:VectorToWorldSpace(Vector3.new(2.5, 3, 0)));
				local boxBottomLeft = cam:worldToViewportPoint(rootPos + cam.CFrame:VectorToWorldSpace(Vector3.new(-2.5, -4.5, 0)));

				local topRightX, topRightY = boxTopRight.X, boxTopRight.Y;
				local bottomLeftX, bottomLeftY = boxBottomLeft.X, boxBottomLeft.Y;

				self._label.Visible = visible;
				self._box.Visible = visible;

				self._label.Position = Vector2.new(pos.X, pos.Y - self._label.TextBounds.Y);
				self._label.Text = self._playerName .. ' | ' .. math.round(hum.Health) .. ' | ' .. math.round((rootPos - cam.CFrame.Position).Magnitude);

				self._box.PointA = Vector2.new(topRightX, topRightY);
				self._box.PointB = Vector2.new(bottomLeftX, topRightY);
				self._box.PointC = Vector2.new(bottomLeftX, bottomLeftY);
				self._box.PointD = Vector2.new(topRightX, bottomLeftY);
			end;
		end;

		local espedPlayers = {};

		local function onPlayerAdded(player)
			if (player == lplr) then return; end;

			local espPlayer = esp.new(player);
			table.insert(espedPlayers, espPlayer);
		end;

		local function onPlayerRemoving(player)
			if (player == lplr) then return; end;

			if (table.find(espedPlayers, player)) then
				espedPlayers[player]:Destroy();
			end;
		end;

		vac.connect(players.PlayerAdded, onPlayerAdded);
		vac.connect(players.PlayerRemoving, onPlayerRemoving);

		for _, v in next, players:GetPlayers() do
			task.spawn(onPlayerAdded, v);
		end;

		local lastUpdateESPAt = 0;

		function funcs.espInit()
			funcs.espStop();

			vac.temp.esploop = vac.connect(runService.RenderStepped, function()
				if (tick() - lastUpdateESPAt < 0.01) then return; end;
				lastUpdateESPAt = tick();

				for _, v in next, espedPlayers do
					v:Update();
				end;
			end);
		end;

		function funcs.espStop()
			if (vac.temp.esploop) then
				vac.temp.esploop:Disconnect();
				vac.temp.esploop = nil;
			end;

			for _, v in next, espedPlayers do
				v:Hide();
			end;
		end;
	end;

	do -- freecam
		local spring = {};
		local playerState = {};
		local input = {};

		local CONTEXT_HIGH = Enum.ContextActionPriority.High.Value;

		do -- spring
			spring.__index = spring;

			function spring.new(frequency, position)
				local self = setmetatable({}, spring);

				self.f = frequency;
				self.p = position;
				self.v = position * 0;

				return self;
			end;

			function spring:Update(deltaTime, goal)
				local f = self.f * 2 * math.pi;
				local p0 = self.p;
				local v0 = self.v;

				local offset = goal - p0;
				local decay = math.exp(-f * deltaTime);

				local p1 = goal + (v0 * deltaTime - offset * (f * deltaTime + 1)) * decay;
				local v1 = (f * deltaTime * (offset * f - v0) + v0) * decay;

				self.p = p1;
				self.v = v1;

				return p1;
			end;

			function spring:Reset(position)
				self.p = position;
				self.v = position * 0;
			end;
		end;

		do -- playerState
			playerState.__index = playerState;

			function playerState.new()
				local self = setmetatable({}, playerState);

				self._oldCameraType = cam.CameraType;
				cam.CameraType = Enum.CameraType.Custom;

				self._oldCameraCFrame = cam.CFrame;
				self._oldCameraFocus = cam.Focus;

				self._oldMouseIconEnabled = inputService.MouseIconEnabled;
				inputService.MouseIconEnabled = true;

				self._oldMouseBehavior = inputService.MouseBehavior;
				inputService.MouseBehavior = Enum.MouseBehavior.Default;

				return self;
			end;

			function playerState:Destroy()
				if (
					not self._oldCameraType
					or not self._oldCameraCFrame
					or not self._oldCameraFocus
					or not self._oldMouseIconEnabled
					or not self._oldMouseBehavior
				) then
					return;
				end;

				cam.CameraType = self._oldCameraType;
				self._oldCameraType = nil;

				cam.CFrame = self._oldCameraCFrame;
				self._oldCameraCFrame = nil;

				cam.Focus = self._oldCameraFocus;
				self._oldCameraFocus = nil;

				inputService.MouseIconEnabled = self._oldMouseIconEnabled;
				self._oldMouseIconEnabled = nil;

				inputService.MouseBehavior = self._oldMouseBehavior;
				self._oldMouseBehavior = nil;
			end;
		end;

		do -- input
			local mouse = {Delta = Vector2.new()};
			local keyboard = { W = 0, A = 0, S = 0, D = 0, E = 0, Q = 0, Up = 0, Down = 0, LeftShift = 0 };

			local PAN_MOUSE_SPEED = Vector2.new(3, 3) * (math.pi / 64);
			local NAV_ADJ_SPEED = 0.75;

			local NAV_SPEED = 1;

			function input.vel(deltaTime)
				NAV_SPEED = math.clamp(NAV_SPEED + deltaTime * (keyboard.Up - keyboard.Down) * NAV_ADJ_SPEED, 0.01, 4);

				local localKeyboard = Vector3.new(keyboard.D - keyboard.A, keyboard.E - keyboard.Q, keyboard.S - keyboard.W) * (Vector3.one * (temp.freecamspeed / 20));
				local shifting = inputService:IsKeyDown(Enum.KeyCode.LeftShift);

				return (localKeyboard) * (NAV_SPEED * (shifting and 0.2 or 1));
			end;

			function input.pan()
				local mousePan = mouse.Delta * PAN_MOUSE_SPEED;
				mouse.Delta = Vector2.new();

				return mousePan;
			end;

			local function _keypress(_, state, object)
				keyboard[object.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0;
				return Enum.ContextActionResult.Sink;
			end

			local function _mousePan(_, _, object)
				local delta = object.Delta;
				mouse.Delta = Vector2.new(-delta.y, -delta.x);
				return Enum.ContextActionResult.Sink;
			end

			local function _zero(tab)
				for k, v in tab do
					tab[k] = v * 0;
				end;
			end;

			function input.start()
				actionService:BindActionAtPriority('vacfckeyboard', _keypress, false, CONTEXT_HIGH, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.Up, Enum.KeyCode.Down);
				actionService:BindActionAtPriority('vacfcmouse', _mousePan, false, CONTEXT_HIGH, Enum.UserInputType.MouseMovement);
			end;

			function input.stop()
				NAV_SPEED = 1;

				_zero(mouse);
				_zero(keyboard);

				actionService:UnbindAction('vacfckeyboard');
				actionService:UnbindAction('vacfcmouse');
			end;
		end;

		local cameraFov;
		local function getFocusDistance(cframe)
			local znear = 0.1;
			local viewport = cam.ViewportSize;
			local projy = 2 * math.tan(cameraFov / 2);
			local projx = viewport.X / viewport.Y * projy;
			local fx = cframe.RightVector;
			local fy = cframe.UpVector;
			local fz = cframe.LookVector;

			local minVect = Vector3.zero;
			local minDist = 512;

			for x = 0, 1, 0.5 do
				for y = 0, 1, 0.5 do
					local cx = (x - 0.5) * projx;
					local cy = (y - 0.5) * projy;
					local offset = fx * cx - fy * cy + fz;
					local origin = cframe.Position + offset * znear;
					local res = workspace:Raycast(origin, offset.unit * minDist);
					res = res and res.Position or Vector3.zero;

					local dist = (res - origin).magnitude;
					if (minDist > dist) then
						minDist = dist;
						minVect = offset.unit;
					end;
				end;
			end;

			return fz:Dot(minVect) * minDist;
		end;

		local cameraPos = Vector3.zero;
		local cameraRot = Vector2.new();
		local velSpring = spring.new(5, Vector3.zero);
		local panSpring = spring.new(5, Vector2.new());

		function funcs.freecam(toggle)
			input.stop();

			if (temp.freecamloop) then
				temp.freecamloop:Disconnect();
				temp.freecamloop = nil;
			end;

			playerState:Destroy();

			if (not toggle) then return; end;

			local cameraCFrame = cam.CFrame;
			local pitch, yaw = cameraCFrame:ToEulerAnglesYXZ();

			cameraRot = Vector2.new(pitch, yaw);
			cameraPos = cameraCFrame.Position;
			cameraFov = cam.FieldOfView;

			velSpring:Reset(Vector3.zero);
			panSpring:Reset(Vector2.new());

			playerState.new();

			temp.freecamloop = vac.connect(runService.RenderStepped, function(dt)
				local vel = velSpring:Update(dt, input.vel(dt));
				local pan = panSpring:Update(dt, input.pan());
				local zoomFactor = math.sqrt(math.tan(math.rad(70 / 2)) / math.tan(math.rad(cameraFov / 2)));

				cameraRot += pan * Vector2.new(0.75, 1) * 8 * (dt / zoomFactor);
				cameraRot = Vector2.new(math.clamp(cameraRot.X, -math.rad(90), math.rad(90)), cameraRot.Y % (2 * math.pi));

				local newCFrame = CFrame.new(cameraPos) * CFrame.fromOrientation(cameraRot.X, cameraRot.Y, 0) * CFrame.new(vel * Vector3.one * 64 * dt);
				cameraPos = newCFrame.Position;

				cam.CFrame = newCFrame;
				cam.Focus = newCFrame * CFrame.new(0, 0, -getFocusDistance(newCFrame));
			end);

			input.start();
		end;
	end;

	do -- waypoints
		function funcs.addWaypoint(name, cordFrame, save)
			name = typeof(name) == 'table' and table.concat(name, ' ') or name;

			local label = vac.create('TextLabel', {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -10, 0, 27),
				Font = Enum.Font.Code,
				Text = name,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = ui.waypointsContentHolder
			});

			vac.create('UIPadding', {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				Parent = label
			});

			local deleteWaypoint = vac.create('TextButton', {
				BackgroundColor3 = Color3.fromRGB(52, 52, 52),
				Size = UDim2.new(0.145, 0, 0.75, 0),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Text = 'delete',
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 16,
				Font = Enum.Font.Code,
				Parent = label
			});

			local toWaypoint = vac.create('TextButton', {
				BackgroundColor3 = Color3.fromRGB(52, 52, 52),
				Size = UDim2.new(0.18, 0, 0.65, 0),
				Position = UDim2.new(1, -70, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Text = 'teleport',
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 16,
				Font = Enum.Font.Code,
				Parent = label
			});

			vac.connect(deleteWaypoint.MouseButton1Click, function()
				label:Destroy();
				vac.saves.waypoints[name] = nil;
				vac.updateSaves();
			end);

			vac.connect(toWaypoint.MouseButton1Click, function()
				local root = utils.getRoot();
				if (not root) then return; end;

				local components = vac.saves.waypoints[name];
				root.CFrame = CFrame.new(components[1], components[2], components[3]);
			end);

			if (save) then
				local root = utils.getRoot();
				if (not root) then return; end;

				local components = cordFrame or {root.CFrame:GetComponents()};
				vac.saves.waypoints[name] = {components[1], components[2], components[3]};
				vac.updateSaves();
			end;
		end;

		for i, v in next, vac.saves.waypoints do
			funcs.addWaypoint(i, v, false);
		end;
	end;

	do -- cmds
		function funcs.cmdsInit()
			if (ui.cmdsdone) then return; end;

			local numCmds = 1;
			local sorted = {};

			for i in next, commands.list do
				table.insert(sorted, i);
			end;
			table.sort(sorted);

			for _, v in next, sorted do
				local label = vac.create('TextLabel', {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -10, 0, 27),
					Font = Enum.Font.Code,
					Text = string.format('%s) %s', numCmds, v),
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = ui.cmdsContentHolder
				});

				vac.create('UIPadding', {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					Parent = label
				});

				vac.connect(label.MouseEnter, function()
					ui.cmdsDescription.Text = commands.list[v];
				end);

				vac.connect(label.MouseLeave, function()
					if (ui.cmdsDescription.Text ~= commands.list[v]) then return; end;
					ui.cmdsDescription.Text = '';
				end);

				numCmds += 1;
			end;

			local contentSize = ui.cmdsLayout.AbsoluteContentSize;
			ui.cmdsContentHolder.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y);

			ui.cmdsdone = true;
		end;
	end;

	do -- configs
		local function checkValid(name)
			if (not vac.saves.configs[name]) then
				vac.log(string.format('config "%s" does not exist', name), 1, vac.constants.colors.orange);
				return false;
			end;

			return true;
		end;

		function funcs.saveConfig(name, module)
			if (not commands.findCommand(module)) then
				vac.log(string.format('"%s" is not a valid command', module), 1, vac.constants.colors.orange);
				return;
			end;

			vac.log(string.format('saved "%s" to config "%s"', module, name), 0);

			vac.saves.configs[name] = vac.saves.configs[name] or {};
			table.insert(vac.saves.configs[name], module);
			vac.updateSaves();
		end;

		function funcs.loadConfig(name)
			if (not checkValid(name)) then return; end;

			for _, v in next, vac.saves.configs[name] do
				commands.execute(v);
			end;

			vac.log(string.format('loaded config "%s"', name), 0);
		end;

		function funcs.deleteConfig(name)
			if (not checkValid(name)) then return; end;

			vac.saves.configs[name] = nil;
			vac.updateSaves();

			vac.log(string.format('config "%s" has been deleted', name), 0);
		end;

		function funcs.renameConfig(name, newname)
			if (not checkValid(name)) then return; end;

			local temp = vac.saves.configs[name];
			vac.saves.configs[newname] = temp;
			vac.saves.configs[name] = nil;

			vac.updateSaves();
			temp = nil;

			vac.log(string.format('config "%s" has been renamed to "%s"', name, newname), 0);
		end;
	end;
end;

do -- commands list
	commands.list = {};
	local list = commands.list;

	list['eject'] = 'fully unloades the script';
	list['discord'] = 'joins the discord sever and copies it to your clipboard';
	list['rebindui [key]'] = 'lets you rebind the ui\'s toggle key';
	list['checkversion / checkver'] = 'checks the script version';
	list['reexecute / reexec'] = 'executes the latest version of the script';
	list['commands / cmds'] = 'shows a list of commands';
	list['rejoin / rj'] = 'rejoins the server';
	list['serverhop / sh / shop'] = 'joins another server';
	list['autorejoin / autorj'] = 'rejoins the server when you get kicked';
	list['unautorejoin / unautorj / noautorejoin / noautorj'] = 'disables auto rejoin';
	list['walkspeed / ws [speed?]'] = 'changes your walkspeed';
	list['loopwalkspeed / loopspeed / loopws / lws [speed?]'] = 'loops your walkspeed';
	list['unloopwalkspeed / unloopspeed/  unloopws / unlws'] = 'unloops your walkspeed';
	list['fly [speed?]'] = 'lets you fly';
	list['velocityfly / velofly / flyvelo [speed?]'] = 'manipulates your velocity to let you fly';
	list['vehiclefly / vfly'] = 'lets you fly in vehicles';
	list['unfly / unvehiclefly / unvfly'] = 'disables fly';
	list['speed [speed?]'] = 'lets you go zooooom';
	list['velocityspeed / velospeed / speedvelo [speed?]'] = 'manipulates your velocity to let you go zooooom';
	list['unspeed / nospeed'] = 'disables speed';
	list['teleportwalk / tpwalk [speed?]'] = 'shifts your character by the speed set when you walk';
	list['unteleportwalk / untpwalk'] = 'disables tp walk';
	list['teleportto / goto / to [player]'] = 'teleports you to someone';
	list['safeteleportto / safegoto / safeto'] = 'loads the area you are teleporting to before teleporting you';
	list['inviscam / noclipcam / nccam'] = 'lets your camera noclip';
	list['uninviscam / unnoclipcam'] = 'reverts invis cam';
	list['maxzoom [distance?]'] = 'sets your max zoom distance';
	list['minzoom [distance?]'] = 'sets your min zoom distance';
	list['instantproximityprompts / instantpp / instapp'] = 'lets you instantly fire prox prompts';
	list['uninstantproximityprompts / uninstantpp / uninstapp'] = 'reverts instantpp';
	list['fieldofview / fov [fov?]'] = 'sets your fov';
	list['loopfieldofview / loopfov / lfov [fov?]'] = 'loop sets your fov';
	list['unloopfieldofview / unloopfov / unlfov'] = 'stops looping setting your fov';
	list['rolewatch [group] [role]'] = 'watches if someone from the group with the a certain role joins you';
	list['stoprolewatch / unrolewatch / norolewatch'] = 'disables role watch';
	list['rolewatchleave'] = 'leaves the game when when role watch is triggered (default)';
	list['rolewatchserverhop / rolewatchsh / rolewatchshop / rolewatchhop'] = 'changes server when role watch is triggered';
	list['nofog'] = 'removes fog';
	list['loopnofog / lnofog'] = 'loops remove fog';
	list['unloopnofog / unlnofog'] = 'disables loopnofog';
	list['fullbright / fb'] = 'sets the best lighting';
	list['loopfullbright / loopfb / lfb'] = 'loops full bright';
	list['unloopfullbright / unloopfb / unlfb'] = 'disables loop fullbright';
	list['grabtools'] = 'gives you all tools on the map';
	list['esp'] = 'lets you see peoples name through walls';
	list['noesp / unesp'] = 'disables esp';
	list['dex'] = 'executes dex';
	list['remotespy / rspy'] = 'executes simple spy';
	list['adonisbypass'] = 'bypasses adonis anticheat';
	list['f3x'] = 'gives you f3x building tools';
	list['freecam / fc'] = 'lets your camera fly around';
	list['unfreecam / unfc'] = 'disbales freecam';
	list['waypoints / wp'] = 'lets you set point you can teleport to';
	list['addwaypoint / setwaypoint / swp'] = 'adds a waypoint';
	list['antikick / anticlientkick'] = 'prevets local script from kicking you';
	list['spectate / view [player]'] = 'lets you spectate a player';
	list['unspectate / unview'] = 'stops spectating the player';
	list['hitbox [player] [size?]'] = 'expands the players hitbox';
	list['infjump / airjump'] = 'lets you jump in air';
	list['uninfjump / unairjump'] = 'disables inf jump';
	list['flyjump / jetpack'] = 'makes you fly up when you hold space';
	list['unflyjump / unjetpack'] = 'disables fly jump';
	list['loopbring [player] [distance?]'] = 'brings players to you';
	list['unloopbring'] = 'disables loop bring';
	list['clearerror / clearerr / clrerr'] = 'removes the blur and box when you get kicked';
	list['copyposition / copypos'] = 'copies your position to your clipboard';
	list['copyvector / copyvec'] = 'copies your positin wrapped in a vector3 constructor';
	list['nobloom'] = 'removes and bloom effects in lighting';
	list['noblur'] = 'removes and blur effects in lighting';
	list['configsave [name] [module]'] = 'lets you save a group of modules for easy execution';
	list['configload [name]'] = 'executes all commands in the provided group';
	list['configdelete [name]'] = 'deletes a config';
	list['configrename [name] [newname]'] = 'renames a config to newname';
end;

do -- commands
	local lplr = vac.game.me;
	local cam = vac.game.cam;

	local ppService = cloneref(game:GetService('ProximityPromptService'));
	local tpService = cloneref(game:GetService('TeleportService'));
	local lightService = cloneref(game:GetService('Lighting'));
	local uiService = cloneref(game:GetService('GuiService'));
	local networkClient = cloneref(game:GetService('NetworkClient'));

	commands.register('eject', vac.unload);

	commands.register('discord', function()
		if (setclipboard) then
			setclipboard(string.format('https://discord.gg/%s', discordCode));
			vac.log('server invite copied to clipboard', 0);
		end;

		if (request) then
			for i = 6463, 6472 do
				if (pcall(function()
					request({
						Url = string.format('http://127.0.0.1:%s/rpc?v=1', i),
						Method = 'POST',
						Headers = {
							['Content-Type'] = 'application/json',
							Origin = 'https://discord.com'
						},
						Body = vac.encode({
							cmd = 'INVITE_BROWSER',
							args = {code = discordCode},
							nonce = httpService:GenerateGUID(false)
						})
					});
				end)) then
					break;
				end;
			end;

			return;
		end;

		vac.log(string.format('discord server: discord.gg/%s', discordCode), 0);
	end);

	commands.register('rebindui', function(key)
		local allowedKey = false
		for _, v in next, Enum.KeyCode:GetEnumItems() do
			if (v.Name:lower() ~= key:lower()) then continue; end;

			allowedKey = true;
			break;
		end;

		if (not allowedKey) then
			vac.log(string.format('invalid key "%s"', key), 1, vac.constants.colors.orange);
			return;
		end;

		vac.scriptsaves.uikeybind = key;
		vac.updateSaves('script');
		vac.log(string.format('ui keybind set to "%s"', key:upper()), 0);
	end);

	commands.register('checkversion', function()
		vac.log('getting version, hold on a sec...', 0);

		local sCommit = vac.decode(game:HttpGet('https://api.github.com/repos/Iratethisname10/vac/commits?path=main.lua'))[1].sha:sub(1, 10);

		local cVersion = vac.constants.scriptversion;
		local cCommit = vac.constants.commitversion:sub(1, 10);

		vac.log(string.format('script cached version - %s (%s)', cVersion, cCommit), 0);
		vac.log(string.format('server returned version - %s (%s)', scriptVersion, sCommit), 0);

		if (scriptVersion == cVersion and sCommit == cCommit) then
			vac.log('script is up to date!', 0, vac.constants.colors.green);
			return;
		end;

		vac.log('version mismatch', 2, vac.constants.colors.orange);
		vac.log('execute "reexec" to get the latest script', 2, vac.constants.colors.orange);
	end, { 'checkver' });

	commands.register('reexecute', function()
		local url = 'https://raw.githubusercontent.com/Iratethisname10/vac/refs/heads/main/main.lua';
		local res, err = vac.debug.executeRaw(url);

		if (err) then
			vac.log(string.format('could not re-execute: ', res), 2, vac.constants.colors.red);
		end;
	end, { 'reexec' });

	commands.register('commands', function()
		ui.cmdsHolder.Visible = not ui.cmdsHolder.Visible;
		ui.cmdsContentHolder.Visible = not ui.cmdsContentHolder.Visible;

		vac.funcs.cmdsInit();
	end, { 'cmds' });

	commands.register('rejoin', function()
		vac.log('rejoining...', 0);

		if (#players:GetPlayers() <= 1) then
			tpService:Teleport(vac.game.id, lplr);
			return;
		end;

		tpService:TeleportToPlaceInstance(vac.game.id, vac.game.job, lplr);
	end, { 'rj' });

	commands.register('serverhop', function()
		if (not vac.temp.serverhoppointer) then
			vac.log('finding server...', 0);
		end;

		local data = vac.decode(game:HttpGet(string.format('https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100%s', vac.game.id, vac.temp.serverhoppointer and '&cursor=' .. vac.temp.serverhoppointer or ''))).data;
		for _, v in next, data do
			if (v.playing >= v.maxPlayers or v.id == vac.game.job or v.ping > 300) then continue; end;

			vac.log('found server!', 0, vac.constants.colors.green);
			tpService:TeleportToPlaceInstance(vac.game.id, v.id, lplr);
			return;
		end;

		if (data.nextPageCursor) then
			vac.temp.serverhoppointer = data.nextPageCursor;
			commands.execute('serverhop');
			return;
		end;

		vac.temp.serverhoppointer = nil;
		vac.log('could not find a server', 1, vac.constants.colors.orange);
	end, { 'sh', 'shop' });

	commands.register('autorejoin', function()
		if (not networkClient:FindFirstChild('ClientReplicator')) then
			commands.execute('rejoin');
		end;

		commands.execute('unautorejoin');

		vac.temp.autorj = vac.connect(networkClient.ChildRemoved, function(inst)
			if (not inst:IsA('ClientReplicator')) then return; end;
			commands.execute('rejoin');
		end);
	end, { 'autorj' });

	commands.register('unautorejoin', function()
		if (vac.temp.autorj) then
			vac.temp.autorj:Disconnect();
			vac.temp.autorj = nil;
		end;
	end, { 'unautorj', 'noautorejoin', 'noautorj' });

	commands.register('walkspeed', function(speed)
		local hum = lplr.Character and lplr.Character:FindFirstChildOfClass('Humanoid');
		if (not hum) then return; end;

		if (not speed) then
			if (vac.temp.walkspeed) then
				hum.WalkSpeed = vac.temp.walkspeed;
			end;

			return;
		end;

		vac.temp.walkspeed = hum.WalkSpeed;
		hum.WalkSpeed = tonumber(speed) or vac.temp.walkspeed;
	end, { 'ws' });

	commands.register('loopwalkspeed', function(speed)
		if (not speed) then return; end;

		vac.temp.loopwalkspeed = true;
		while (vac.temp.loopwalkspeed) do
			local hum = lplr.Character and lplr.Character:FindFirstChildOfClass('Humanoid');
			if (not hum) then task.wait(); continue; end;

			hum.WalkSpeed = tonumber(speed) or 16;

			task.wait();
		end;
	end, { 'loopspeed', 'loopws', 'lws' });

	commands.register('unloopwalkspeed', function()
		vac.temp.loopwalkspeed = false;
	end, { 'unloopspeed', 'unloopws', 'unlws' });

	commands.register('fly', function(speed)
		if (tonumber(speed)) then vac.temp.flyspeed = speed; end;
		vac.funcs.fly(true, true, false);
	end);

	commands.register('velocityfly', function(speed)
		if (tonumber(speed)) then vac.temp.flyspeed = speed; end;
		vac.funcs.fly(true, false, false);
	end, { 'velofly', 'flyvelo' });

	commands.register('vehiclefly', function(speed)
		if (tonumber(speed)) then vac.temp.flyspeed = speed; end;
		vac.funcs.fly(true, false, true);
	end, { 'vfly' });

	commands.register('unfly', function()
		vac.funcs.fly(false);
	end, { 'unvehiclefly', 'unvfly' });

	commands.register('speed', function(speed)
		if (tonumber(speed)) then vac.temp.speedspeed = speed; end;
		vac.funcs.speed(true, true);
	end);

	commands.register('velocityspeed', function(speed)
		if (tonumber(speed)) then vac.temp.speedspeed = speed; end;
		vac.funcs.speed(true, false);
	end, { 'velospeed', 'speedvelo' });

	commands.register('unspeed', function()
		vac.funcs.speed(false);
	end, { 'nospeed' });

	commands.register('teleportwalk', function(speed)
		commands.execute('unteleportwalk');

		vac.temp.tpwalk = vac.connect(runService.Heartbeat, function(dt)
			local root, hum = vac.utilfuncs.getBoth();
			if (not root or not hum) then return; end;

			local dir = hum.MoveDirection;
			if (dir.Magnitude <= 0) then return; end;

			lplr.Character:TranslateBy(dir * (tonumber(speed) and speed or 1.5) * dt * 10);
		end);
	end, { 'tpwalk' });

	commands.register('unteleportwalk', function()
		if (vac.temp.tpwalk) then
			vac.temp.tpwalk:Disconnect();
			vac.temp.tpwalk = nil;
		end;
	end, { 'untpwalk' });

	commands.register('teleportto', function(player)
		player = vac.utilfuncs.getPlayer(player);
		if (not player) then return; end;

		local otherRoot = player.Character and player.Character.PrimaryPart;
		local localRoot = vac.utilfuncs.getRoot();
		if (not localRoot or not otherRoot) then return; end;

		localRoot.CFrame = otherRoot.CFrame;
	end, { 'goto', 'to' });

	commands.register('safeteleportto', function(player)
		player = vac.utilfuncs.getPlayer(player);
		if (not player) then return; end;

		local otherRoot = player.Character and player.Character.PrimaryPart;
		local localRoot = vac.utilfuncs.getRoot();
		if (not localRoot or not otherRoot) then return; end;

		local beenASecond = false;
		task.delay(1, function() beenASecond = true end);

		task.spawn(function()
			while (not beenASecond) do
				lplr:RequestStreamAroundAsync(otherRoot.CFrame.Position, 0.3);
				localRoot.AssemblyLinearVelocity = Vector3.zero;
				localRoot.AssemblyAngularVelocity = Vector3.zero;
				task.wait();
			end;
		end);

		localRoot.CFrame = otherRoot.CFrame;
	end, { 'safegoto', 'safeto' });

	commands.register('inviscam', function()
		lplr.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam;
	end, { 'noclipcam', 'nccam' });

	commands.register('uninviscam', function()
		lplr.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom;
	end, { 'unnoclipcam' });

	commands.register('maxzoom', function(distance)
		if (not distance) then
			if (vac.temp.maxzoom) then
				lplr.CameraMaxZoomDistance = vac.temp.maxzoom;
			end;

			return;
		end;

		vac.temp.maxzoom = lplr.CameraMaxZoomDistance;
		lplr.CameraMaxZoomDistance = tonumber(distance) or vac.temp.maxzoom;
	end);

	commands.register('minzoom', function(distance)
		if (not distance) then
			if (vac.temp.minzoom) then
				lplr.CameraMinZoomDistance = vac.temp.maxzoom;
			end;

			return;
		end;

		vac.temp.minzoom = lplr.CameraMaxZoomDistance;
		lplr.CameraMinZoomDistance = tonumber(distance) or vac.temp.minzoom;
	end);

	commands.register('instantproximityprompts', function()
		if (not fireproximityprompt) then
			vac.log('missing function "fireproximityprompt"', 1, Color3.fromRGB(216, 233, 65));
			return;
		end;

		vac.temp.instapp = vac.connect(ppService.PromptButtonHoldBegan, function(prompt)
			fireproximityprompt(prompt);
		end);
	end, { 'instantpp', 'instapp' });

	commands.register('uninstantproximityprompts', function()
		if (vac.temp.instapp) then
			vac.temp.instapp:Disconnect();
			vac.temp.instapp = nil;
		end;
	end, { 'uninstantpp', 'uninstapp' });

	commands.register('fieldofview', function(fov)
		if (not fov) then
			if (vac.temp.fov) then
				cam.FieldOfView = vac.temp.fov;
			end;

			return;
		end;

		vac.temp.fov = cam.FieldOfView;
		cam.FieldOfView = tonumber(fov) or vac.temp.fov;
	end, { 'fov' });

	commands.register('loopfieldofview', function(fov)
		commands.execute('unloopfieldofview');

		if (not fov) then return; end;

		vac.temp.loopfov = true;
		while (vac.temp.loopfov) do
			cam.FieldOfView = tonumber(fov) or 70;
			task.wait();
		end;
	end, { 'loopfov', 'lfov' });

	commands.register('unloopfieldofview', function()
		vac.temp.loopfov = false;
	end, { 'unloopfov', 'unlfov' });

	commands.register('rolewatch', function(group, role)
		if (not group or not role) then return; end;

		vac.temp.rolewatch.group = group;
		vac.temp.rolewatch.role = role;

		vac.funcs.rwInit();
	end);

	commands.register('stoprolewatch', function()
		vac.temp.rolewatch.group = nil;
		vac.temp.rolewatch.role = nil;

		if (vac.temp.rolewatch.loop) then
			vac.temp.rolewatch.loop:Disconnect();
			vac.temp.rolewatch.loop = nil;
		end;

		vac.log('role watch has stopped', 0);
	end, { 'unrolewatch', 'norolewatch' });

	commands.register('rolewatchleave', function()
		vac.temp.rolewatch.action = 'leave';

		vac.log('role watch action updated to "leave"', 0);
	end);

	commands.register('rolewatchserverhop', function()
		vac.temp.rolewatch.action = 'hop';

		vac.log('role watch action updated to "server hop"', 0);
	end, { 'rolewatchsh', 'rolewatchshop', 'rolewatchhop' });

	commands.register('nofog', function()
		lightService.FogEnd = 10e4;

		for _, v in next, lightService:GetChildren() do
			if (not v:IsA('Atmosphere')) then continue; end;
			v.Density = 0;
		end;
	end);

	commands.register('loopnofog', function()
		vac.funcs.nofog(true, lightService)
	end, { 'lnofog' });

	commands.register('unloopnofog', function()
		vac.funcs.nofog(false);
	end, { 'unlnofog' });

	commands.register('fullbright', function()
		lightService.Brightness = 2;
		lightService.ClockTime = 14;
		lightService.FogEnd = 100000;
		lightService.GlobalShadows = false;
		lightService.OutdoorAmbient = Color3.fromRGB(128, 128, 128);
	end, { 'fb' });

	commands.register('loopfullbright', function()
		vac.funcs.fullbright(true, lightService);
	end, { 'loopfb', 'lfb' });

	commands.register('unloopfullbright', function()
		vac.funcs.fullbright(false);
	end, { 'unloopfb', 'unlfb' });

	commands.register('grabtools', function()
		local hum = vac.utilfuncs.getHum();
		if (not hum) then return; end;

		for _, v in next, workspace:GetChildren() do
			if (not v:IsA('BackpackItem') or not v:FindFirstChild('Handle')) then continue; end;
			hum:EquipTool(v);
		end;
	end);

	commands.register('esp', function()
		vac.funcs.espInit();
	end);

	commands.register('noesp', function()
		vac.funcs.espStop();
	end, { 'unesp' });

	commands.register('dex', function()
		local url = 'https://raw.githubusercontent.com/infyiff/backup/main/dex.lua';
		local res, err = vac.debug.executeRaw(url);

		if (err) then
			vac.log(string.format('could not execute dex: ', res), 2, vac.constants.colors.red);
		end;
	end);

	commands.register('remotespy', function()
		local url = 'https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua';
		local res, err = vac.debug.executeRaw(url);

		if (err) then
			vac.log(string.format('could not execute rspy: ', res), 2, vac.constants.colors.red);
		end;
	end, { 'rspy' });

	commands.register('adonisbypass', function()
		local url = 'https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua';
		local res, err = vac.debug.executeRaw(url);

		if (err) then
			vac.log(string.format('could not execute adonisbypass: ', res), 2, vac.constants.colors.red);
		end;
	end);

	commands.register('f3x', function()
		loadstring(game:GetObjects('rbxassetid://6695644299')[1].Source)();
	end);

	commands.register('freecam', function(speed)
		if (speed) then vac.temp.freecamspeed = tonumber(speed) or 50; end;
		vac.funcs.freecam(true);
	end, { 'fc' });

	commands.register('unfreecam', function()
		vac.funcs.freecam(false);
	end, { 'unfc' });

	commands.register('waypoints', function()
		ui.waypointsHolder.Visible = not ui.waypointsHolder.Visible;
		ui.waypointsContentHolder.Visible = not ui.waypointsContentHolder.Visible;
	end, { 'wp' });

	commands.register('addwaypoint', function(...)
		if (next({...}) < 1) then return; end;
		vac.funcs.addWaypoint({...}, nil, true);
	end, { 'setwaypoint', 'swp' });

	commands.register('antikick', function()
		if (not hookmetamethod) then
			vac.log('missing function "hookmetamethod"', 1, Color3.fromRGB(216, 233, 65));
			return;
		end;

		if (not hookfunction) then
			vac.log('missing function "hookfunction"', 1, Color3.fromRGB(216, 233, 65));
			return;
		end;

		if (not getnamecallmethod) then
			vac.log('missing function "getnamecallmethod"', 1, Color3.fromRGB(216, 233, 65));
			return;
		end;

		hookfunction(lplr.Kick, function() end);

		local oldNamecall; oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
			if (self == lplr and getnamecallmethod():lower() == 'kick') then
				return;
			end;

			return oldNamecall(self, ...);
		end);

		vac.log('anti kick enabled', 0);
	end, { 'anticlientkick' });

	commands.register('spectate', function(player)
		player = vac.utilfuncs.getPlayer(player);
		if (not player) then return; end;

		commands.execute('unspectate');
		commands.execute('unfreecam');

		vac.temp.spectateplayer = vac.connect(player.CharacterAdded, function()
			repeat task.wait(); until player.Character and player.Character.PrimaryPart;
			cam.CameraSubject = player.Character;
		end);

		vac.temp.spectatecamchanged = vac.connect(cam:GetPropertyChangedSignal('CameraSubject'), function()
			cam.CameraSubject = player.Character;
		end);

		cam.CameraSubject = player.Character;
	end, { 'view' });

	commands.register('unspectate', function()
		if (vac.temp.spectateplayer) then
			vac.temp.spectateplayer:Disconnect();
			vac.temp.spectateplayer = nil;
		end;

		if (vac.temp.spectatecamchanged) then
			vac.temp.spectatecamchanged:Disconnect();
			vac.temp.spectatecamchanged = nil;
		end;

		if (lplr.Character) then
			cam.CameraSubject = lplr.Character;
		end;
	end, { 'unview' });

	commands.register('noclip', function()
		commands.execute('unnoclip');

		vac.temp.nocliploop = vac.connect(runService.Heartbeat, function()
			local parts = lplr.Character and lplr.Character:GetDescendants() or {};
			if (next(parts) < 1) then return; end;

			for _, v in next, parts do
				if (not v:IsA('BasePart') or not v.CanCollide) then continue; end;
				v.CanCollide = false;
			end;
		end);
	end, { 'phase' });

	commands.register('unnoclip', function()
		if (vac.temp.nocliploop) then
			vac.temp.nocliploop:Disconnect();
			vac.temp.nocliploop = nil;
		end;
	end, { 'nonoclip', 'unphase'} );

	commands.register('hitbox', function(player, size)
		player = vac.utilfuncs.getPlayer(player, true);
		if (not player) then return; end;

		if (typeof(player) == 'table') then
			for _, v in next, player do
				local root = v.Character and v.Character:FindFirstChild('HumanoidRootPart');
				if (not root) then continue; end;

				root.Size = tonumber(size) and Vector3.one * size or Vector3.new(2, 1, 1);
				root.Transparency = tonumber(size) and 0.6 or 1;
			end;

			return;
		end;

		local root = player.Character and player.Character:FindFirstChild('HumanoidRootPart');
		if (not root) then return; end;

		root.Size = tonumber(size) and Vector3.one * size or Vector3.new(2, 1, 1);
		root.Transparency = 0.6;
	end);

	commands.register('airjump', function()
		commands.execute('uninfjump');

		vac.temp.airjump = vac.connect(inputService.JumpRequest, function()
			if (not vac.temp.airjumpallow) then return; end;
			vac.temp.airjumpallow = false;

			local hum = vac.utilfuncs.getHum();
			if (not hum) then return; end;

			hum:ChangeState(Enum.HumanoidStateType.Jumping);
			task.wait(0.225);

			vac.temp.airjumpallow = true;
		end);
	end, { 'infjump' });

	commands.register('unairjump', function()
		if (vac.temp.airjump) then
			vac.temp.airjump:Disconnect();
			vac.temp.airjump = nil;
		end;

		vac.temp.airjumpallow = true;
	end, { 'uninfjump' });

	commands.register('flyjump', function()
		commands.execute('unflyjump');

		vac.temp.jetpack = vac.connect(runService.Heartbeat, function()
			if (not inputService:IsKeyDown(Enum.KeyCode.Space)) then return; end;

			local root = vac.utilfuncs.getRoot();
			if (not root) then return; end;

			local preVelo = root.AssemblyLinearVelocity;
			root.AssemblyLinearVelocity = Vector3.new(preVelo.X, 50, preVelo.Z);
		end);
	end, { 'jetpack' });

	commands.register('unflyjump', function()
		if (vac.temp.jetpack) then
			vac.temp.jetpack:Disconnect();
			vac.temp.jetpack = nil;
		end;
	end, { 'unjetpack' });

	commands.register('loopbring', function(player, distance)
		commands.execute('unloopbring');

		player = vac.utilfuncs.getPlayer(player, true);
		if (not player) then return; end;

		vac.temp.loopbringing = true;

		if (typeof(player) == 'table') then
			while (vac.temp.loopbringing) do
				local localRoot = vac.utilfuncs.getRoot();
				if (not localRoot) then task.wait(); continue; end;

				player = vac.utilfuncs.getPlayer('all', true);
				if (not player) then task.wait(); continue; end;

				for _, v in next, player do
					local root = v.Character and v.Character:FindFirstChild('HumanoidRootPart');
					if (not root) then continue; end;

					root.CFrame = localRoot.CFrame * CFrame.new(0, 0, tonumber(distance) and -distance or -5);
					root.AssemblyLinearVelocity = Vector3.zero;
					root.AssemblyAngularVelocity = Vector3.zero;
				end;

				task.wait();
			end;

			return;
		end;

		while (vac.temp.loopbringing) do
			local localRoot = vac.utilfuncs.getRoot();
			if (not localRoot) then task.wait(); continue; end;

			local root = player.Character and player.Character:FindFirstChild('HumanoidRootPart');
			if (not root) then continue; end;

			root.CFrame = localRoot.CFrame * CFrame.new(0, 0, tonumber(distance) and -distance or -5);
			root.AssemblyLinearVelocity = Vector3.zero;
			root.AssemblyAngularVelocity = Vector3.zero;

			task.wait();
		end;
	end);

	commands.register('unloopbring', function()
		vac.temp.loopbringing = false;
	end);

	commands.register('clearerror', function()
		uiService:ClearError();
	end, { 'clearerr', 'clrerr' });

	commands.register('copyposition', function()
		local root = vac.utilfuncs.getRoot();
		if (not root) then return; end;

		if (not vac.debug.getFunc(setclipboard, 'setclipboard')) then return; end;

		local postion = root.CFrame.Position;
		setclipboard(string.format('%s, %s, %s', math.round(postion.X), math.round(postion.Y), math.round(postion.Z)));
		vac.log('postion copied to clipboard', 0);
	end, { 'copypos' });

	commands.register('copyvector', function()
		local root = vac.utilfuncs.getRoot();
		if (not root) then return; end;

		if (not vac.debug.getFunc(setclipboard, 'setclipboard')) then return; end;

		local postion = root.CFrame.Position;
		setclipboard(string.format('Vector3.new(%s, %s, %s)', math.round(postion.X), math.round(postion.Y), math.round(postion.Z)));
		vac.log('postion copied to clipboard', 0);
	end, { 'copyvec' });

	commands.register('nobloom', function()
		for _, v in next, lightService:GetChildren() do
			if (not v:IsA('BloomEffect')) then continue; end;
			v.Enabled = false;
		end;
	end);

	commands.register('noblur', function()
		for _, v in next, lightService:GetChildren() do
			if (not v:IsA('BlurEffect')) then continue; end;
			v.Enabled = false;
		end;
	end);

	commands.register('configsave', function(name, module)
		if (not name or not module) then return; end;
		vac.funcs.saveConfig(name, module);
	end);

	commands.register('configload', function(name)
		if (not name) then return; end;
		vac.funcs.loadConfig(name);
	end);

	commands.register('configdelete', function(name)
		if (not name) then return; end;
		vac.funcs.deleteConfig(name);
	end);

	commands.register('configrename', function(name, newname)
		if (not name or not newname) then return; end;
		vac.funcs.renameConfig(name, newname);
	end);
end;

do -- end
	vac.log(string.format('loaded in %.02f seconds!', tick() - scriptLoadAt), 0, vac.constants.colors.green);
	vac.log(string.format('click %s to toggle the ui', vac.scriptsaves.uikeybind), 0);

	local usingOutdated = false;

	task.spawn(function()
		repeat task.wait(); until vac.constants.scriptversion;

		if (scriptVersion ~= vac.constants.scriptversion) then
			vac.log('a new version of the script is available', 2, vac.constants.colors.orange);
			vac.log('execute "reexec" to get the latest script', 2, vac.constants.colors.orange);

			usingOutdated = true
		end;
	end);

	task.spawn(function()
		if (usingOutdated) then return; end;

		repeat task.wait(180);
			if (usingOutdated) then break; end;

			local jsonData = game:HttpGet('https://raw.githubusercontent.com/Iratethisname10/vac/refs/heads/main/version.json');
			local luaData = vac.decode(jsonData);

			if (scriptVersion ~= luaData.ver) then
				vac.log('the script has just updated', 2, vac.constants.colors.orange);
				vac.log('execute "reexec" to get the latest script', 2, vac.constants.colors.orange);

				usingOutdated = true
				break;
			end;

			task.wait(500);
		until not vac;
	end);

	getgenv().vac = vac;
end;