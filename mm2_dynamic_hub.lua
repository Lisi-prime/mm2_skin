--[[
    Dynamic Hub — Murder Mystery 2 (Ultimate Pro Edition)
    - Single State Architecture (`Hub`) with Zero Local Limit
    - Compact Elegant Window (Width: 620, Height: 540, CornerRadius: 14)
    - Dragging window strictly by TopBar header
    - Drop shadow completely hidden on menu close
    - Clean typography: Pure white glowing "DYNAMIC" (no subheaders)
    - Unique Lucide icons for all tabs (Combat, Visuals, Fun, Maps, Animation, Config)
    - ALL GUI toggles OFF by default on startup!
    - Tabs:
        1. Combat
           * Sheriff: Silent Aim, Wallbang (no distance restriction, up to 300+ studs),
             Shoot on Click (always built-in, fires even with empty hands/from Backpack),
             Shoot Murderer Keybind, Flick Shot (modes: "Mouse" & "ShiftLock / Cam"),
             Prediction Slider %, Auto Shot Murderer, Auto Grab Dropped Gun
           * Murderer: Reorganized into 3 distinct sections (NO duplicate buttons):
             - Top: Kill All (Toggle + Kill All Now button + Mode)
             - Middle: Kill Aura (Toggle + Distance Slider + Mode)
             - Bottom: Select Kill (Dropdown player selector + Kill Selected Player button)
        2. Visuals
           * 3D Character Preview: Full HD textures (Humanoid, Shirt, Pants, BodyColors, Accessories),
             Full 3D rotation in all axes (yaw + pitch look from above and below), Idle rotation, Aura effect
           * ESP Roles: Instant robust role reading via CurrentRoundClient.PlayerData & Backpack/Character fallbacks,
             works whether gun is in hand or not!
           * Local Player ESP (Self): See your own role chams and tag
           * World Settings (Мир): Slide-up section at the bottom of Visuals tab:
             FullBright, Remove Fog, Global Shadows, Time of Day slider, Camera FOV slider, Ambient Tint
        3. Fun
           * Movement: Speed Hack (with slider), Infinite Jump, NoClip
           * Reload 3D Rig
        4. Maps (Предпоследний раздел)
           * Vote Duplicator toggle at top (remains ON across rounds, pauses in round, resumes in next lobby!)
           * 3 Map Cards side-by-side horizontally in a row!
           * Clean card design: Map Image, Map Name, Votes count (NO "VotePad" text!)
           * Teleport works strictly during voting phase!
           * Real-time fast vote counter updates (every 0.15s)
        5. Animation
           * Full Catalog Animations & Emotes engine with real AnimationId resolution
           * Stop Emote button, subcategories: Emotes, Walk Styles, Favorites
           * Persistent Action4 playback (never cancels on movement)
        6. Config
           * Menu Keybind listener, Unload Script & clean GUI destruction
--]]

local Hub = {
    Services = {
        Players = game:GetService("Players"),
        TweenService = game:GetService("TweenService"),
        RunService = game:GetService("RunService"),
        UserInputService = game:GetService("UserInputService"),
        HttpService = game:GetService("HttpService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        Workspace = game:GetService("Workspace"),
        Lighting = game:GetService("Lighting"),
        VirtualInputManager = (function()
            local vim = nil
            pcall(function() vim = game:GetService("VirtualInputManager") end)
            return vim
        end)(),
        CoreGui = (function()
            local cg = nil
            pcall(function() cg = game:GetService("CoreGui") end)
            return cg
        end)(),
    },
    Config = {
        ActiveTab = "Combat",
        MenuKey = Enum.KeyCode.RightControl,
        IsListeningMenuKey = false,
        ShootKey = Enum.KeyCode.Unknown,
        IsListeningShootKey = false,
        SelectedTargetPlayer = nil,
        -- ВСЕ функции по умолчанию ВЫКЛЮЧЕНЫ
        Toggles = {
            -- Combat / Sheriff
            SilentAim = false,
            AimWallbang = false,
            AimPrediction = false,
            FlickShot = false,
            AutoShotMurderer = false,
            AutoGrabGun = false,
            -- Combat / Murderer
            KillAll = false,
            KillAura = false,
            AutoKillSheriff = false,
            -- Visuals / ESP
            ESPRoles = false,
            LocalESP = false,
            ESPRoleText = false,
            ESPNickname = false,
            ESPDist = false,
            ESPBoxes = false,
            ESPTracers = false,
            ESPGun = false,
            -- Visuals / Preview
            PreviewRotate = false,
            PreviewAura = false,
            -- Visuals / World
            FullBright = false,
            NoFog = false,
            WorldShadows = true,
            XRay = false,
            -- Fun
            SpeedHack = false,
            InfiniteJump = false,
            NoClip = false,
            AntiAFK = false,
            -- Maps
            VoteDup = false,
            -- Trading & Values
            ShowSkinValues = true,
            ShowInventoryValues = true,
            ShowTradeValues = true,
        },
        Values = {
            PredictionPercent = 40,
            FlickMode = "Mouse",
            KillAllMode = "Classic",
            KillMode = "Classic",
            KillSheriffMode = "Classic",
            KillAuraDist = 18,
            WalkSpeed = 24,
            CameraFOV = 70,
            ClockTime = 14,
            AmbientTint = "Default",
            XRayTransparency = 65,
            ValuesURL = "https://raw.githubusercontent.com/Lisi-prime/mm2_skin/main/values.json",
        }
    },
    Theme = {
        MainBg = Color3.fromRGB(15, 17, 23),
        TopBarBg = Color3.fromRGB(20, 23, 31),
        SidebarBg = Color3.fromRGB(18, 20, 27),
        CardBg = Color3.fromRGB(23, 26, 35),
        CardHover = Color3.fromRGB(30, 35, 47),
        Border = Color3.fromRGB(38, 43, 58),
        Accent = Color3.fromRGB(80, 140, 255),
        AccentGlow = Color3.fromRGB(95, 155, 255),
        TextPrimary = Color3.fromRGB(245, 247, 252),
        TextDim = Color3.fromRGB(165, 172, 192),
        TextMuted = Color3.fromRGB(105, 112, 132),
        SheriffBlue = Color3.fromRGB(0, 150, 255),
        MurderRed = Color3.fromRGB(255, 55, 75),
        InnocentGreen = Color3.fromRGB(45, 220, 95),
        HeroYellow = Color3.fromRGB(255, 230, 0),
    },
    State = {
        Gui = nil,
        MainFrame = nil,
        Shadow = nil,
        TopBar = nil,
        IsOpen = true,
        Tabs = {},
        TabButtons = {},
        Connections = {},
        OriginalSheriff = nil,
    },
    ESP = {
        Highlights = {},
        Drawings = {},
        PlayerRoles = {},
        GunHighlight = nil,
        GunBillboard = nil,
        GunBillboardBot = nil,
        GunDrawing = nil,
    },
    Preview = {
        Viewport = nil,
        World = nil,
        Camera = nil,
        Model = nil,
        Yaw = 0,
        Pitch = 0,
        Dragging = false,
        LastMouse = Vector2.zero,
        AuraEmitter = nil,
    },
    World = {
        Section = nil,
        OrigAmbient = nil,
        OrigClockTime = nil,
        OrigFogEnd = nil,
        OrigShadows = nil,
        OriginalTransparency = {},
        XRayConnection = nil,
    },
    Maps = {
        DupRunning = false,
        SelectedPad = nil,
        Cards = {},
        Cached = {
            VotePad1 = { MapName = "Map 1", Votes = "0", Image = "rbxassetid://10747384394" },
            VotePad2 = { MapName = "Map 2", Votes = "0", Image = "rbxassetid://10747384394" },
            VotePad3 = { MapName = "Map 3", Votes = "0", Image = "rbxassetid://10747384394" },
        },
        StatusLabel = nil,
    },
    ValuesSystem = {
        DatabaseURL = "https://raw.githubusercontent.com/Lisi-prime/mm2_skin/main/values.json",
        LastFetch = 0,
        FetchInterval = 300,
        CachedValues = {},
        FallbackValues = {
            ["Black Luger"] = 1000000,
            ["Chroma Traveler's Gun"] = 140000,
            ["Chroma Evergun"] = 53000,
            ["Chroma Evergreen"] = 39000,
            ["Chroma Bauble"] = 29000,
            ["Chroma Constellation"] = 27000,
            ["Chroma Vampire's Gun"] = 24500,
            ["Chroma Alienbeam"] = 24000,
            ["Gingerscope"] = 15250,
            ["Chroma Raygun"] = 14500,
            ["Chroma Sunrise"] = 10250,
            ["Chroma Snowcannon"] = 7750,
            ["Traveler's Axe"] = 7100,
            ["Travelers Axe"] = 7100,
            ["Chroma Sunset"] = 6500,
            ["Chroma Blizzard"] = 5500,
            ["Traveler's Gun"] = 5200,
            ["Travelers Gun"] = 5200,
            ["Chroma Snowstorm"] = 4250,
            ["Chroma Heart Wand"] = 3500,
            ["Evergun"] = 3450,
            ["Evergreen"] = 2700,
            ["Constellation"] = 2600,
            ["Chroma Snow Dagger"] = 2350,
            ["Chroma Watergun"] = 2300,
            ["Celestial"] = 2100,
            ["Alienbeam"] = 1975,
            ["Raygun"] = 1950,
            ["Vampire's Gun"] = 1900,
            ["Vampires Gun"] = 1900,
            ["Turkey"] = 1850,
            ["Chroma Icecream"] = 1850,
            ["Chroma Ornament"] = 1825,
            ["Darkshot"] = 1800,
            ["Darksword"] = 1775,
            ["Chroma Treat"] = 1775,
            ["Chroma Sweet"] = 1725,
            ["Vampire's Axe"] = 1500,
            ["Vampires Axe"] = 1500,
            ["Sakura"] = 1250,
            ["Chroma Sands"] = 1200,
            ["Chroma Beachy"] = 1150,
            ["Sunrise"] = 875,
            ["Zombie Dog"] = 750,
            ["Bauble"] = 675,
            ["Snowcannon"] = 675,
            ["Soul"] = 670,
            ["Spirit"] = 660,
            ["Elf (2019)"] = 625,
            ["Cane (Knife) [XMAS2018]"] = 525,
            ["Rainbow Gun"] = 405,
            ["Xenoknife"] = 405,
            ["Xenoshot"] = 405,
            ["Flora"] = 400,
            ["Rainbow"] = 400,
            ["Bloom"] = 395,
            ["Heart Wand"] = 340,
            ["Corrupt"] = 340,
            ["HeartWand"] = 340,
            ["Blizzard"] = 280,
            ["Snowstorm"] = 280,
            ["Harvester"] = 250,
            ["Ocean"] = 245,
            ["Flowerwood Gun"] = 240,
            ["Bats (Knife) [HALLOWS2018]"] = 240,
            ["Flowerwood"] = 235,
            ["Blue Pumpkin [HALLOWS2018]"] = 220,
            ["Snow Dagger"] = 175,
            ["Icepiercer"] = 160,
            ["Icecream"] = 155,
            ["Treat"] = 155,
            ["Watergun"] = 155,
            ["Sweet"] = 150,
            ["Dogey"] = 150,
            ["Borealis"] = 145,
            ["Australis"] = 140,
            ["Latte (Gun)"] = 140,
            ["Latte (Knife)"] = 140,
            ["Latte"] = 140,
            ["Dungeon"] = 120,
            ["Zombified (Knife)"] = 120,
            ["Red Pumpkin [HALLOWS2018]"] = 120,
            ["Gifts (Knife)"] = 95,
            ["Gifts"] = 95,
            ["Ghoulish"] = 90,
            ["Beachy"] = 85,
            ["Sands"] = 85,
            ["Gingerbread (Knife) [XMAS2019]"] = 85,
            ["Pine (Knife)"] = 85,
            ["Pine"] = 85,
            ["Pearlshine"] = 80,
            ["Candy"] = 80,
            ["Pearl"] = 75,
            ["Black Cat"] = 75,
            ["Darkknife"] = 70,
            ["Heartblade"] = 65,
            ["Icebreaker"] = 65,
            ["Chroma Darkbringer"] = 65,
            ["Glitch1"] = 65,
            ["Chroma Lightbringer"] = 60,
            ["Sweater (Knife) [XMAS2018]"] = 60,
            ["Green Pumpkin [HALLOWS2018]"] = 60,
            ["Snowflake (Knife) [XMAS2018]"] = 55,
            ["Mr. Reindeer"] = 55,
            ["Piggy"] = 55,
            ["Chroma Luger"] = 50,
            ["Spectral (Knife)"] = 50,
            ["Traveler (Gun)"] = 50,
            ["Silent Night (Knife)"] = 50,
            ["Branches"] = 50,
            ["Pumpkin (2017)"] = 50,
            ["Spectral"] = 50,
            ["Traveler"] = 50,
            ["Silent Night"] = 50,
            ["BattleAxe2"] = 45,
            ["BattleAxe II"] = 45,
            ["Batwing"] = 42,
            ["Chroma Candleflame"] = 40,
            ["Chroma Laser"] = 40,
            ["Elderwood Scythe"] = 38,
            ["Swirly Axe"] = 38,
            ["ElderwoodScythe"] = 38,
            ["Chroma Elderwood Blade"] = 37,
            ["Red Luger"] = 35,
            ["Spectre"] = 35,
            ["Chroma Deathshard"] = 35,
            ["Chroma Swirly Gun"] = 35,
            ["Beach"] = 35,
            ["Cotton Candy"] = 35,
            ["Makeshift (Knife)"] = 35,
            ["Glitch2"] = 35,
            ["Mummified"] = 35,
            ["RedLuger"] = 35,
            ["Candleflame"] = 33,
            ["Darkbringer"] = 33,
            ["Elderwood Blade"] = 33,
            ["Elderwood Revolver"] = 33,
            ["Iceblaster"] = 33,
            ["Makeshift"] = 33,
            ["ElderwoodBlade"] = 33,
            ["ElderwoodRevolver"] = 33,
            ["Lightbringer"] = 32,
            ["Sugar"] = 32,
            ["Chroma Cookiecane"] = 32,
            ["Chroma Fang"] = 32,
            ["Chroma Gemstone"] = 32,
            ["Chroma Shark"] = 32,
            ["Chroma Slasher"] = 32,
            ["Hallowscythe"] = 30,
            ["Zombified"] = 30,
            ["Frosted (Knife)"] = 30,
            ["Snowflakes (Gun)"] = 30,
            ["Wrapped (Gun)"] = 30,
            ["Sparkle9"] = 30,
            ["Frosted"] = 30,
            ["Wrapped"] = 30,
            ["Chroma Heat"] = 28,
            ["Chroma Seer"] = 28,
            ["JD"] = 28,
            ["Chroma Gingerblade"] = 27,
            ["Chroma Tides"] = 27,
            ["Mummy (2017)"] = 25,
            ["Snowman (Gun) [XMAS2018]"] = 25,
            ["Webbed (Gun)"] = 25,
            ["CandyCorn (2017)"] = 25,
            ["Ecto"] = 25,
            ["Elf"] = 25,
            ["Webbed"] = 25,
            ["Green Luger"] = 23,
            ["Chroma Saw"] = 23,
            ["GreenLuger"] = 23,
            ["Amerilaser"] = 22,
            ["Chroma Boneblade"] = 22,
            ["Starry (Gun)"] = 22,
            ["Hallowgun"] = 20,
            ["Nightblade"] = 20,
            ["Shark"] = 20,
            ["Swirl"] = 20,
            ["Elf (2018)"] = 20,
            ["Slimy"] = 20,
            ["Sparkle10"] = 20,
            ["Sparkle8"] = 20,
            ["Red Pumpkin [HALLOWS2020]"] = 20,
            ["Mr. Snowman"] = 20,
            ["Icebeam"] = 18,
            ["Luger"] = 18,
            ["Plasmabeam"] = 18,
            ["Swirly Gun"] = 18,
            ["Logchopper"] = 18,
            ["Sparkle7"] = 18,
            ["Battleaxe II"] = 17,
            ["Blaster"] = 17,
            ["Ginger Luger"] = 17,
            ["Pixel"] = 17,
            ["RIP"] = 17,
            ["Red Pumpkin [HALLOWS2021]"] = 17,
            ["GingerLuger"] = 17,
            ["Gemstone"] = 15,
            ["Iceflake"] = 15,
            ["Old Glory"] = 15,
            ["Plasmablade"] = 15,
            ["Slasher"] = 15,
            ["Vampire's Edge"] = 15,
            ["Bunnies"] = 15,
            ["Skulls"] = 15,
            ["Zombified (Gun)"] = 15,
            ["Coal (Knife) [XMAS2018]"] = 15,
            ["Elf (Knife)"] = 15,
            ["Skully"] = 15,
            ["Cookiecane"] = 13,
            ["Deathshard"] = 13,
            ["Eternalcane"] = 13,
            ["Gingerblade"] = 13,
            ["Jinglegun"] = 13,
            ["Lugercane"] = 13,
            ["Minty"] = 13,
            ["Nebula"] = 13,
            ["Virtual"] = 13,
            ["Icewing"] = 13,
            ["Magma (Gun)"] = 13,
            ["Battleaxe"] = 12,
            ["Gingermint"] = 12,
            ["Swirly Blade"] = 12,
            ["Silent Night (Gun)"] = 12,
            ["Snowflakes"] = 12,
            ["Void"] = 12,
            ["Wrap (Gun)"] = 12,
            ["Wrap (Knife)"] = 12,
            ["Candy Corn (2019)"] = 12,
            ["Prism"] = 12,
            ["Sparkle6"] = 12,
            ["Green Pumpkin [HALLOWS2020]"] = 12,
            ["Wrap"] = 12,
            ["Phantom"] = 10,
            ["Laser"] = 10,
            ["Chill"] = 10,
            ["Clockwork"] = 10,
            ["Fang"] = 10,
            ["Frostsaber"] = 10,
            ["Heat"] = 10,
            ["Spider"] = 10,
            ["Tides"] = 10,
            ["Ghost"] = 10,
            ["Prince"] = 10,
            ["Shadow"] = 10,
            ["Phaser"] = 10,
            ["Cowboy"] = 10,
            ["Golden"] = 10,
            ["Arctic (Gun)"] = 10,
            ["Floral (Knife)"] = 10,
            ["Ghostfire"] = 10,
            ["Gingerbread (Knife) [XMAS2020]"] = 10,
            ["Zombie"] = 10,
            ["Combat II"] = 10,
            ["Sparkle4"] = 10,
            ["Green Pumpkin [HALLOWS2021]"] = 10,
            ["Arctic"] = 10,
            ["Bioblade"] = 8,
            ["Eternal III"] = 8,
            ["Eternal IV"] = 8,
            ["Hallow's Blade"] = 8,
            ["Hallow's Edge"] = 8,
            ["Handsaw"] = 8,
            ["Blood"] = 8,
            ["Steel (Gun)"] = 8,
            ["Skool"] = 8,
            ["Sparkle5"] = 8,
            ["Steel"] = 8,
            ["Boneblade"] = 7,
            ["Eternal"] = 7,
            ["Eternal II"] = 7,
            ["Frostbite"] = 7,
            ["Ghostblade"] = 7,
            ["Ice Dragon"] = 7,
            ["Ice Shard"] = 7,
            ["Prismatic"] = 7,
            ["Pumpking"] = 7,
            ["Saw"] = 7,
            ["Xmas"] = 7,
            ["America"] = 7,
            ["Cavern (Knife)"] = 7,
            ["Broken"] = 7,
            ["Aurora (Knife)"] = 7,
            ["Ghastly (Gun)"] = 7,
            ["Gothic (Gun)"] = 7,
            ["Tailslide"] = 7,
            ["Blue Pumpkin [HALLOWS2020]"] = 7,
            ["<3"] = 7,
            ["Cavern"] = 7,
            ["Ghastly"] = 7,
            ["Gothic"] = 7,
            ["Eggblade"] = 5,
            ["Flames"] = 5,
            ["Winter's Edge"] = 5,
            ["Icedriller"] = 5,
            ["Nightsky"] = 5,
            ["Ghost (Knife)"] = 5,
            ["Toxic (Knife)"] = 5,
            ["Wraith (Knife)"] = 5,
            ["Snowman (Gun) [XMAS2021]"] = 5,
            ["Hazard (Gun)"] = 5,
            ["Zombie (Gun)"] = 5,
            ["Starry"] = 5,
            ["Shadow Pumpkin"] = 5,
            ["Nobledragon"] = 5,
            ["Toxic"] = 5,
            ["Wraith"] = 5,
            ["Hazard"] = 5,
            ["Peppermint"] = 4,
            ["Red Scratch"] = 4,
            ["Alex"] = 4,
            ["Corl"] = 4,
            ["Denis"] = 4,
            ["Euro"] = 4,
            ["Ollie"] = 4,
            ["Sidewinder"] = 4,
            ["Sketchy"] = 4,
            ["Sub"] = 4,
            ["Cookieblade"] = 3,
            ["Blue Seer"] = 3,
            ["Purple Seer"] = 3,
            ["Red Seer"] = 3,
            ["Seer"] = 3,
            ["Splitter"] = 3,
            ["Chroma Fire Bat"] = 3,
            ["Chroma Fire Bear"] = 3,
            ["Chroma Fire Bunny"] = 3,
            ["Chroma Fire Cat"] = 3,
            ["Chroma Fire Dog"] = 3,
            ["Chroma Fire Fox"] = 3,
            ["Chroma Fire Pig"] = 3,
            ["Vampire (Gun)"] = 3,
            ["Spectral (Gun)"] = 3,
            ["Traveler (Knife)"] = 3,
            ["Witched"] = 3,
            ["Blue Elite"] = 3,
            ["Green Elite"] = 3,
            ["Santa's Magic"] = 3,
            ["Santa's Spirit"] = 3,
            ["Icicles (Gun)"] = 3,
            ["Jack"] = 3,
            ["Snakebite (Knife)"] = 3,
            ["Magma"] = 3,
            ["Gingerbread (Gun) [XMAS2020]"] = 3,
            ["Lantern"] = 3,
            ["Zombie (2023)"] = 3,
            ["Potion (2017)"] = 3,
            ["Apocalypse (Gun)"] = 3,
            ["Bats (2020)"] = 3,
            ["Infected (Gun)"] = 3,
            ["Ghosty"] = 3,
            ["Sparkle1"] = 3,
            ["Sparkle2"] = 3,
            ["Sparkle3"] = 3,
            ["Eyeball"] = 3,
            ["Reindeer"] = 3,
            ["Snowbear"] = 3,
            ["Chilly"] = 3,
            ["Fairy"] = 3,
            ["Green Pumpkin [HALLOWS2019]"] = 3,
            ["Jetstream"] = 3,
            ["Mechbug"] = 3,
            ["Overseer Eye"] = 3,
            ["Pengy"] = 3,
            ["Purple Pumpkin [HALLOWS2018]"] = 3,
            ["Red Pumpkin [HALLOWS2019]"] = 3,
            ["Rudolph"] = 3,
            ["Seahorsey"] = 3,
            ["Tankie"] = 3,
            ["UFO"] = 3,
            ["Vampire Bat"] = 3,
            ["Icicles"] = 3,
            ["Snakebite"] = 3,
            ["Apocalypse"] = 3,
            ["Orange Seer"] = 2,
            ["Yellow Seer"] = 2,
            ["Energized (Gun)"] = 2,
            ["Frostfade (Knife)"] = 2,
            ["Blue Scratch"] = 2,
            ["Ghost (Gun)"] = 2,
            ["Candy Swirl (Gun)"] = 2,
            ["Sun"] = 2,
            ["Bats"] = 2,
            ["Green Marble"] = 2,
            ["Orange Marble"] = 2,
            ["Toxic (Gun)"] = 2,
            ["Tree (2021)"] = 2,
            ["Meltdown"] = 2,
            ["Moonlight"] = 2,
            ["Stars (Knife)"] = 2,
            ["Pumpkin Pie"] = 2,
            ["Mummy (Gun) [HALLOWS2018]"] = 2,
            ["Potion (Gun)"] = 2,
            ["Potion (Knife)"] = 2,
            ["Asteroid"] = 2,
            ["Grind"] = 2,
            ["Indy"] = 2,
            ["Energized"] = 2,
            ["Frostfade"] = 2,
            ["Candy Swirl"] = 2,
            ["Stars"] = 2,
            ["Potion"] = 2,
            ["Aurora (Gun)"] = 1,
            ["Vampire (Knife)"] = 1,
            ["Chromatic (Knife)"] = 1,
            ["Icecracker"] = 1,
            ["Red Fire"] = 1,
            ["Cavern (Gun)"] = 1,
            ["Darkgun"] = 1,
            ["Gingerbread"] = 1,
            ["Candy Swirl (Knife)"] = 1,
            ["Snakebite (Gun)"] = 1,
            ["Cookie (Knife)"] = 1,
            ["Gingerbread (Gun) [XMAS2019]"] = 1,
            ["Holly (Gun)"] = 1,
            ["Mummy (Knife) [HALLOWS2018]"] = 1,
            ["Zombie (Knife)"] = 1,
            ["Moons"] = 1,
            ["Vampire"] = 1,
            ["Wolf"] = 1,
            ["Slashed"] = 1,
            ["Bats (Gun) [HALLOWS2018]"] = 1,
            ["Grave (Gun)"] = 1,
            ["Grave (Knife)"] = 1,
            ["Haunted (Gun)"] = 1,
            ["Haunted (Knife)"] = 1,
            ["Slime (Gun)"] = 1,
            ["Slime (Knife)"] = 1,
            ["Lil' Alien"] = 1,
            ["Badger"] = 1,
            ["Blue Pumpkin [HALLOWS2019]"] = 1,
            ["Aurora"] = 1,
            ["Chromatic"] = 1,
            ["Cookie"] = 1,
            ["Holly"] = 1,
            ["Grave"] = 1,
            ["Slime"] = 1,
            ["2015"] = "x4 T1 Legendaries",
            ["8Bit"] = "x1 T1 Common",
            ["Abduction"] = "x2 T1 Uncommons",
            ["Abstract"] = "x4 T1 Uncommons",
            ["Ace"] = "x4 T1 Uncommons",
            ["Adurite"] = "x4 T1 Commons",
            ["Adurite (Gun)"] = "x4 T1 Commons",
            ["Adurite (Knife)"] = "x4 T1 Commons",
            ["Aliens"] = "x1 T1 Uncommon",
            ["Apocalypse (Knife)"] = "x4 T1 Legendaries",
            ["Aqua"] = "x1 T1 Common",
            ["Aquarium"] = "x3 T1 Legendaries",
            ["Aquarium (Gun)"] = "x3 T1 Legendaries",
            ["Aquarium (Knife)"] = "x2 T1 Legendaries",
            ["Arctic (Knife)"] = "x4 T1 Legendaries",
            ["Bacon"] = "x4 T1 Uncommons",
            ["Balloons"] = "x2 T1 Commons",
            ["Bat"] = "x2 T1 Uncommons",
            ["Bats (Gun) [HALLOWS2024]"] = "x3 T1 Commons",
            ["Bats (Knife) [HALLOWS2024]"] = "x2 T1 Commons",
            ["Bear"] = "x3 T1 Commons",
            ["Bells"] = "x2 T1 Commons",
            ["Big Kill"] = "x1 T1 Common",
            ["Bio"] = "x3 T1 Rares",
            ["Biogun"] = "x4 T1 Commons",
            ["Bit"] = "x1 T1 Common",
            ["Black"] = "x4 T1 Uncommons",
            ["Bleached"] = "x1 T1 Common",
            ["Blossom"] = "x4 T1 Legendaries",
            ["Blue"] = "x4 T1 Commons",
            ["Bluesteel"] = "x4 T1 Commons",
            ["Bluesteel (Gun)"] = "x4 T1 Commons",
            ["Bluesteel (Knife)"] = "x4 T1 Commons",
            ["Bones"] = "x4 T1 Legendaries",
            ["Bones (Knife)"] = "x2 T1 Uncommons",
            ["Borders"] = "x1 T1 Common",
            ["Brains"] = "x4 T1 Legendaries",
            ["Brains (2022)"] = "x3 T1 Uncommons",
            ["Brown"] = "x1 T1 Common",
            ["Brush"] = "x4 T1 Commons",
            ["Bubbles"] = "x2 T1 Legendaries",
            ["Bunny"] = "x4 T1 Legendaries",
            ["Butterflies"] = "x1 T1 Legendary",
            ["Camo"] = "x4 T1 Commons",
            ["Camo (Gun)"] = "x4 T1 Commons",
            ["Camo (Knife)"] = "x4 T1 Commons",
            ["Candied"] = "x2 T1 Uncommons",
            ["Candied (Gun)"] = "x3 T1 Commons",
            ["Candied (Knife)"] = "x2 T1 Uncommons",
            ["Candle"] = "x3 T1 Commons",
            ["Candleflame (Gun)"] = "x1 T1 Legendary",
            ["Candles"] = "x3 T1 Commons",
            ["Candy Corn (Gun) [HALLOWS2020]"] = "x2 T1 Commons",
            ["Candy Corn (Gun) [HALLOWS2022]"] = "x3 T1 Commons",
            ["Candy Corn (Gun) [HALLOWS2024]"] = "x2 T1 Commons",
            ["Candy Corn (Gun) [HALLOWS2025]"] = "x3 T1 Commons",
            ["Candy Corn (Knife) [HALLOWS2020]"] = "x3 T1 Commons",
            ["Candy Corn (Knife) [HALLOWS2022]"] = "x2 T1 Commons",
            ["Candy Corn (Knife) [HALLOWS2024]"] = "x3 T1 Commons",
            ["Candy Corn (Knife) [HALLOWS2025]"] = "x2 T1 Commons",
            ["Cane"] = "x2 T1 Rares",
            ["Cane (Gun)"] = "x2 T1 Rares",
            ["Cane (Gun) [XMAS2015]"] = "x4 T1 Legendaries",
            ["Cane (Gun) [XMAS2018]"] = "x3 T1 Legendaries",
            ["Cane (Knife)"] = "x3 T1 Commons",
            ["Cane (Knife) [XMAS2015]"] = "x4 T1 Legendaries",
            ["Canes"] = "x1 T1 Rare",
            ["Canes (Gun)"] = "x1 T1 Rare",
            ["Canes (Knife)"] = "x3 T1 Uncommons",
            ["Cardboard"] = "x1 T1 Common",
            ["Carrot"] = "x4 T1 Legendaries",
            ["Carrot (Gun)"] = "x3 T1 Uncommons",
            ["Carrot (Knife)"] = "x3 T1 Uncommons",
            ["Carrot Bunny"] = "x3 T1 Legendaries",
            ["Carrots"] = "x3 T1 Commons",
            ["Carved"] = "x3 T1 Commons",
            ["Carved (Gun)"] = "x3 T1 Commons",
            ["Carved (Knife)"] = "x2 T1 Commons",
            ["Cat"] = "x1 T1 Common",
            ["Cats"] = "x3 T1 Commons",
            ["Caution"] = "x4 T1 Commons",
            ["Checkers"] = "x3 T1 Uncommons",
            ["Cheddar"] = "x4 T1 Commons",
            ["Cheesy"] = "x4 T1 Commons",
            ["Cherries"] = "x2 T1 Commons",
            ["Cherry"] = "x1 T1 Common",
            ["Chick"] = "x3 T1 Commons",
            ["Choco"] = "x4 T1 Legendaries",
            ["Chromatic (Gun)"] = "x4 T1 Legendaries",
            ["Circuit"] = "x4 T1 Commons",
            ["Clan"] = "x1 T1 Common",
            ["Clown"] = "x1 T1 Common",
            ["Clown (Gun)"] = "x1 T1 Common",
            ["Clown (Knife)"] = "x1 T1 Common",
            ["Clownfish"] = "x3 T1 Commons",
            ["Clownfish (Gun)"] = "x2 T1 Commons",
            ["Clownfish (Knife)"] = "x3 T1 Commons",
            ["Coal"] = "x3 T1 Commons",
            ["Coal (Gun) [XMAS2018]"] = "x1 T1 Uncommon",
            ["Coal (Gun) [XMAS2021]"] = "x3 T1 Commons",
            ["Coal (Gun) [XMAS2022]"] = "x1 T1 Uncommon",
            ["Coal (Knife) [XMAS2021]"] = "x3 T1 Uncommons",
            ["Coal (Knife) [XMAS2022]"] = "x2 T1 Commons",
            ["Coconut"] = "x2 T1 Commons",
            ["Cold"] = "x1 T1 Common",
            ["Combat"] = "x1 T1 Common",
            ["Cookie (Gun)"] = "x1 T1 Rare",
            ["Copper"] = "x1 T1 Common",
            ["Cracks"] = "x2 T1 Uncommons",
            ["Cracks (Gun)"] = "x2 T1 Uncommons",
            ["Cracks (Knife)"] = "x3 T1 Commons",
            ["Cupid"] = "x2 T1 Legendaries",
            ["Curse"] = "x3 T1 Rares",
            ["Cursed"] = "x4 T1 Legendaries",
            ["Cursed (Gun)"] = "x3 T1 Legendaries",
            ["Cursed (Knife)"] = "x4 T1 Legendaries",
            ["Damp"] = "x1 T1 Legendary",
            ["Darkness"] = "x2 T1 Uncommons",
            ["Darkness (Gun)"] = "x3 T1 Commons",
            ["Darkness (Knife)"] = "x2 T1 Uncommons",
            ["Deathspeaker"] = "x3 T1 Legendaries",
            ["Decorated"] = "x3 T1 Uncommons",
            ["Deep Sea"] = "x3 T1 Uncommons",
            ["Dog"] = "x1 T1 Common",
            ["Doge"] = "x4 T1 Commons",
            ["Dolphins"] = "x2 T1 Commons",
            ["Donut"] = "x2 T1 Uncommons",
            ["Duckies"] = "x2 T1 Commons",
            ["Eclipse"] = "x3 T1 Uncommons",
            ["Eco"] = "x1 T1 Common",
            ["Egg"] = "x4 T1 Legendaries",
            ["Electro"] = "x3 T1 Legendaries",
            ["Elf (2017)"] = "x3 T1 Commons",
            ["Elf (2023)"] = "x2 T1 Commons",
            ["Elf (Gun)"] = "x4 T1 Legendaries",
            ["Elite"] = "x3 T1 Rares",
            ["Elitey"] = "x1 T1 Uncommon",
            ["Emerald"] = "x4 T1 Legendaries",
            ["Energized (Knife)"] = "x4 T1 Legendaries",
            ["Engraved"] = "x1 T1 Common",
            ["Etched"] = "x1 T1 Rare",
            ["Eyes"] = "x3 T1 Uncommons",
            ["Fade"] = "x4 T1 Rares",
            ["Fall"] = "x2 T1 Commons",
            ["Fall Camo"] = "x3 T1 Uncommons",
            ["Fallout"] = "x1 T1 Common",
            ["Fire Bat"] = "x2 T1 Legendaries",
            ["Fire Bear"] = "x2 T1 Legendaries",
            ["Fire Bunny"] = "x2 T1 Legendaries",
            ["Fire Cat"] = "x2 T1 Legendaries",
            ["Fire Dog"] = "x2 T1 Legendaries",
            ["Fire Fox"] = "x2 T1 Legendaries",
            ["Fire Pig"] = "x2 T1 Legendaries",
            ["Fireplace"] = "x1 T1 Rare",
            ["Floatie"] = "x3 T1 Uncommons",
            ["Floral"] = "x3 T1 Uncommons",
            ["Floral (Gun)"] = "x2 T1 Rares",
            ["Forest"] = "x1 T1 Rare",
            ["Fox"] = "x2 T1 Commons",
            ["Fragile"] = "x2 T1 Uncommons",
            ["Fragile (Gun)"] = "x2 T1 Uncommons",
            ["Fragile (Knife)"] = "x2 T1 Uncommons",
            ["Frostbird"] = "x3 T1 Legendaries",
            ["Frosted (Gun)"] = "x4 T1 Legendaries",
            ["Frostfade (Gun)"] = "x3 T1 Legendaries",
            ["Frostflame"] = "x1 T1 Legendary",
            ["Frostflame (Gun)"] = "x3 T1 Rares",
            ["Frostflame (Knife)"] = "x1 T1 Legendary",
            ["Frosty"] = "x1 T1 Rare",
            ["Frozen"] = "x2 T1 Commons",
            ["Frozen (Gun)"] = "x2 T1 Commons",
            ["Frozen (Knife)"] = "x3 T1 Commons",
            ["Fusion"] = "x4 T1 Rares",
            ["Future"] = "x3 T1 Uncommons",
            ["Galactic"] = "x4 T1 Uncommons",
            ["Galaxy"] = "x4 T1 Uncommons",
            ["Ghastly (Knife)"] = "x2 T1 Legendaries",
            ["Ghostly"] = "x2 T1 Uncommons",
            ["Ghosts"] = "x3 T1 Rares",
            ["Ghosts (2023)"] = "x1 T1 Uncommon",
            ["Ghosts (2024)"] = "x2 T1 Commons",
            ["Ghosts (Gun)"] = "x3 T1 Rares",
            ["Ghosts (Knife)"] = "x2 T1 Uncommons",
            ["Gift Bag"] = "x3 T1 Legendaries",
            ["Gift Bag (Gun)"] = "x2 T1 Uncommons",
            ["Gift Bag (Knife)"] = "x3 T1 Legendaries",
            ["Gifted"] = "x4 T1 Legendaries",
            ["Gifts (2024)"] = "x3 T1 Commons",
            ["Gifts (Gun)"] = "x2 T1 Legendaries",
            ["Giftwrap"] = "x2 T1 Commons",
            ["Ginger"] = "x4 T1 Legendaries",
            ["Ginger (Gun)"] = "x4 T1 Legendaries",
            ["Ginger (Knife)"] = "x4 T1 Legendaries",
            ["Gingerbread (Gun)"] = "x4 T1 Legendaries",
            ["Gingerbread (Gun) [XMAS2021]"] = "x3 T1 Uncommons",
            ["Gingerbread (Gun) [XMAS2025]"] = "x3 T1 Uncommons",
            ["Gingerbread (Knife)"] = "x1 T1 Legendary",
            ["Gingerbread (Knife) [XMAS2025]"] = "x2 T1 Uncommons",
            ["Gingercookie"] = "x3 T1 Rares",
            ["Gingercookie (Gun)"] = "x2 T1 Rares",
            ["Gingercookie (Knife)"] = "x3 T1 Rares",
            ["Gingerheart"] = "x2 T1 Rares",
            ["Glowy"] = "x3 T1 Uncommons",
            ["Goo"] = "x4 T1 Legendaries",
            ["Gothic (Knife)"] = "x4 T1 Legendaries",
            ["Graffiti"] = "x3 T1 Commons",
            ["Green"] = "x1 T1 Common",
            ["Green Fire"] = "x4 T1 Legendaries",
            ["Hacker"] = "x4 T1 Uncommons",
            ["Hardened"] = "x1 T1 Common",
            ["Haunted"] = "x2 T1 Commons",
            ["Haunted (2025)"] = "x3 T1 Commons",
            ["Hazard (Knife)"] = "x3 T1 Rares",
            ["Hazmat"] = "x4 T1 Commons",
            ["Heart"] = "x1 T1 Legendary",
            ["Heartbreak"] = "x2 T1 Rares",
            ["Hearts"] = "x4 T1 Legendaries",
            ["Hearts (2026)"] = "x2 T1 Commons",
            ["High Tech"] = "x3 T1 Commons",
            ["Hive"] = "x4 T1 Commons",
            ["HL2"] = "x1 T1 Common",
            ["Holly (Knife)"] = "x1 T1 Rare",
            ["Hologram"] = "x3 T1 Rares",
            ["Hologram (Gun)"] = "x3 T1 Rares",
            ["Hologram (Knife)"] = "x2 T1 Rares",
            ["Hot Chocolate"] = "x3 T1 Commons",
            ["Hunter"] = "x3 T1 Legendaries",
            ["Ice"] = "x1 T1 Common",
            ["Ice Camo"] = "x2 T1 Legendaries",
            ["Ice Phoenix"] = "x3 T1 Legendaries",
            ["Icey"] = "x3 T1 Legendaries",
            ["Icicles (Knife)"] = "x3 T1 Legendaries",
            ["Igloo"] = "x3 T1 Commons",
            ["Igloo (Gun)"] = "x3 T1 Commons",
            ["Igloo (Knife)"] = "x2 T1 Commons",
            ["Imbued"] = "x4 T1 Uncommons",
            ["Infected"] = "x3 T1 Legendaries",
            ["Infected (Knife)"] = "x4 T1 Legendaries",
            ["Infiltrator"] = "x1 T1 Common",
            ["iRevolver"] = "x4 T1 Uncommons",
            ["Iron"] = "x1 T1 Common",
            ["Jellyfish"] = "x2 T1 Uncommons",
            ["Jigsaw"] = "x4 T1 Commons",
            ["Juice"] = "x1 T1 Common",
            ["Korblox"] = "x4 T1 Uncommons",
            ["Kraken"] = "x2 T1 Rares",
            ["Krypto"] = "x4 T1 Uncommons",
            ["Lava"] = "x3 T1 Uncommons",
            ["Lava (Gun)"] = "x2 T1 Uncommons",
            ["Lava (Knife)"] = "x3 T1 Uncommons",
            ["Leaf"] = "x1 T1 Common",
            ["Leaves"] = "x2 T1 Uncommons",
            ["Leaves [HALLOWS2023]"] = "x2 T1 Commons",
            ["Leaves [SUMMER2025]"] = "x2 T1 Commons",
            ["Lights"] = "x2 T1 Commons",
            ["Lights (Gun)"] = "x2 T1 Commons",
            ["Lights (Knife)"] = "x2 T1 Commons",
            ["Linked"] = "x1 T1 Common",
            ["Log"] = "x1 T1 Common",
            ["Logcutter"] = "x2 T1 Legendaries",
            ["Love"] = "x2 T1 Rares",
            ["Love (2023)"] = "x3 T1 Uncommons",
            ["Love (Gun)"] = "x2 T1 Rares",
            ["Love (Knife)"] = "x1 T1 Common",
            ["Lovely"] = "x1 T1 Common",
            ["Lucky"] = "x4 T1 Commons",
            ["Magma (Knife)"] = "x3 T1 Legendaries",
            ["Marble"] = "x1 T1 Rare",
            ["Marina"] = "x4 T1 Commons",
            ["Meadow"] = "x3 T1 Uncommons",
            ["Melon"] = "x4 T1 Commons",
            ["Melon [SUMMER2023]"] = "x1 T1 Rare",
            ["Midnight"] = "x3 T1 Legendaries",
            ["Missing"] = "x4 T1 Commons",
            ["Mistletoe"] = "x3 T1 Rares",
            ["Mistletoe (Gun)"] = "x3 T1 Rares",
            ["Mistletoe (Knife)"] = "x3 T1 Uncommons",
            ["Molten"] = "x2 T1 Legendaries",
            ["Molten (Gun)"] = "x2 T1 Legendaries",
            ["Molten (Knife)"] = "x2 T1 Legendaries",
            ["Monster"] = "x3 T1 Uncommons",
            ["Moon"] = "x3 T1 Uncommons",
            ["Moons (2024)"] = "x3 T1 Uncommons",
            ["Mummy"] = "x4 T1 Legendaries",
            ["Mummy (Gun) [HALLOWS2020]"] = "x3 T1 Uncommons",
            ["Mummy (Knife) [HALLOWS2020]"] = "x1 T1 Rare",
            ["Musical"] = "x4 T1 Uncommons",
            ["Neon"] = "x3 T1 Legendaries",
            ["Neon [SUMMER2025]"] = "x2 T1 Rares",
            ["Neon [XMAS2023]"] = "x1 T1 Legendary",
            ["Neopolitan"] = "x3 T1 Uncommons",
            ["Nether"] = "x1 T1 Legendary",
            ["News"] = "x1 T1 Common",
            ["Night"] = "x3 T1 Uncommons",
            ["Nightfire"] = "x4 T1 Uncommons",
            ["Nightstar"] = "x4 T1 Legendaries",
            ["Nova"] = "x4 T1 Uncommons",
            ["Nuke"] = "x3 T1 Legendaries",
            ["Nutcracker"] = "x4 T1 Legendaries",
            ["Oily"] = "x1 T1 Common",
            ["Orange"] = "x1 T1 Common",
            ["Ornament"] = "x4 T1 Legendaries",
            ["Ornament1"] = "x4 T1 Legendaries",
            ["Ornament2"] = "x4 T1 Legendaries",
            ["Ornament2 (Gun)"] = "x4 T1 Legendaries",
            ["Ornament2 (Knife)"] = "x4 T1 Legendaries",
            ["Ornaments"] = "x2 T1 Uncommons",
            ["Ornaments (Gun)"] = "x1 T1 Rare",
            ["Ornaments (Knife)"] = "x2 T1 Uncommons",
            ["Overseer"] = "x4 T1 Legendaries",
            ["Overseer (Gun)"] = "x4 T1 Legendaries",
            ["Overseer (Knife)"] = "x4 T1 Rares",
            ["Painted"] = "x1 T1 Legendary",
            ["Painted (Gun)"] = "x3 T1 Uncommons",
            ["Painted (Knife)"] = "x1 T1 Legendary",
            ["Palms"] = "x3 T1 Legendaries",
            ["Palms (Gun)"] = "x3 T1 Legendaries",
            ["Palms (Knife)"] = "x2 T1 Legendaries",
            ["Paper"] = "x4 T1 Commons",
            ["Passion"] = "x4 T1 Legendaries",
            ["Patrick"] = "x4 T1 Legendaries",
            ["Paws"] = "x2 T1 Uncommons",
            ["Pea"] = "x1 T1 Common",
            ["Penguin"] = "x1 T1 Uncommon",
            ["Peppermint (Gun)"] = "x2 T1 Commons",
            ["Peppermint (Knife)"] = "x2 T1 Commons",
            ["Phoenix"] = "x3 T1 Legendaries",
            ["Pier"] = "x3 T1 Rares",
            ["Pig"] = "x2 T1 Commons",
            ["Pine (Gun)"] = "x3 T1 Rares",
            ["Pink"] = "x4 T1 Commons",
            ["Pirate"] = "x4 T1 Commons",
            ["Plaid"] = "x2 T1 Commons",
            ["Plasmite"] = "x4 T1 Rares",
            ["Polar Bear"] = "x3 T1 Uncommons",
            ["Pool"] = "x3 T1 Uncommons",
            ["Pool Noodle"] = "x1 T1 Legendary",
            ["Pop Art"] = "x3 T1 Rares",
            ["Pop Art (Gun)"] = "x2 T1 Rares",
            ["Pop Art (Knife)"] = "x3 T1 Rares",
            ["Popsicle"] = "x3 T1 Uncommons",
            ["Popsicle (Gun)"] = "x2 T1 Uncommons",
            ["Portal"] = "x2 T1 Rares",
            ["Portal (Gun)"] = "x2 T1 Uncommons",
            ["Portal (Knife)"] = "x2 T1 Rares",
            ["Predator"] = "x4 T1 Legendaries",
            ["Predator (Gun)"] = "x4 T1 Rares",
            ["Predator (Knife)"] = "x4 T1 Legendaries",
            ["Present"] = "x3 T1 Commons",
            ["Present (2023)"] = "x3 T1 Commons",
            ["Pumpkin"] = "x2 T1 Uncommons",
            ["Pumpkin (2018)"] = "x2 T1 Legendaries",
            ["Pumpkin (2019)"] = "x3 T1 Uncommons",
            ["Pumpkin (2020)"] = "x2 T1 Commons",
            ["Pumpkin (2021)"] = "x1 T1 Common",
            ["Pumpkin (2023)"] = "x1 T1 Uncommon",
            ["Pumpkin (2025)"] = "x3 T1 Uncommons",
            ["Pumpkin (Knife)"] = "x2 T1 Uncommons",
            ["Pumpkin Patch"] = "x2 T1 Uncommons",
            ["Purple"] = "x4 T1 Uncommons",
            ["Rainbow (Gun)"] = "x4 T1 Uncommons",
            ["Rainbow (Knife)"] = "x4 T1 Uncommons",
            ["RB Knife"] = "x3 T1 Rares",
            ["Red"] = "x4 T1 Commons",
            ["Reindeer [XMAS2025]"] = "x1 T1 Uncommon",
            ["Reptile"] = "x4 T1 Legendaries",
            ["Retro"] = "x2 T1 Uncommons",
            ["Ribbon"] = "x1 T1 Uncommon",
            ["Ribbons"] = "x2 T1 Legendaries",
            ["Ripper"] = "x4 T1 Legendaries",
            ["Ripper (Gun)"] = "x2 T1 Legendaries",
            ["Ripper (Knife)"] = "x4 T1 Legendaries",
            ["Ritual"] = "x2 T1 Rares",
            ["Robot"] = "x2 T1 Rares",
            ["Rose"] = "x2 T1 Rares",
            ["Roses"] = "x4 T1 Legendaries",
            ["Rune"] = "x4 T1 Rares",
            ["Rupture"] = "x4 T1 Legendaries",
            ["Sammy"] = "x3 T1 Legendaries",
            ["Sand"] = "x2 T1 Commons",
            ["Sandy"] = "x1 T1 Common",
            ["Sandy (Gun)"] = "x2 T1 Commons",
            ["Santa"] = "x3 T1 Commons",
            ["Santa (2018)"] = "x3 T1 Commons",
            ["Santa (2023)"] = "x1 T1 Uncommon",
            ["Santa (Gun)"] = "x4 T1 Legendaries",
            ["Santa (Knife)"] = "x4 T1 Legendaries",
            ["Santa Dog"] = "x1 T1 Uncommon",
            ["Scarecrow"] = "x1 T1 Legendary",
            ["Scarf"] = "x3 T1 Uncommons",
            ["Shaded"] = "x1 T1 Common",
            ["Sharky"] = "x2 T1 Rares",
            ["Shiny"] = "x4 T1 Rares",
            ["Skelly"] = "x3 T1 Legendaries",
            ["Sketch"] = "x4 T1 Commons",
            ["Skyline"] = "x2 T1 Commons",
            ["Slate"] = "x1 T1 Common",
            ["Sleigh"] = "x2 T1 Rares",
            ["Snowball"] = "x2 T1 Commons",
            ["Snowball (Gun)"] = "x2 T1 Commons",
            ["Snowball (Knife)"] = "x2 T1 Commons",
            ["Snowfall"] = "x2 T1 Commons",
            ["Snowflake"] = "x2 T1 Rares",
            ["Snowflake (Gun) [XMAS2018]"] = "x1 T1 Rare",
            ["Snowflake (Gun) [XMAS2022]"] = "x3 T1 Uncommons",
            ["Snowflake (Knife) [XMAS2022]"] = "x1 T1 Legendary",
            ["Snowflakes (Knife)"] = "x2 T1 Legendaries",
            ["Snowglobe"] = "x2 T1 Rares",
            ["Snowman (2023)"] = "x3 T1 Uncommons",
            ["Snowman (2024)"] = "x2 T1 Uncommons",
            ["Snowman (Gun) [XMAS2015]"] = "x4 T1 Legendaries",
            ["Snowman (Gun) [XMAS2022]"] = "x2 T1 Uncommons",
            ["Snowman (Knife) [XMAS2015]"] = "x4 T1 Legendaries",
            ["Snowman (Knife) [XMAS2018]"] = "x3 T1 Commons",
            ["Snowman (Knife) [XMAS2021]"] = "x1 T1 Rare",
            ["Snowman (Knife) [XMAS2022]"] = "x2 T1 Commons",
            ["Snowy"] = "x4 T1 Legendaries",
            ["Soda"] = "x4 T1 Commons",
            ["Soda (Gun)"] = "x3 T1 Uncommons",
            ["Soda (Knife)"] = "x2 T1 Uncommons",
            ["Space"] = "x4 T1 Uncommons",
            ["Sparkle"] = "x3 T1 Legendaries",
            ["Spearmint"] = "x3 T1 Rares",
            ["Spearmint (Gun)"] = "x3 T1 Rares",
            ["Spearmint (Knife)"] = "x2 T1 Rares",
            ["Spectrum"] = "x4 T1 Uncommons",
            ["Spider (2023)"] = "x2 T1 Commons",
            ["Spitfire"] = "x1 T1 Legendary",
            ["Splash"] = "x4 T1 Rares",
            ["Splash (Gun)"] = "x3 T1 Rares",
            ["Splash (Knife)"] = "x4 T1 Rares",
            ["Splat"] = "x1 T1 Common",
            ["Splatter"] = "x1 T1 Common",
            ["Spring"] = "x2 T1 Rares",
            ["Squire"] = "x4 T1 Uncommons",
            ["Stainless"] = "x1 T1 Common",
            ["Stalker"] = "x4 T1 Commons",
            ["Star"] = "x1 T1 Common",
            ["Starfish"] = "x2 T1 Commons",
            ["Starfish (Gun)"] = "x2 T1 Commons",
            ["Starfish (Knife)"] = "x2 T1 Commons",
            ["Starry (Knife)"] = "x4 T1 Legendaries",
            ["Stars (Gun)"] = "x3 T1 Uncommons",
            ["Static"] = "x1 T1 Common",
            ["Steambird"] = "x3 T1 Legendaries",
            ["Steel (Knife)"] = "x2 T1 Legendaries",
            ["Stickers (Gun) [HALLOWS2021]"] = "x2 T1 Commons",
            ["Stickers (Gun) [HALLOWS2024]"] = "x2 T1 Commons",
            ["Stickers (Gun) [SUMMER2023]"] = "x3 T1 Commons",
            ["Stickers (Gun) [SUMMER2025]"] = "x2 T1 Commons",
            ["Stickers (Gun) [XMAS2021]"] = "x2 T1 Commons",
            ["Stickers (Gun) [XMAS2022]"] = "x2 T1 Commons",
            ["Stickers (Gun) [XMAS2024]"] = "x2 T1 Commons",
            ["Stickers (Gun) [XMAS2025]"] = "x2 T1 Commons",
            ["Stickers (Knife) [HALLOWS2021]"] = "x2 T1 Commons",
            ["Stickers (Knife) [HALLOWS2024]"] = "x2 T1 Commons",
            ["Stickers (Knife) [SUMMER2023]"] = "x2 T1 Commons",
            ["Stickers (Knife) [SUMMER2025]"] = "x2 T1 Commons",
            ["Stickers (Knife) [XMAS2021]"] = "x2 T1 Commons",
            ["Stickers (Knife) [XMAS2022]"] = "x3 T1 Commons",
            ["Stickers (Knife) [XMAS2024]"] = "x2 T1 Commons",
            ["Stickers (Knife) [XMAS2025]"] = "x2 T1 Commons",
            ["Stickers [HALLOWS2022]"] = "x2 T1 Commons",
            ["Stickers [HALLOWS2025]"] = "x2 T1 Commons",
            ["Stickers [THANKSGIVING2025]"] = "x2 T1 Commons",
            ["Stockings"] = "x2 T1 Uncommons",
            ["Stockings (2024)"] = "x2 T1 Commons",
            ["Stockings (Gun)"] = "x3 T1 Uncommons",
            ["Stockings (Knife)"] = "x3 T1 Uncommons",
            ["Storm"] = "x1 T1 Legendary",
            ["Strawberries"] = "x2 T1 Commons",
            ["Strawberries (Gun)"] = "x2 T1 Commons",
            ["Strawberries (Knife)"] = "x2 T1 Commons",
            ["Striped"] = "x2 T1 Commons",
            ["Striped (Gun)"] = "x2 T1 Commons",
            ["Striped (Knife)"] = "x2 T1 Commons",
            ["Sunny"] = "x3 T1 Rares",
            ["Sunset"] = "x3 T1 Rares",
            ["Sweater"] = "x3 T1 Uncommons",
            ["Sweater (Gun) [XMAS2018]"] = "x3 T1 Uncommons",
            ["Sweater (Gun) [XMAS2025]"] = "x2 T1 Uncommons",
            ["Sweater (Knife) [XMAS2025]"] = "x3 T1 Uncommons",
            ["Sweetheart"] = "x4 T1 Legendaries",
            ["Teddy"] = "x1 T1 Legendary",
            ["Tiger"] = "x4 T1 Commons",
            ["TNL"] = "x3 T1 Legendaries",
            ["Tourist"] = "x2 T1 Commons",
            ["Toy"] = "x2 T1 Uncommons",
            ["Toy (Gun)"] = "x1 T1 Uncommon",
            ["Toy (Knife)"] = "x2 T1 Uncommons",
            ["Traveller"] = "x3 T1 Legendaries",
            ["Treats"] = "x3 T1 Uncommons",
            ["Treats (Gun)"] = "x3 T1 Uncommons",
            ["Treats (Knife)"] = "x2 T1 Uncommons",
            ["Tree"] = "x2 T1 Rares",
            ["Tree (2017)"] = "x3 T1 Uncommons",
            ["Tree (2023)"] = "x3 T1 Rares",
            ["Tree (Gun)"] = "x2 T1 Rares",
            ["Tree (Knife)"] = "x3 T1 Rares",
            ["Trees"] = "x2 T1 Uncommons",
            ["Tropical"] = "x3 T1 Rares",
            ["Tulip"] = "x4 T1 Legendaries",
            ["Turtle"] = "x2 T1 Uncommons",
            ["Turtles"] = "x3 T1 Uncommons",
            ["UFOs"] = "x3 T1 Commons",
            ["UFOs (Gun)"] = "x2 T1 Commons",
            ["UFOs (Knife)"] = "x3 T1 Commons",
            ["Universe"] = "x4 T1 Rares",
            ["Valentine"] = "x4 T1 Legendaries",
            ["Vines"] = "x1 T1 Uncommon",
            ["Vines (Gun)"] = "x2 T1 Commons",
            ["Vines (Knife)"] = "x1 T1 Uncommon",
            ["Viper"] = "x4 T1 Rares",
            ["Vortex"] = "x4 T1 Uncommons",
            ["Wanwood"] = "x4 T1 Commons",
            ["Watcher"] = "x3 T1 Commons",
            ["Watcher (Gun)"] = "x3 T1 Commons",
            ["Watcher (Knife)"] = "x2 T1 Commons",
            ["Waves"] = "x2 T1 Rares",
            ["Wavy"] = "x3 T1 Commons",
            ["Wavy (Gun)"] = "x3 T1 Commons",
            ["Wavy (Knife)"] = "x3 T1 Commons",
            ["Web"] = "x4 T1 Legendaries",
            ["Webbed (Knife)"] = "x4 T1 Legendaries",
            ["Webs"] = "x2 T1 Uncommons",
            ["Whiteout"] = "x1 T1 Common",
            ["Witch"] = "x4 T1 Legendaries",
            ["Witch's Brew"] = "x2 T1 Uncommons",
            ["Witchbrew"] = "x3 T1 Uncommons",
            ["Wood"] = "x2 T1 Commons",
            ["Wooden"] = "x4 T1 Commons",
            ["Wraith (Gun)"] = "x1 T1 Legendary",
            ["Wraiths"] = "x1 T1 Legendary",
            ["Wraiths (Gun)"] = "x3 T1 Uncommons",
            ["Wraiths (Knife)"] = "x1 T1 Legendary",
            ["Wrapped (Gun) [XMAS2015]"] = "x4 T1 Legendaries",
            ["Wrapped (Gun) [XMAS2024]"] = "x1 T1 Rare",
            ["Wrapped (Knife)"] = "x3 T1 Commons",
            ["Wrapped (Knife) [XMAS2015]"] = "x4 T1 Legendaries",
            ["Wrapped (Knife) [XMAS2024]"] = "x2 T1 Uncommons",
            ["Wreaths"] = "x2 T1 Uncommons",
            ["Xbox"] = "x2 T1 Commons",
            ["Xeno"] = "x3 T1 Rares",
            ["Xeno (Gun)"] = "x2 T1 Rares",
            ["Xeno (Knife)"] = "x3 T1 Rares",
            ["Yellow"] = "x1 T1 Common",
            ["Yummy"] = "x2 T1 Rares",
        },


        TradeOverlayGui = nil,
        InventoryHeader = nil,
    },
    Combat = {
        AimHooked = false,
        LastShot = 0,
    },
    Animations = {
        CurrentTrack = nil,
        Favorites = {},
        ActiveTab = "Emotes",
        SearchQuery = "",
        ListContainer = nil,
        List = {
            { Id = "3303391864", Name = "Floss Dance", Category = "Emotes", Icon = "rbxassetid://10747384394" },
            { Id = "3303399939", Name = "Hype Dance", Category = "Emotes", Icon = "rbxassetid://10747384394" },
            { Id = "3303387872", Name = "Electro Shuffle", Category = "Emotes", Icon = "rbxassetid://10747384394" },
            { Id = "4212455378", Name = "Ninja Animation", Category = "Walk Styles", Icon = "rbxassetid://10747384394" },
            { Id = "2510198475", Name = "Zombie Walk", Category = "Walk Styles", Icon = "rbxassetid://10747384394" },
            { Id = "3303162083", Name = "Vampire Walk", Category = "Walk Styles", Icon = "rbxassetid://10747384394" },
            { Id = "4551322476", Name = "Sneaky Walk", Category = "Walk Styles", Icon = "rbxassetid://10747384394" },
            { Id = "3303165239", Name = "Levitation Style", Category = "Walk Styles", Icon = "rbxassetid://10747384394" },
            { Id = "3303161396", Name = "Toy Animation", Category = "Walk Styles", Icon = "rbxassetid://10747384394" },
            { Id = "3303382711", Name = "Godly Pose", Category = "Emotes", Icon = "rbxassetid://10747384394" },
            { Id = "3303385410", Name = "Line Dance", Category = "Emotes", Icon = "rbxassetid://10747384394" },
            { Id = "3303389445", Name = "Dab Emote", Category = "Emotes", Icon = "rbxassetid://10747384394" },
        }
    },
    SkinSystem = {
        DatabaseURL = "https://raw.githubusercontent.com/Lisi-prime/mm2_skin/main/skins.json",
        Loaded = false,
        ByName = {},
        BySlot = { Knife = {}, Gun = {} },
        ByRarity = {},
        Meshes = {},
        Musor = {},
        Saved = {},
        Picked = {},
        CurrentKnife = "None",
        CurrentGun = "None",
        AutoReapply = true,
        LobbyPedestal = true,
    }
}

-- ==================== ИКОНКИ LUCIDE ====================
local Icons = {
    Combat = "rbxassetid://10709791437",
    Visuals = "rbxassetid://10723346959",
    Skins = "rbxassetid://10723387687",
    Misc = "rbxassetid://10723387687",
    Fun = "rbxassetid://10723387687",
    Maps = "rbxassetid://10723395215",
    Animation = "rbxassetid://10747372992",
    Config = "rbxassetid://10734950309",
    StarOutline = "rbxassetid://10709790948",
    StarFilled = "rbxassetid://10709790807",
    Close = "rbxassetid://10747384394",
    MapFallback = "rbxassetid://6527581691",
}

-- ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
function Hub:GetSafeParent()
    local ok, res = pcall(function()
        if gethui then return gethui() end
        return self.Services.CoreGui
    end)
    if ok and res then return res end
    return self.Services.Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Hub:Tween(instance, properties, duration, style, direction)
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    duration = duration or 0.25
    local tw = self.Services.TweenService:Create(instance, TweenInfo.new(duration, style, direction), properties)
    tw:Play()
    return tw
end

function Hub:Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

function Hub:Stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or self.Theme.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function Hub:GetRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChildWhichIsA("BasePart")
end

-- ==================== MM2 LOGIC (РОЛИ И СОСТОЯНИЕ РАУНДА) ====================
function Hub:GetRoundModule()
    local ok, m = pcall(function()
        local rep = self.Services.ReplicatedStorage
        local mods = rep:FindFirstChild("Modules")
        if mods then
            local crc = mods:FindFirstChild("CurrentRoundClient")
            if crc then return require(crc) end
        end
        return nil
    end)
    if ok and type(m) == "table" then return m end
    return nil
end

function Hub:GetPlayerDataMap()
    -- 1. Считываем данные из официального модуля CurrentRoundClient
    local m = self:GetRoundModule()
    if m and type(m.PlayerData) == "table" then
        return m.PlayerData
    end

    -- 2. Запасной вариант через Remotes
    local rep = self.Services.ReplicatedStorage
    for _, path in ipairs({ "GetPlayerData", "Remotes.Gameplay.GetPlayerData", "Remotes.GetPlayerData" }) do
        local rem = rep
        for part in path:gmatch("[^%.]+") do
            rem = rem and rem:FindFirstChild(part)
        end
        if rem and rem:IsA("RemoteFunction") then
            local ok, data = pcall(function() return rem:InvokeServer() end)
            if ok and type(data) == "table" then return data end
        end
    end
    return nil
end

function Hub:IsRoundActive()
    local data = self:GetPlayerDataMap()
    if data and type(data) == "table" and next(data) ~= nil then
        for _, pData in pairs(data) do
            if type(pData) == "table" and pData.Role and pData.Role ~= "" and pData.Role ~= "Lobby" and (not pData.Dead) and (not pData.Killed) then
                return true
            end
        end
    end

    if self.Services.Workspace:FindFirstChild("GunDrop") then
        return true
    end

    if self.Services.Workspace:FindFirstChild("Map") or self.Services.Workspace:FindFirstChild("Normal") then
        return true
    end

    self.State.OriginalSheriff = nil
    return false
end

function Hub:IsPlayerInRound(player)
    if not player or not player.Character then return false end
    local root = self:GetRoot(player.Character)
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not (root and hum and hum.Health > 0) then return false end

    -- Если раунд в игре вообще не идет -> никто не в раунде
    if not self:IsRoundActive() then
        return false
    end

    -- Проверка по высоте лобби MM2: если Y > 350, игрок в лобби
    if root.Position.Y > 350 then
        return false
    end

    -- 1. Проверка по официальным данным раунда MM2
    local data = self:GetPlayerDataMap()
    if data and type(data) == "table" and next(data) ~= nil then
        local pd = data[player.Name]
        if not pd then
            -- Игрок отсутствует в данных раунда -> наблюдатель или в лобби
            return false
        end
        if pd.Dead or pd.Killed then
            return false
        end
        if not pd.Role or pd.Role == "" or pd.Role == "Lobby" or pd.Role == "Dead" then
            return false
        end
        return true
    end

    -- 2. Если данных нет, проверяем физическое нахождение на активной карте
    local map = self.Services.Workspace:FindFirstChild("Map") or self.Services.Workspace:FindFirstChild("Normal")
    if not map then
        return false
    end

    return true
end

function Hub:GetPlayerRole(player)
    if not self:IsPlayerInRound(player) then
        return "None"
    end

    local char = player.Character
    local bp = player:FindFirstChildOfClass("Backpack")

    -- 1. Проверяем наличие ножа (Murderer)
    local hasKnife = false
    if char and (char:FindFirstChild("Knife") or (char:FindFirstChildWhichIsA("Tool") and char:FindFirstChildWhichIsA("Tool").Name:lower():find("knife"))) then
        hasKnife = true
    end
    if bp and (bp:FindFirstChild("Knife") or (bp:FindFirstChildWhichIsA("Tool") and bp:FindFirstChildWhichIsA("Tool").Name:lower():find("knife"))) then
        hasKnife = true
    end

    -- 2. Проверяем наличие пистолета (Sheriff или Hero)
    local hasGun = false
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and (item.Name == "Gun" or item.Name:lower():find("gun")) then
                hasGun = true
                break
            end
        end
    end
    if not hasGun and bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and (item.Name == "Gun" or item.Name:lower():find("gun")) then
                hasGun = true
                break
            end
        end
    end

    local data = self:GetPlayerDataMap()
    local pd = data and data[player.Name]

    if hasKnife or (pd and pd.Role == "Murderer") then
        return "Murderer"
    end

    if hasGun then
        -- Если у игрока в руках или рюкзаке пистолет:
        if pd then
            if pd.Role == "Hero" or pd.Hero == true then
                return "Hero"
            end
            if pd.Role == "Innocent" then
                -- Невинный, который подобрал выпавший пистолет -> HERO!
                return "Hero"
            end
            if pd.Role == "Sheriff" then
                if not self.State.OriginalSheriff then
                    self.State.OriginalSheriff = player.Name
                end
                return "Sheriff"
            end
        end

        -- Если данных раунда нет или роль не указана
        if self.State.OriginalSheriff and self.State.OriginalSheriff ~= player.Name then
            return "Hero"
        end

        if not self.State.OriginalSheriff then
            self.State.OriginalSheriff = player.Name
            return "Sheriff"
        end

        return "Hero"
    end

    -- 3. Если пистолета/ножа нет прямо сейчас в руках/рюкзаке
    if pd and pd.Role and pd.Role ~= "" and pd.Role ~= "Lobby" and pd.Role ~= "Dead" then
        if pd.Role == "Sheriff" then
            if not self.State.OriginalSheriff then
                self.State.OriginalSheriff = player.Name
            end
            return "Sheriff"
        end
        if pd.Role == "Hero" or pd.Hero == true then
            return "Hero"
        end
        return pd.Role
    end

    return "Innocent"
end

function Hub:GetRoleColor(role)
    if role == "Murderer" then return self.Theme.MurderRed
    elseif role == "Sheriff" then return self.Theme.SheriffBlue
    elseif role == "Hero" then return self.Theme.HeroYellow
    else return self.Theme.InnocentGreen
    end
end

function Hub:GetMurderer()
    -- 1. Сначала проверяем по официальным ролям
    for _, p in ipairs(self.Services.Players:GetPlayers()) do
        if p ~= self.Services.Players.LocalPlayer then
            local r = self:GetPlayerRole(p)
            if r == "Murderer" then return p end
        end
    end

    -- 2. Если роли еще не применились, проверяем наличие ножа у любого игрока
    for _, p in ipairs(self.Services.Players:GetPlayers()) do
        if p ~= self.Services.Players.LocalPlayer then
            local c = p.Character
            if c and c:FindFirstChild("Knife") then return p end
        end
    end

    return nil
end

function Hub:GetSheriff()
    for _, p in ipairs(self.Services.Players:GetPlayers()) do
        if p ~= self.Services.Players.LocalPlayer then
            local r = self:GetPlayerRole(p)
            if r == "Sheriff" or r == "Hero" then return p end
        end
    end

    for _, p in ipairs(self.Services.Players:GetPlayers()) do
        if p ~= self.Services.Players.LocalPlayer then
            local c = p.Character
            if c and c:FindFirstChild("Gun") then return p end
        end
    end

    return nil
end

function Hub:GetShootRemote()
    local lp = self.Services.Players.LocalPlayer
    local containers = { lp.Character, lp:FindFirstChildOfClass("Backpack") }
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    for _, rName in ipairs({ "Shoot", "ShootEvent", "ShootGun", "Fire" }) do
                        local rem = item:FindFirstChild(rName)
                        if rem and (rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction")) then
                            return rem, item
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

function Hub:FindKnife()
    local lp = self.Services.Players.LocalPlayer
    local containers = { lp.Character, lp:FindFirstChildOfClass("Backpack") }
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and (item.Name:lower():find("knife") or item:FindFirstChild("Slash") or item:FindFirstChild("Stab")) then
                    return item
                end
            end
        end
    end
    return nil
end

-- ==================== COMBAT / SHOOTING ====================
function Hub:GetAimTargetPart(character)
    if not character then return nil end
    return character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Head")
end

function Hub:GetPredictedAimPos(targetPart)
    if not targetPart then return Vector3.zero end
    local basePos = targetPart.Position
    local vel = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.zero

    -- Ограничиваем нереалистичные скачки скорости
    if vel.Magnitude > 60 then
        vel = vel.Unit * 60
    end

    -- Сетевой пинг игрока
    local ping = 0.04
    pcall(function()
        local stats = game:GetService("Stats")
        local net = stats and stats:FindFirstChild("Network")
        local sItem = net and net:FindFirstChild("ServerStatsItem")
        local pingVal = sItem and sItem:FindFirstChild("Data Ping")
        if pingVal then
            ping = math.clamp(pingVal:GetValue() / 1000, 0.015, 0.2)
        end
    end)

    -- В MM2 выстрел на сервере регистрируется как хитскан (Raycast).
    -- Компенсируем только сетевую задержку пакета (пинг) без перелета:
    local lead = ping * 0.85
    if self.Config.Toggles.AimPrediction then
        local userPct = (self.Config.Values.PredictionPercent or 40) / 40
        lead = lead * userPct
    end

    local predictedPos = basePos + (vel * lead)
    return predictedPos
end

function Hub:PerformFlick(targetWorldPos)
    local mode = self.Config.Values.FlickMode or "Mouse"
    local cam = self.Services.Workspace.CurrentCamera
    if not cam then return end

    if mode == "Mouse" then
        local screenPos, onScreen = cam:WorldToViewportPoint(targetWorldPos)
        if onScreen then
            local mouse = self.Services.Players.LocalPlayer:GetMouse()
            local curX, curY = mouse.X, mouse.Y
            local dx = math.floor(screenPos.X - curX)
            local dy = math.floor(screenPos.Y - curY)
            if mousemoverel then
                mousemoverel(dx, dy)
            elseif mousemoveabs then
                mousemoveabs(screenPos.X, screenPos.Y)
            elseif self.Services.VirtualInputManager then
                pcall(function()
                    self.Services.VirtualInputManager:SendMouseMoveEvent(screenPos.X, screenPos.Y, game)
                end)
            end
        end
    else
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetWorldPos)
    end
end

function Hub:ShootMurderer()
    local remote, gunTool = self:GetShootRemote()
    if not (remote and gunTool) then return end

    local lp = self.Services.Players.LocalPlayer
    local myChar = lp.Character
    if not myChar then return end
    local myRoot = self:GetRoot(myChar)
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    if not (myRoot and hum and hum.Health > 0) then return end

    local murderer = self:GetMurderer()
    local targetPos = nil

    if murderer and murderer.Character then
        local aimPart = self:GetAimTargetPart(murderer.Character)
        if aimPart then
            targetPos = self:GetPredictedAimPos(aimPart)
        end
    end

    -- Если убийца не определен, стреляем по направлению курсора мыши
    if not targetPos then
        local mouse = lp:GetMouse()
        targetPos = mouse.Hit.Position
    end

    -- Flick Shot (только если оружие уже в руках)
    if self.Config.Toggles.FlickShot and murderer and murderer.Character and gunTool.Parent == myChar then
        self:PerformFlick(targetPos)
    end

    -- Получаем официальный CFrame точки выстрела (GunRaycastAttachment на HumanoidRootPart)
    local hrp = myChar:FindFirstChild("HumanoidRootPart") or myRoot
    local att = hrp:FindFirstChild("GunRaycastAttachment")
    local originCF = (att and att.WorldCFrame) or hrp.CFrame

    -- Улучшенный AimWallbang: аккуратный прострел через стены/преграды
    if self.Config.Toggles.AimWallbang and targetPos then
        local delta = (targetPos - hrp.Position)
        if delta.Magnitude > 3 then
            originCF = originCF + (delta.Unit * math.clamp(delta.Magnitude * 0.25, 2.5, 7.5))
        end
    end

    local targetCF = CFrame.new(targetPos)

    self.Combat.LastShot = os.clock()

    -- Отправляем точный выстрел в цель без принудительной экипировки оружия в руки
    pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(originCF, targetCF)
        else
            remote:InvokeServer(originCF, targetCF)
        end
    end)
end

function Hub:HookSilentAim()
    if self.Combat.AimHooked then return end
    if not (hookmetamethod and newcclosure and getnamecallmethod) then return end

    local oldNC
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if (method == "FireServer" or method == "InvokeServer") then
            local n = tostring(self.Name):lower()
            if n == "shoot" or n == "shootevent" or n == "shootgun" or n == "fire" then
                if Hub.Config.Toggles.SilentAim and not (checkcaller and checkcaller()) then
                    local murderer = Hub:GetMurderer()
                    if murderer and murderer.Character then
                        local aimPart = Hub:GetAimTargetPart(murderer.Character)
                        if aimPart then
                            local args = { ... }
                            local nArgs = select("#", ...)
                            local aimPos = Hub:GetPredictedAimPos(aimPart)

                            -- Улучшенный Wallbang: прострел через стены
                            if Hub.Config.Toggles.AimWallbang and typeof(args[1]) == "CFrame" then
                                local lp = Hub.Services.Players.LocalPlayer
                                local myRoot = lp.Character and Hub:GetRoot(lp.Character)
                                if myRoot then
                                    local delta = (aimPos - myRoot.Position)
                                    if delta.Magnitude > 3 then
                                        args[1] = args[1] + (delta.Unit * math.clamp(delta.Magnitude * 0.25, 2.5, 7.5))
                                    end
                                end
                            end

                            -- Перенаправляем точку прицеливания (args[2]):
                            if typeof(args[2]) == "CFrame" then
                                args[2] = CFrame.new(aimPos)
                            elseif typeof(args[2]) == "Vector3" then
                                args[2] = aimPos
                            else
                                args[2] = CFrame.new(aimPos)
                            end

                            if setnamecallmethod then
                                setnamecallmethod(method)
                            end
                            return oldNC(self, table.unpack(args, 1, math.max(nArgs, 2)))
                        end
                    end
                end
            end
        end
        if setnamecallmethod then
            setnamecallmethod(method)
        end
        return oldNC(self, ...)
    end))
    self.Combat.AimHooked = true
end

function Hub:StabClassic(targetPlr, knife)
    local lp = self.Services.Players.LocalPlayer
    local myChar = lp.Character
    local ch = targetPlr.Character
    local root = self:GetRoot(ch)
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not (root and hum and hum.Health > 0 and knife) then return end

    if knife.Parent ~= myChar then
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if myHum then pcall(function() myHum:EquipTool(knife) end) end
        if knife.Parent ~= myChar then knife.Parent = myChar end
    end

    pcall(function() knife:Activate() end)

    for _, o in ipairs(knife:GetDescendants()) do
        if o:IsA("RemoteEvent") then
            pcall(function() o:FireServer(root, root.Position) end)
            pcall(function() o:FireServer() end)
        elseif o:IsA("RemoteFunction") then
            pcall(function() o:InvokeServer(root, root.Position) end)
        end
    end

    if firetouchinterest then
        local handle = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
        if handle then
            for _, hit in ipairs({ root, ch:FindFirstChild("Head"), ch:FindFirstChild("UpperTorso") }) do
                if hit then
                    pcall(function()
                        firetouchinterest(handle, hit, 0)
                        firetouchinterest(handle, hit, 1)
                    end)
                end
            end
        end
    end
end

function Hub:StabSilent(targetPlr, knife)
    local ch = targetPlr.Character
    local root = self:GetRoot(ch)
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not (root and hum and hum.Health > 0 and knife) then return end

    for _, o in ipairs(knife:GetDescendants()) do
        if o:IsA("RemoteEvent") then
            pcall(function() o:FireServer(root, root.Position) end)
        elseif o:IsA("RemoteFunction") then
            pcall(function() o:InvokeServer(root, root.Position) end)
        end
    end

    if firetouchinterest then
        local handle = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
        if handle then
            pcall(function()
                firetouchinterest(handle, root, 0)
                firetouchinterest(handle, root, 1)
            end)
        end
    end
end

function Hub:ExecuteKillAll()
    local knife = self:FindKnife()
    if not knife then return end
    local lp = self.Services.Players.LocalPlayer
    local mode = self.Config.Values.KillAllMode or "Classic"

    for _, p in ipairs(self.Services.Players:GetPlayers()) do
        if p ~= lp then
            task.spawn(function()
                if mode == "Silent" then
                    self:StabSilent(p, knife)
                else
                    self:StabClassic(p, knife)
                end
            end)
        end
    end
end

function Hub:KillSheriff()
    local target = self:GetSheriff()
    local knife = self:FindKnife()
    if target and target.Character and knife then
        local mode = self.Config.Values.KillSheriffMode or "Classic"
        task.spawn(function()
            if mode == "Silent" then
                self:StabSilent(target, knife)
            else
                self:StabClassic(target, knife)
            end
        end)
    end
end

function Hub:GetDroppedGunPart()
    local gd = self.Services.Workspace:FindFirstChild("GunDrop")
    if not gd then
        gd = self.Services.Workspace:FindFirstChild("GunDrop", true)
    end
    if not gd then
        for _, obj in ipairs(self.Services.Workspace:GetChildren()) do
            if obj.Name:lower():find("gundrop") or (obj:IsA("Tool") and obj.Name == "Gun" and obj.Parent == self.Services.Workspace) then
                gd = obj
                break
            end
        end
    end
    if gd then
        if gd:IsA("BasePart") then return gd end
        local handle = gd:FindFirstChild("Handle") or gd:FindFirstChild("GunDrop") or gd:FindFirstChildWhichIsA("BasePart", true)
        return handle
    end
    return nil
end

function Hub:GrabDroppedGun()
    local lp = self.Services.Players.LocalPlayer
    if not self:IsPlayerInRound(lp) then return end

    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = self:GetRoot(char)
    if not (char and root and hum and hum.Health > 0 and firetouchinterest) then return end

    -- Не пытаться подбирать, если у игрока уже есть пистолет в руках или рюкзаке
    local bp = lp:FindFirstChildOfClass("Backpack")
    if char:FindFirstChild("Gun") or (bp and bp:FindFirstChild("Gun")) then return end

    local handle = self:GetDroppedGunPart()
    if not handle then return end

    -- Только чистое искусственное касание (firetouchinterest) частями тела
    for _, part in ipairs({ root, char:FindFirstChild("RightHand"), char:FindFirstChild("Right Arm"), char:FindFirstChild("LeftFoot"), char:FindFirstChild("Head") }) do
        if part then
            pcall(function()
                firetouchinterest(part, handle, 0)
                firetouchinterest(part, handle, 1)
            end)
        end
    end
end

function Hub:FixToolGrip()
    self:StopAnimation()
    local lp = self.Services.Players.LocalPlayer
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local bp = lp:FindFirstChildOfClass("Backpack")
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and hum and bp then
        tool.Parent = bp
        task.wait(0.08)
        hum:EquipTool(tool)
    end
end

-- ==================== 3D CHARACTER PREVIEW ====================
function Hub:SetupPreview(container)
    local vp = Instance.new("ViewportFrame")
    vp.Name = "CharacterPreview"
    vp.Size = UDim2.new(1, 0, 0, 240)
    vp.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    vp.BorderSizePixel = 0
    vp.Ambient = Color3.fromRGB(230, 230, 240)
    vp.LightColor = Color3.fromRGB(255, 255, 255)
    vp.LightDirection = Vector3.new(-1, -1.5, -2)
    vp.Parent = container
    self:Corner(vp, 8)
    self:Stroke(vp, self.Theme.Border, 1)

    local world = Instance.new("WorldModel")
    world.Parent = vp

    local cam = Instance.new("Camera")
    cam.FieldOfView = 50
    cam.Parent = vp
    vp.CurrentCamera = cam

    self.Preview.Viewport = vp
    self.Preview.World = world
    self.Preview.Camera = cam

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, 0, 0, 20)
    hint.Position = UDim2.new(0, 0, 1, -22)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.GothamMedium
    hint.Text = "Drag mouse to rotate 3D character (All Axes)"
    hint.TextColor3 = self.Theme.TextMuted
    hint.TextSize = 10
    hint.Parent = vp

    vp.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Preview.Dragging = true
            self.Preview.LastMouse = Vector2.new(input.Position.X, input.Position.Y)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    self.Preview.Dragging = false
                end
            end)
        end
    end)

    self.Services.UserInputService.InputChanged:Connect(function(input)
        if self.Preview.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local current = Vector2.new(input.Position.X, input.Position.Y)
            local delta = current - self.Preview.LastMouse
            self.Preview.LastMouse = current
            self.Preview.Yaw = self.Preview.Yaw - delta.X * 0.015
            self.Preview.Pitch = math.clamp(self.Preview.Pitch - delta.Y * 0.015, -1.35, 1.35)
            self:UpdatePreviewCamera()
        end
    end)

    task.spawn(function()
        task.wait(0.2)
        self:CloneLocalPlayerModel()
    end)

    self.Services.RunService.RenderStepped:Connect(function(dt)
        if self.State.IsOpen and self.Config.ActiveTab == "Visuals" then
            if not self.Preview.Dragging and self.Config.Toggles.PreviewRotate then
                self.Preview.Yaw = self.Preview.Yaw + dt * 0.5
                self:UpdatePreviewCamera()
            end
        end
    end)
end

function Hub:CloneLocalPlayerModel()
    if self.Preview.Model then
        pcall(function() self.Preview.Model:Destroy() end)
        self.Preview.Model = nil
    end

    local lp = self.Services.Players.LocalPlayer
    local char = lp.Character
    if not char then return end

    local clone = Instance.new("Model")
    clone.Name = "PreviewRig"
    local cframeOrigin = char:GetPivot()

    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("CharacterMesh") then
            pcall(function()
                local c = item:Clone()
                c.Parent = clone
            end)
        end
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            local hClone = hum:Clone()
            hClone.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hClone.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            hClone.Parent = clone
        end)
    end

    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("BasePart") then
            local p = item:Clone()
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            local rel = cframeOrigin:ToObjectSpace(item.CFrame)
            p.CFrame = CFrame.new(rel.Position) * rel.Rotation
            p.Parent = clone
        elseif item:IsA("Accessory") then
            local acc = item:Clone()
            local h = acc:FindFirstChild("Handle")
            if h and h:IsA("BasePart") then
                h.Anchored = true
                h.CanCollide = false
                local rel = cframeOrigin:ToObjectSpace(h.CFrame)
                h.CFrame = CFrame.new(rel.Position) * rel.Rotation
            end
            acc.Parent = clone
        end
    end

    clone.Parent = self.Preview.World
    self.Preview.Model = clone

    self:UpdatePreviewCamera()
    self:TogglePreviewAura(self.Config.Toggles.PreviewAura)
    self:UpdatePreviewLocalESP()
end

function Hub:UpdatePreviewCamera()
    if not self.Preview.Camera then return end
    local dist = 7.2
    local target = Vector3.new(0, 0.1, 0)
    local cf = CFrame.new(target)
        * CFrame.Angles(0, self.Preview.Yaw, 0)
        * CFrame.Angles(self.Preview.Pitch, 0, 0)
        * CFrame.new(0, 0, dist)
    self.Preview.Camera.CFrame = CFrame.lookAt(cf.Position, target)
end

function Hub:TogglePreviewAura(state)
    self.Config.Toggles.PreviewAura = state
    if not self.Preview.Model then return end
    local root = self:GetRoot(self.Preview.Model) or self.Preview.Model:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    if state then
        if not self.Preview.AuraEmitter then
            local p = Instance.new("ParticleEmitter")
            p.Name = "PreviewAuraEmitter"
            p.Texture = "rbxassetid://243098098"
            p.Rate = 24
            p.Lifetime = NumberRange.new(0.8, 1.4)
            p.Speed = NumberRange.new(1.5, 3)
            p.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.4),
                NumberSequenceKeypoint.new(1, 1.2),
            })
            p.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2),
                NumberSequenceKeypoint.new(1, 1),
            })
            p.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
            p.LightEmission = 0.8
            p.Parent = root
            self.Preview.AuraEmitter = p
        end
    else
        if self.Preview.AuraEmitter then
            pcall(function() self.Preview.AuraEmitter:Destroy() end)
            self.Preview.AuraEmitter = nil
        end
    end
end

function Hub:UpdatePreviewLocalESP()
    if not self.Preview.Model then return end
    local lp = self.Services.Players.LocalPlayer
    local role = self:GetPlayerRole(lp)
    local color = self:GetRoleColor(role)

    local selBox = self.Preview.Model:FindFirstChild("PreviewESP_Box")
    if self.Config.Toggles.LocalESP then
        if not selBox then
            selBox = Instance.new("SelectionBox")
            selBox.Name = "PreviewESP_Box"
            selBox.LineThickness = 0.04
            selBox.SurfaceTransparency = 0.65
            selBox.Adornee = self.Preview.Model
            selBox.Parent = self.Preview.Model
        end
        selBox.Color3 = color
        selBox.SurfaceColor3 = color
        selBox.Visible = true

        if self.Preview.AuraEmitter then
            self.Preview.AuraEmitter.Color = ColorSequence.new(color)
        end
    else
        if selBox then
            selBox.Visible = false
        end
        if self.Preview.AuraEmitter then
            self.Preview.AuraEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        end
    end
end

-- ==================== ESP ROLES & DRAWINGS ====================
function Hub:ClearGunESP()
    if self.ESP.GunHighlight then
        pcall(function() self.ESP.GunHighlight:Destroy() end)
        self.ESP.GunHighlight = nil
    end
    if self.ESP.GunBillboard then
        pcall(function() self.ESP.GunBillboard:Destroy() end)
        self.ESP.GunBillboard = nil
    end
    if self.ESP.GunBillboardBot then
        pcall(function() self.ESP.GunBillboardBot:Destroy() end)
        self.ESP.GunBillboardBot = nil
    end
    if self.ESP.GunDrawing then
        if self.ESP.GunDrawing.Tracer then
            pcall(function()
                self.ESP.GunDrawing.Tracer.Visible = false
                self.ESP.GunDrawing.Tracer:Remove()
            end)
        end
        self.ESP.GunDrawing = nil
    end
end

function Hub:ClearAllESP()
    for _, h in pairs(self.ESP.Highlights) do
        if h then pcall(function() h:Destroy() end) end
    end
    table.clear(self.ESP.Highlights)

    for _, d in pairs(self.ESP.Drawings) do
        if d.Box then pcall(function() d.Box.Visible = false; d.Box:Remove() end) end
        if d.Tracer then pcall(function() d.Tracer.Visible = false; d.Tracer:Remove() end) end
    end
    table.clear(self.ESP.Drawings)

    for _, p in ipairs(self.Services.Players:GetPlayers()) do
        local char = p.Character
        if char then
            local bg = char:FindFirstChild("MM2_ESP_Top")
            if bg then bg:Destroy() end
            local bgBot = char:FindFirstChild("MM2_ESP_Bot")
            if bgBot then bgBot:Destroy() end
        end
    end

    self:ClearGunESP()
end

function Hub:RenderESP()
    if not self.Config.Toggles.ESPRoles and not self.Config.Toggles.ESPGun then
        self:ClearAllESP()
        return
    end

    local lp = self.Services.Players.LocalPlayer
    local myRoot = self:GetRoot(lp.Character)
    local cam = self.Services.Workspace.CurrentCamera
    local roundActive = self:IsRoundActive()

    if self.Config.Toggles.ESPRoles then
        for _, p in ipairs(self.Services.Players:GetPlayers()) do
            local isSelf = (p == lp)
        local char = p.Character
        local root = self:GetRoot(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local isAlive = hum and hum.Health > 0
        local role = self:GetPlayerRole(p)

        local inRound = roundActive and self:IsPlayerInRound(p)
        local shouldRender = inRound and isAlive and root and (role ~= "None") and (role ~= "Dead")
        if isSelf and not self.Config.Toggles.LocalESP then
            shouldRender = false
        end

        -- Отображаем живых участников раунда
        if shouldRender then
            local color = self:GetRoleColor(role)

            -- 1. Highlight (всегда включен вместе с ESP)
            local hl = self.ESP.Highlights[p]
            if not hl or hl.Parent ~= char then
                if hl then pcall(function() hl:Destroy() end) end
                hl = Instance.new("Highlight")
                hl.Name = "MM2_Highlight"
                hl.Adornee = char
                hl.FillTransparency = 0.45
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = char
                self.ESP.Highlights[p] = hl
            end
            hl.FillColor = color
            hl.OutlineColor = color

                -- 2. Текстовые метки над головой (Role, Nickname)
                local head = char:FindFirstChild("Head") or root
                local topGui = char:FindFirstChild("MM2_ESP_Top")
                if not topGui then
                    topGui = Instance.new("BillboardGui")
                    topGui.Name = "MM2_ESP_Top"
                    topGui.Adornee = head
                    topGui.Size = UDim2.new(0, 160, 0, 36)
                    topGui.StudsOffset = Vector3.new(0, 2.4, 0)
                    topGui.AlwaysOnTop = true
                    topGui.Parent = char

                    local lRole = Instance.new("TextLabel")
                    lRole.Name = "RoleLabel"
                    lRole.Size = UDim2.new(1, 0, 0, 16)
                    lRole.BackgroundTransparency = 1
                    lRole.Font = Enum.Font.GothamBold
                    lRole.TextSize = 12
                    lRole.Parent = topGui

                    local lNick = Instance.new("TextLabel")
                    lNick.Name = "NickLabel"
                    lNick.Size = UDim2.new(1, 0, 0, 16)
                    lNick.Position = UDim2.new(0, 0, 0, 16)
                    lNick.BackgroundTransparency = 1
                    lNick.Font = Enum.Font.GothamMedium
                    lNick.TextSize = 11
                    lNick.TextColor3 = Color3.fromRGB(240, 240, 245)
                    lNick.Parent = topGui
                end

                local rLabel = topGui:FindFirstChild("RoleLabel")
                if rLabel then
                    rLabel.Visible = self.Config.Toggles.ESPRoleText
                    rLabel.Text = (isSelf and "[YOU] " or "") .. role:upper()
                    rLabel.TextColor3 = color
                end

                local nLabel = topGui:FindFirstChild("NickLabel")
                if nLabel then
                    nLabel.Visible = self.Config.Toggles.ESPNickname
                    nLabel.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                end

                -- 3. Текстовая метка под ногами (Distance) — только для других игроков
                local botGui = char:FindFirstChild("MM2_ESP_Bot")
                if not isSelf and self.Config.Toggles.ESPDist and myRoot then
                    if not botGui then
                        botGui = Instance.new("BillboardGui")
                        botGui.Name = "MM2_ESP_Bot"
                        botGui.Adornee = root
                        botGui.Size = UDim2.new(0, 120, 0, 18)
                        botGui.StudsOffset = Vector3.new(0, -3.2, 0)
                        botGui.AlwaysOnTop = true
                        botGui.Parent = char

                        local lDist = Instance.new("TextLabel")
                        lDist.Name = "DistLabel"
                        lDist.Size = UDim2.new(1, 0, 1, 0)
                        lDist.BackgroundTransparency = 1
                        lDist.Font = Enum.Font.GothamBold
                        lDist.TextSize = 11
                        lDist.TextColor3 = Color3.fromRGB(255, 255, 255)
                        lDist.Parent = botGui
                    end
                    local dLabel = botGui:FindFirstChild("DistLabel")
                    if dLabel then
                        local dist = math.floor((root.Position - myRoot.Position).Magnitude)
                        dLabel.Text = tostring(dist) .. "m"
                    end
                else
                    if botGui then botGui:Destroy() end
                end

                -- 4. 2D Boxes & Tracers (Drawing API)
                if Drawing and Drawing.new and cam then
                    if not self.ESP.Drawings[p] then
                        self.ESP.Drawings[p] = {}
                    end
                    local d = self.ESP.Drawings[p]

                    -- Box 2D
                    if self.Config.Toggles.ESPBoxes then
                        if not d.Box then
                            local ok, box = pcall(Drawing.new, "Square")
                            if ok then
                                box.Thickness = 1.5
                                box.Filled = false
                                box.Transparency = 1
                                d.Box = box
                            end
                        end
                        if d.Box then
                            local screenPos, onScreen = cam:WorldToViewportPoint(root.Position)
                            if onScreen then
                                local headPos = cam:WorldToViewportPoint(root.Position + Vector3.new(0, 2.8, 0))
                                local legPos = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))
                                local h = math.abs(headPos.Y - legPos.Y)
                                local w = h * 0.65
                                d.Box.Size = Vector2.new(w, h)
                                d.Box.Position = Vector2.new(screenPos.X - w / 2, screenPos.Y - h / 2)
                                d.Box.Color = color
                                d.Box.Visible = true
                            else
                                d.Box.Visible = false
                            end
                        end
                    else
                        if d.Box then d.Box.Visible = false end
                    end

                    -- Tracer (только для других игроков)
                    if not isSelf and self.Config.Toggles.ESPTracers then
                        if not d.Tracer then
                            local ok, tr = pcall(Drawing.new, "Line")
                            if ok then
                                tr.Thickness = 1.2
                                tr.Transparency = 0.85
                                d.Tracer = tr
                            end
                        end
                        if d.Tracer then
                            local screenPos, onScreen = cam:WorldToViewportPoint(root.Position)
                            if onScreen then
                                d.Tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                                d.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                                d.Tracer.Color = color
                                d.Tracer.Visible = true
                            else
                                d.Tracer.Visible = false
                            end
                        end
                    else
                        if d.Tracer then d.Tracer.Visible = false end
                    end
                end
            else
                -- Очистка
                if self.ESP.Highlights[p] then
                    pcall(function() self.ESP.Highlights[p]:Destroy() end)
                    self.ESP.Highlights[p] = nil
                end
                if char then
                    local bg = char:FindFirstChild("MM2_ESP_Top")
                    if bg then bg:Destroy() end
                    local bgBot = char:FindFirstChild("MM2_ESP_Bot")
                    if bgBot then bgBot:Destroy() end
                end
                if self.ESP.Drawings[p] then
                    if self.ESP.Drawings[p].Box then self.ESP.Drawings[p].Box.Visible = false end
                    if self.ESP.Drawings[p].Tracer then self.ESP.Drawings[p].Tracer.Visible = false end
                end
            end
        end
    else
        for _, h in pairs(self.ESP.Highlights) do
            if h then pcall(function() h:Destroy() end) end
        end
        table.clear(self.ESP.Highlights)
        for _, d in pairs(self.ESP.Drawings) do
            if d.Box then pcall(function() d.Box.Visible = false; d.Box:Remove() end) end
            if d.Tracer then pcall(function() d.Tracer.Visible = false; d.Tracer:Remove() end) end
        end
        table.clear(self.ESP.Drawings)
        for _, p in ipairs(self.Services.Players:GetPlayers()) do
            local char = p.Character
            if char then
                local bg = char:FindFirstChild("MM2_ESP_Top")
                if bg then bg:Destroy() end
                local bgBot = char:FindFirstChild("MM2_ESP_Bot")
                if bgBot then bgBot:Destroy() end
            end
        end
    end

    -- 5. ESP Dropped Gun (выпавший пистолет на карте)
    if self.Config.Toggles.ESPGun then
        local gunPart = self:GetDroppedGunPart()
        if gunPart and gunPart:IsDescendantOf(self.Services.Workspace) then
            -- Выделяем ТОЛЬКО сам пистолет (не Workspace!)
            local gunObj = gunPart
            if gunPart.Parent and gunPart.Parent:IsA("Tool") then
                gunObj = gunPart.Parent
            end

            -- Highlight (только пистолет)
            local gHl = self.ESP.GunHighlight
            if not gHl or gHl.Parent ~= gunObj or gHl.Adornee ~= gunObj then
                if gHl then pcall(function() gHl:Destroy() end) end
                gHl = Instance.new("Highlight")
                gHl.Name = "MM2_Gun_Highlight"
                gHl.Adornee = gunObj
                gHl.FillTransparency = 0.35
                gHl.OutlineTransparency = 0
                gHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                gHl.FillColor = self.Theme.HeroYellow
                gHl.OutlineColor = Color3.fromRGB(255, 255, 255)
                gHl.Parent = gunObj
                self.ESP.GunHighlight = gHl
            else
                gHl.FillColor = self.Theme.HeroYellow
                gHl.OutlineColor = Color3.fromRGB(255, 255, 255)
            end

            -- BillboardGui НАД выпавшим пистолетом (название желтым)
            local gBg = self.ESP.GunBillboard
            if not gBg or gBg.Parent ~= gunPart then
                if gBg then pcall(function() gBg:Destroy() end) end
                gBg = Instance.new("BillboardGui")
                gBg.Name = "MM2_Gun_ESP"
                gBg.Adornee = gunPart
                gBg.Size = UDim2.new(0, 140, 0, 18)
                gBg.StudsOffset = Vector3.new(0, 1.4, 0)
                gBg.AlwaysOnTop = true
                gBg.Parent = gunPart
                self.ESP.GunBillboard = gBg

                local lGun = Instance.new("TextLabel")
                lGun.Name = "GunLabel"
                lGun.Size = UDim2.new(1, 0, 1, 0)
                lGun.BackgroundTransparency = 1
                lGun.Font = Enum.Font.GothamBold
                lGun.TextSize = 13
                lGun.TextColor3 = self.Theme.HeroYellow
                lGun.Text = "DROPPED GUN"
                lGun.Parent = gBg
            end

            -- BillboardGui СНИЗУ выпавшего пистолета (дистанция белым текстом)
            local gBgBot = self.ESP.GunBillboardBot
            if not gBgBot or gBgBot.Parent ~= gunPart then
                if gBgBot then pcall(function() gBgBot:Destroy() end) end
                gBgBot = Instance.new("BillboardGui")
                gBgBot.Name = "MM2_Gun_ESP_Bot"
                gBgBot.Adornee = gunPart
                gBgBot.Size = UDim2.new(0, 100, 0, 16)
                gBgBot.StudsOffset = Vector3.new(0, -1.4, 0)
                gBgBot.AlwaysOnTop = true
                gBgBot.Parent = gunPart
                self.ESP.GunBillboardBot = gBgBot

                local lDist = Instance.new("TextLabel")
                lDist.Name = "GunDistLabel"
                lDist.Size = UDim2.new(1, 0, 1, 0)
                lDist.BackgroundTransparency = 1
                lDist.Font = Enum.Font.GothamBold
                lDist.TextSize = 12
                lDist.TextColor3 = Color3.fromRGB(255, 255, 255)
                lDist.Text = "0m"
                lDist.Parent = gBgBot
            end

            local lDist = gBgBot:FindFirstChild("GunDistLabel")
            if lDist and myRoot then
                local dist = math.floor((gunPart.Position - myRoot.Position).Magnitude)
                lDist.Text = tostring(dist) .. "m"
            end
        else
            self:ClearGunESP()
        end
    else
        self:ClearGunESP()
    end
end

-- ==================== WORLD SETTINGS (ВЫЕЗЖАЮЩИЙ СНИЗУ РАЗДЕЛ) ====================
function Hub:ApplyWorldSettings()
    local L = self.Services.Lighting

    if not self.World.OrigAmbient then
        self.World.OrigAmbient = L.Ambient
        self.World.OrigClockTime = L.ClockTime
        self.World.OrigFogEnd = L.FogEnd
        self.World.OrigShadows = L.GlobalShadows
    end

    -- 1. FullBright
    if self.Config.Toggles.FullBright then
        L.Brightness = 2
        L.Ambient = Color3.fromRGB(255, 255, 255)
        L.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        L.Brightness = 1
        L.Ambient = self.World.OrigAmbient or Color3.fromRGB(128, 128, 128)
    end

    -- 2. No Fog
    if self.Config.Toggles.NoFog then
        L.FogEnd = 9e9
        L.FogStart = 9e9
    else
        L.FogEnd = self.World.OrigFogEnd or 1000
    end

    -- 3. Shadows
    L.GlobalShadows = self.Config.Toggles.WorldShadows

    -- 4. Time of Day
    if not self.Config.Toggles.FullBright then
        L.ClockTime = self.Config.Values.ClockTime
    end

    -- 5. Camera FOV
    local cam = self.Services.Workspace.CurrentCamera
    if cam then
        cam.FieldOfView = self.Config.Values.CameraFOV
    end

    -- 6. Ambient Tint
    local tint = self.Config.Values.AmbientTint
    if tint == "Neon Purple" then
        L.ColorShift_Top = Color3.fromRGB(220, 100, 255)
    elseif tint == "Sunset Warm" then
        L.ColorShift_Top = Color3.fromRGB(255, 160, 90)
    elseif tint == "Midnight Blue" then
        L.ColorShift_Top = Color3.fromRGB(80, 120, 255)
    else
        L.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    end

    if self.Config.Toggles.XRay then
        self:ApplyXRay()
    end
end

-- ==================== X-RAY & ANTI-AFK ====================
function Hub:IsCharacterOrGunPart(part)
    if not part then return false end
    for _, p in ipairs(self.Services.Players:GetPlayers()) do
        if p.Character and part:IsDescendantOf(p.Character) then
            return true
        end
    end
    local gun = self.Services.Workspace:FindFirstChild("GunDrop")
    if gun and part:IsDescendantOf(gun) then
        return true
    end
    return false
end

function Hub:ApplyXRay()
    if not self.World.OriginalTransparency then
        self.World.OriginalTransparency = {}
    end
    local targetTrans = math.clamp(self.Config.Values.XRayTransparency / 100, 0, 1)

    for _, part in ipairs(self.Services.Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsA("Terrain") then
            if not self:IsCharacterOrGunPart(part) and part.Transparency < 0.95 then
                if self.World.OriginalTransparency[part] == nil then
                    self.World.OriginalTransparency[part] = part.Transparency
                end
                part.Transparency = targetTrans
            end
        end
    end

    if not self.World.XRayConnection then
        self.World.XRayConnection = self.Services.Workspace.DescendantAdded:Connect(function(descendant)
            if self.Config.Toggles.XRay and descendant:IsA("BasePart") and not descendant:IsA("Terrain") then
                task.wait(0.05)
                if descendant and descendant.Parent and not self:IsCharacterOrGunPart(descendant) and descendant.Transparency < 0.95 then
                    if self.World.OriginalTransparency[descendant] == nil then
                        self.World.OriginalTransparency[descendant] = descendant.Transparency
                    end
                    descendant.Transparency = math.clamp(self.Config.Values.XRayTransparency / 100, 0, 1)
                end
            end
        end)
    end
end

function Hub:UpdateXRayTransparency()
    if not self.Config.Toggles.XRay then return end
    local targetTrans = math.clamp(self.Config.Values.XRayTransparency / 100, 0, 1)
    for part, _ in pairs(self.World.OriginalTransparency) do
        if part and part.Parent and typeof(part) == "Instance" and part:IsA("BasePart") then
            pcall(function()
                part.Transparency = targetTrans
            end)
        end
    end
end

function Hub:DisableXRay()
    if self.World.XRayConnection then
        self.World.XRayConnection:Disconnect()
        self.World.XRayConnection = nil
    end
    if self.World.OriginalTransparency then
        for part, orig in pairs(self.World.OriginalTransparency) do
            if part and part.Parent and typeof(part) == "Instance" and part:IsA("BasePart") then
                pcall(function()
                    part.Transparency = orig
                end)
            end
        end
        table.clear(self.World.OriginalTransparency)
    end
end

function Hub:SetupAntiAFK()
    local lp = self.Services.Players.LocalPlayer
    if lp then
        lp.Idled:Connect(function()
            if self.Config.Toggles.AntiAFK then
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end
        end)
    end
end

-- ==================== SUPREME VALUES & TRADE CALCULATOR ====================
function Hub:FormatNumber(num)
    local n = tonumber(num) or 0
    local sign = n < 0 and "-" or ""
    local absN = math.abs(n)
    local intPart = math.floor(absN)
    local decPart = absN - intPart

    local formatted = tostring(intPart)
    local k
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end

    if decPart >= 0.01 then
        local decStr = string.format("%.2f", decPart):sub(2)
        decStr = decStr:gsub("0+$", "")
        if decStr ~= "." then
            return sign .. formatted .. decStr
        end
    end
    return sign .. formatted
end

function Hub:CountTable(tbl)
    local c = 0
    if type(tbl) == "table" then
        for _ in pairs(tbl) do c = c + 1 end
    end
    return c
end

function Hub:GetSkinValue(skinName)
    if not skinName or type(skinName) ~= "string" then return nil end
    local clean = skinName:gsub("^%s+", ""):gsub("%s+$", "")
    if clean == "" or clean == "Loading..." or clean == "None" then return nil end
    local lowerClean = clean:lower()

    -- Explicitly blacklist default/untradable items
    if lowerClean == "default knife" or lowerClean == "default gun" or lowerClean == "defaultknife" or lowerClean == "defaultgun" then
        return nil
    end

    local alphaOnly = lowerClean:gsub("%W", "")

    local function checkVal(v)
        if type(v) == "number" and v > 0 then
            return v
        elseif type(v) == "string" and v ~= "" and v ~= "0" and v ~= "None" then
            local n = tonumber(v)
            if n then
                return n > 0 and n or nil
            end
            return v
        end
        return nil
    end

    -- 1. Check live scraped values cache
    local val = checkVal(self.ValuesSystem.CachedValues[clean])
        or checkVal(self.ValuesSystem.CachedValues[lowerClean])
        or (alphaOnly ~= "" and checkVal(self.ValuesSystem.CachedValues[alphaOnly]))
    if val then return val end

    -- Check variants with (Gun) or (Knife)
    local valGun = checkVal(self.ValuesSystem.CachedValues[clean .. " (Gun)"])
        or checkVal(self.ValuesSystem.CachedValues[lowerClean .. " (gun)"])
    local valKnife = checkVal(self.ValuesSystem.CachedValues[clean .. " (Knife)"])
        or checkVal(self.ValuesSystem.CachedValues[lowerClean .. " (knife)"])
    if valGun and not valKnife then return valGun end
    if valKnife and not valGun then return valKnife end
    if valGun and valKnife then return valGun end

    for name, v in pairs(self.ValuesSystem.CachedValues) do
        local nLow = tostring(name):lower()
        if nLow == lowerClean or (alphaOnly ~= "" and nLow:gsub("%W", "") == alphaOnly) then
            val = checkVal(v)
            if val then return val end
        end
    end

    -- 2. Check skins.json entry if available
    if self.SkinSystem and self.SkinSystem.ByName then
        local rec = self.SkinSystem.ByName[clean] or self.SkinSystem.ByName[lowerClean]
        if not rec then
            for n, r in pairs(self.SkinSystem.ByName) do
                if n:lower() == lowerClean then
                    rec = r
                    break
                end
            end
        end
        if rec and rec.meta then
            val = checkVal(rec.meta.Value)
            if val then return val end
            local iname = rec.meta.ItemName
            if iname then
                val = checkVal(self.ValuesSystem.CachedValues[iname])
                    or checkVal(self.ValuesSystem.CachedValues[iname:lower()])
                if val then return val end
            end
        end
    end

    -- 3. Check fallback database
    val = checkVal(self.ValuesSystem.FallbackValues[clean])
        or checkVal(self.ValuesSystem.FallbackValues[lowerClean])
        or (alphaOnly ~= "" and checkVal(self.ValuesSystem.FallbackValues[alphaOnly]))
    if val then return val end

    local fbGun = checkVal(self.ValuesSystem.FallbackValues[clean .. " (Gun)"])
        or checkVal(self.ValuesSystem.FallbackValues[lowerClean .. " (gun)"])
    local fbKnife = checkVal(self.ValuesSystem.FallbackValues[clean .. " (Knife)"])
        or checkVal(self.ValuesSystem.FallbackValues[lowerClean .. " (knife)"])
    if fbGun and not fbKnife then return fbGun end
    if fbKnife and not fbGun then return fbKnife end
    if fbGun and fbKnife then return fbGun end

    for name, v in pairs(self.ValuesSystem.FallbackValues) do
        local nLow = tostring(name):lower()
        if nLow == lowerClean or (alphaOnly ~= "" and nLow:gsub("%W", "") == alphaOnly) then
            val = checkVal(v)
            if val then return val end
        end
    end

    return nil
end

function Hub:GetItemNameFromSlot(slot)
    if not slot or not slot:IsA("Instance") then return nil end

    -- 1. Direct MM2 slot structure: slot.ItemName.Label.Text
    local inFrame = slot:FindFirstChild("ItemName")
    local inLabel = inFrame and inFrame:FindFirstChild("Label")
    if inLabel and inLabel:IsA("TextLabel") and inLabel.Text ~= "" and inLabel.Text ~= "..." and inLabel.Text ~= "Loading..." then
        return inLabel.Text
    end

    -- 2. Any Label or ItemName TextLabel inside slot
    for _, name in ipairs({ "Label", "ItemName", "WeaponName", "Weapon", "Item", "Title" }) do
        local lbl = slot:FindFirstChild(name, true)
        if lbl and lbl:IsA("TextLabel") and lbl.Text ~= "" and lbl.Text ~= "..." and lbl.Text ~= "Loading..." and lbl.Name ~= "ValText" and lbl.Name ~= "TotalText" and lbl.Name ~= "Amount" and lbl.Name ~= "TradeAmount" then
            return lbl.Text
        end
    end

    -- 3. Check if slot.Name itself matches a skin
    local sName = slot.Name
    if sName and sName ~= "Slot" and sName ~= "Item" and sName ~= "Template" and sName ~= "NewItem" and sName ~= "ImageButton" and sName ~= "Frame" and not sName:find("^%d+$") then
        return sName
    end

    return nil
end

function Hub:FetchValues()
    local url = self.Config.Values.ValuesURL or self.ValuesSystem.DatabaseURL
    if not url or url == "" then return end
    task.spawn(function()
        local ok, res = pcall(function()
            if game.HttpGet then
                return game:HttpGet(url)
            end
            local req = (syn and syn.request) or (http and http.request) or http_request or request
            if req then
                local resp = req({ Url = url, Method = "GET" })
                return resp and resp.Body
            end
            return nil
        end)
        if ok and res and type(res) == "string" and #res > 10 then
            local decodeOk, data = pcall(function()
                return self.Services.HttpService:JSONDecode(res)
            end)
            if decodeOk and type(data) == "table" then
                local map = data.values or (not data.entries and data) or nil
                if map and type(map) == "table" then
                    for k, v in pairs(map) do
                        local sName = tostring(k)
                        self.ValuesSystem.CachedValues[sName] = v
                        self.ValuesSystem.CachedValues[sName:lower()] = v
                        local alpha = sName:lower():gsub("%W", "")
                        if alpha ~= "" then self.ValuesSystem.CachedValues[alpha] = v end
                    end
                end
                if data.entries and type(data.entries) == "table" then
                    for _, entry in pairs(data.entries) do
                        local n = entry.name or (entry.meta and entry.meta.ItemName)
                        local v = entry.value or entry.val or (entry.meta and entry.meta.Value)
                        if n and v then
                            local sName = tostring(n)
                            self.ValuesSystem.CachedValues[sName] = v
                            self.ValuesSystem.CachedValues[sName:lower()] = v
                            local alpha = sName:lower():gsub("%W", "")
                            if alpha ~= "" then self.ValuesSystem.CachedValues[alpha] = v end

                            if entry.meta and entry.meta.ItemName then
                                local iname = tostring(entry.meta.ItemName)
                                self.ValuesSystem.CachedValues[iname] = v
                                self.ValuesSystem.CachedValues[iname:lower()] = v
                                local inAlpha = iname:lower():gsub("%W", "")
                                if inAlpha ~= "" then self.ValuesSystem.CachedValues[inAlpha] = v end
                            end
                        end
                    end
                end
                self.ValuesSystem.LastFetch = os.clock()
            end
        end
    end)
end

function Hub:AttachItemValueBadge(slot, val)
    if not slot or not slot.Parent then return end
    if slot:FindFirstChildOfClass("UIGridLayout") or slot:FindFirstChildOfClass("UIListLayout") then
        return
    end
    if slot.Name == "Container" and slot.Parent and (slot.Parent.Name == "YourOffer" or slot.Parent.Name == "TheirOffer") then
        return
    end
    local badge = slot:FindFirstChild("ValueBadge")

    if not val or val == "" or val == 0 or val == "0" then
        if badge then badge.Visible = false end
        return
    end

    local numVal = (type(val) == "number") and val or tonumber(val)
    if numVal and numVal <= 0 then
        if badge then badge.Visible = false end
        return
    end

    if not badge then
        badge = Instance.new("Frame")
        badge.Name = "ValueBadge"
        badge.Position = UDim2.new(0, 4, 0, 4)
        badge.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
        badge.BackgroundTransparency = 0.15
        badge.BorderSizePixel = 0
        badge.ZIndex = 9999
        badge.Parent = slot
        self:Corner(badge, 4)
        self:Stroke(badge, Color3.fromRGB(60, 72, 98), 1)

        local text = Instance.new("TextLabel")
        text.Name = "ValText"
        text.Size = UDim2.new(1, -4, 1, 0)
        text.Position = UDim2.new(0, 2, 0, 0)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.GothamBold
        text.TextSize = 9
        text.ZIndex = 10000
        text.Parent = badge
    end

    badge.Visible = true
    local text = badge:FindFirstChild("ValText")
    if text then
        local str
        if numVal then
            str = self:FormatNumber(numVal)
            text.TextColor3 = Color3.fromRGB(255, 215, 80) -- Gold for numeric currency
        else
            str = tostring(val)
            text.TextColor3 = Color3.fromRGB(255, 140, 140) -- Coral/Peach for tiered collectibles
        end
        text.Text = str

        local len = #str
        local w
        if len <= 4 then
            w = 26
        elseif len <= 8 then
            w = math.max(28, len * 7 + 8)
        else
            w = math.min(102, len * 5.6 + 8)
        end
        badge.Size = UDim2.new(0, math.floor(w), 0, 16)
    end
end

function Hub:FindInventoryGui()
    local lp = self.Services.Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if not pg then return nil, nil end

    local mainGui = pg:FindFirstChild("MainGUI")
    local gameGui = mainGui and mainGui:FindFirstChild("Game")
    local inv = (gameGui and gameGui:FindFirstChild("Inventory")) or pg:FindFirstChild("Inventory", true)
    if not inv or not inv.Visible then return nil, nil end

    local weapons = inv:FindFirstChild("Main") and inv.Main:FindFirstChild("Weapons")
    if not weapons or not weapons.Visible then return inv, nil end

    local items = weapons:FindFirstChild("Items")
    local contWrapper = items and items:FindFirstChild("Container")
    return inv, contWrapper
end

function Hub:FindTradeGui()
    local lp = self.Services.Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if not pg then return nil end

    local mainGui = pg:FindFirstChild("MainGUI")
    local tradeGui = pg:FindFirstChild("TradeGUI") or (mainGui and mainGui:FindFirstChild("Trade", true))
    if not tradeGui then return nil end

    local isOpen = false
    if tradeGui:IsA("ScreenGui") then
        isOpen = tradeGui.Enabled
    elseif tradeGui:IsA("GuiObject") then
        isOpen = tradeGui.Visible
        local cur = tradeGui.Parent
        while cur and cur:IsA("GuiObject") do
            if not cur.Visible then
                isOpen = false
                break
            end
            cur = cur.Parent
        end
    end
    if not isOpen then return nil end
    return tradeGui
end

function Hub:CleanInventoryBadges()
    local lp = self.Services.Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, desc in ipairs(pg:GetDescendants()) do
        if desc.Name == "ValueBadge" or desc.Name == "MM2TotalValueHeader" or desc.Name == "TotalValHeader" then
            pcall(function() desc:Destroy() end)
        end
    end
end

function Hub:CleanTradePanel()
    local lp = self.Services.Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if pg then
        for _, desc in ipairs(pg:GetDescendants()) do
            if desc.Name == "TradeStatusPanel" or desc.Name == "SV_Total" then
                pcall(function() desc:Destroy() end)
            end
        end
    end
    if self.State.Gui then
        local pnl = self.State.Gui:FindFirstChild("TradeStatusPanel")
        if pnl then pcall(function() pnl:Destroy() end) end
    end
end

function Hub:CleanValuesBadges()
    self:CleanInventoryBadges()
    self:CleanTradePanel()
end

function Hub:ProcessInventoryWindow(inv)
    if not inv or not inv:IsA("GuiObject") or not inv.Visible then
        local old = inv and inv:FindFirstChild("MM2TotalValueHeader", true)
        if old then old.Visible = false end
        return
    end

    local mainFrame = inv:FindFirstChild("Main")
    local weapons = mainFrame and mainFrame:FindFirstChild("Weapons")

    -- In ViewProfile on Profile tab, attach badges to showcase items
    if inv.Name == "ViewProfile" and (not weapons or not weapons.Visible) then
        local profileTab = mainFrame and mainFrame:FindFirstChild("Profile")
        if profileTab and profileTab.Visible then
            local showcase = profileTab:FindFirstChild("ItemShowcase", true)
            local cont = showcase and showcase:FindFirstChild("Container")
            if cont then
                for _, desc in ipairs(cont:GetDescendants()) do
                    if desc.Name == "NewItem" then
                        local itemName = self:GetItemNameFromSlot(desc)
                        if itemName and itemName ~= "" and itemName ~= "Loading..." then
                            local val = self:GetSkinValue(itemName)
                            self:AttachItemValueBadge(desc, val)
                        end
                    end
                end
            end
        end
        local old = inv:FindFirstChild("MM2TotalValueHeader", true)
        if old then old.Visible = false end
        return
    end

    if not weapons or not weapons.Visible then
        local old = inv:FindFirstChild("MM2TotalValueHeader", true)
        if old then old.Visible = false end
        return
    end

    local itemsFrame = weapons:FindFirstChild("Items")
    if not itemsFrame then return end

    local seenSlots = {}
    local totalVal = 0
    local totalItems = 0

    -- Scan all weapons across ALL tabs (Current / Season 1, Classic, Holiday / Christmas & Halloween, ItemList)
    for _, desc in ipairs(itemsFrame:GetDescendants()) do
        if desc.Name == "NewItem" and not seenSlots[desc] then
            seenSlots[desc] = true
            local itemName = self:GetItemNameFromSlot(desc)
            if itemName and itemName ~= "" and itemName ~= "Loading..." then
                local amountLbl = desc:FindFirstChild("Container") and desc.Container:FindFirstChild("Amount")
                local amtText = amountLbl and amountLbl.Text or ""
                local qty = tonumber(amtText:match("(%d+)")) or 1

                local val = self:GetSkinValue(itemName)
                self:AttachItemValueBadge(desc, val)

                local numVal = (type(val) == "number") and val or tonumber(val)
                if numVal and numVal > 0 then
                    totalVal = totalVal + (numVal * qty)
                    totalItems = totalItems + qty
                end
            end
        end
    end

    -- Parent Total Header strictly to Weapons (NO UIListLayout!), top right corner
    local header = weapons:FindFirstChild("MM2TotalValueHeader")
    if not header then
        -- Also check if accidentally inside Tabs and destroy it
        local inTabs = weapons:FindFirstChild("MM2TotalValueHeader", true)
        if inTabs and inTabs.Parent ~= weapons then inTabs:Destroy() end

        header = Instance.new("Frame")
        header.Name = "MM2TotalValueHeader"
        header.Size = UDim2.new(0, 115, 0, 24)
        header.Position = UDim2.new(1, -125, 0, 8)
        header.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
        header.BackgroundTransparency = 0.15
        header.ZIndex = 9999
        header.Parent = weapons
        self:Corner(header, 5)
        self:Stroke(header, Color3.fromRGB(55, 65, 90), 1)

        local txt = Instance.new("TextLabel")
        txt.Name = "TotalText"
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamBold
        txt.TextColor3 = Color3.fromRGB(255, 215, 80)
        txt.TextSize = 11
        txt.ZIndex = 10000
        txt.Parent = header
    end

    header.Visible = true
    local txt = header:FindFirstChild("TotalText")
    if txt then
        txt.Text = "Total: " .. self:FormatNumber(totalVal)
    end
end

function Hub:UpdateInventoryValues()
    if not self.Config.Toggles.ShowSkinValues then return end

    local lp = self.Services.Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if not pg then return end

    local mainGui = pg:FindFirstChild("MainGUI")
    local gameGui = mainGui and mainGui:FindFirstChild("Game")
    if not gameGui then return end

    -- 1. Local Player Inventory
    local localInv = gameGui:FindFirstChild("Inventory")
    if localInv then
        self:ProcessInventoryWindow(localInv)
    end

    -- 2. Inspect Other Player Inventory (ViewProfile)
    local viewProfile = gameGui:FindFirstChild("ViewProfile")
    if viewProfile and viewProfile.Visible then
        self:ProcessInventoryWindow(viewProfile)
    else
        local oldVp = viewProfile and viewProfile:FindFirstChild("MM2TotalValueHeader", true)
        if oldVp then oldVp.Visible = false end
    end

    -- 3. Inspect Other Player Inventory (Inventory2)
    local inv2 = gameGui:FindFirstChild("Inventory2")
    if inv2 and inv2.Visible then
        self:ProcessInventoryWindow(inv2)
    else
        local oldInv2 = inv2 and inv2:FindFirstChild("MM2TotalValueHeader", true)
        if oldInv2 then oldInv2.Visible = false end
    end
end

function Hub:UpdateTradeValues()
    if not self.Config.Toggles.ShowSkinValues then return end

    local tradeGui = self:FindTradeGui()
    if not tradeGui then
        if self.State.Gui then
            local pnl = self.State.Gui:FindFirstChild("TradeStatusPanel")
            if pnl then pnl.Visible = false end
        end
        local lp = self.Services.Players.LocalPlayer
        local pg = lp and lp:FindFirstChild("PlayerGui")
        if pg then
            for _, pnl in ipairs(pg:GetDescendants()) do
                if pnl.Name == "TradeStatusPanel" or pnl.Name == "SV_Total" then
                    pnl.Visible = false
                end
            end
        end
        return
    end

    local container = tradeGui:FindFirstChild("Container") or tradeGui
    local trade = container:FindFirstChild("Trade", true) or container
    local yourOffer = trade:FindFirstChild("YourOffer", true) or trade:FindFirstChild("MyOffer", true)
    local theirOffer = trade:FindFirstChild("TheirOffer", true) or trade:FindFirstChild("OtherOffer", true)

    local function processOffer(offer)
        if not offer then return 0 end
        local offerVal = 0
        local cont = offer:FindFirstChild("Container")

        -- Remove any misplaced badge directly under cont to avoid breaking UIGridLayout
        if cont then
            for _, bad in ipairs(cont:GetChildren()) do
                if bad.Name == "ValueBadge" or bad.Name == "SV_Value" then
                    pcall(function() bad:Destroy() end)
                end
            end
        end

        local slots = {}
        if cont then
            -- 1. Strictly locate NewItem1..NewItem12
            for i = 1, 12 do
                local card = cont:FindFirstChild("NewItem" .. i)
                if card then
                    slots[#slots + 1] = card
                end
            end
            -- 2. Fallback: GuiObjects inside cont that are NOT layouts or badges
            if #slots == 0 then
                for _, ch in ipairs(cont:GetChildren()) do
                    if ch:IsA("GuiObject") and not ch:IsA("UILayout") and ch.Name ~= "ValueBadge" and ch.Name ~= "SV_Value" then
                        slots[#slots + 1] = ch
                    end
                end
            end
        end

        if #slots == 0 then
            for _, ch in ipairs(offer:GetChildren()) do
                if ch:IsA("GuiObject") and not ch:IsA("UILayout") and ch.Name ~= "Container" and ch.Name ~= "Title" and ch.Name ~= "Username" and ch.Name ~= "ValueBadge" and ch.Name ~= "SV_Total" then
                    slots[#slots + 1] = ch
                end
            end
        end

        for _, slot in ipairs(slots) do
            local badge = slot:FindFirstChild("ValueBadge")
            if slot.Visible then
                local itemName = self:GetItemNameFromSlot(slot)
                if itemName and itemName ~= "" and itemName ~= "Loading..." and itemName ~= "..." then
                    local inner = slot:FindFirstChild("Container")
                    local amtLbl = (inner and inner:FindFirstChild("Amount")) or slot:FindFirstChild("Amount")
                    local amtText = amtLbl and amtLbl.Text or ""
                    local qty = tonumber(amtText:match("(%d+)")) or 1

                    local val = self:GetSkinValue(itemName)
                    self:AttachItemValueBadge(slot, val)

                    local numVal = (type(val) == "number") and val or tonumber(val)
                    if numVal and numVal > 0 then
                        offerVal = offerVal + (numVal * qty)
                    end
                else
                    if badge then badge.Visible = false end
                end
            else
                if badge then badge.Visible = false end
            end
        end

        -- Side total label (SV_Total) attached directly to offer Frame (which has no layout)
        local svTotal = offer:FindFirstChild("SV_Total")
        if offerVal > 0 then
            if not svTotal then
                svTotal = Instance.new("TextLabel")
                svTotal.Name = "SV_Total"
                svTotal.BackgroundTransparency = 1
                svTotal.BorderSizePixel = 0
                svTotal.Font = Enum.Font.GothamBold
                svTotal.TextColor3 = Color3.fromRGB(255, 215, 80)
                svTotal.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                svTotal.TextStrokeTransparency = 0.2
                svTotal.TextSize = 13
                svTotal.TextXAlignment = Enum.TextXAlignment.Left
                svTotal.ZIndex = 50
                svTotal.Parent = offer
            end
            local title = offer:FindFirstChild("Title")
            if title and title:IsA("TextLabel") and title.AbsoluteSize.X > 5 then
                local left = (title.AbsolutePosition.X - offer.AbsolutePosition.X) + title.TextBounds.X + 12
                svTotal.Position = UDim2.new(0, math.floor(left), title.Position.Y.Scale, title.Position.Y.Offset)
                svTotal.Size = UDim2.new(0.4, 0, 0, math.max(18, title.AbsoluteSize.Y))
            else
                svTotal.Position = UDim2.new(0.05, 0, 0, 8)
                svTotal.Size = UDim2.new(0.4, 0, 0, 20)
            end
            svTotal.Text = "Val: " .. self:FormatNumber(offerVal)
            svTotal.Visible = true
        else
            if svTotal then svTotal.Visible = false end
        end

        return offerVal
    end

    local yourVal = processOffer(yourOffer)
    local theirVal = processOffer(theirOffer)

    -- Safe parent for comparison banner (uses Hub ScreenGui so MM2 trade layout is never disturbed)
    local safeParent = self.State.Gui or self:GetSafeParent()
    local panel = safeParent:FindFirstChild("TradeStatusPanel")
    if not panel then
        panel = Instance.new("Frame")
        panel.Name = "TradeStatusPanel"
        panel.Size = UDim2.new(0, 520, 0, 42)
        panel.Position = UDim2.new(0.5, -260, 0, 10)
        panel.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
        panel.ZIndex = 9999
        panel.Parent = safeParent
        self:Corner(panel, 8)
        self:Stroke(panel, Color3.fromRGB(40, 45, 62), 1)

        local yourLbl = Instance.new("TextLabel")
        yourLbl.Name = "YourValLabel"
        yourLbl.Position = UDim2.new(0, 15, 0, 0)
        yourLbl.Size = UDim2.new(0.32, 0, 1, 0)
        yourLbl.BackgroundTransparency = 1
        yourLbl.Font = Enum.Font.GothamBold
        yourLbl.TextColor3 = Color3.fromRGB(240, 243, 250)
        yourLbl.TextSize = 12
        yourLbl.TextXAlignment = Enum.TextXAlignment.Left
        yourLbl.ZIndex = 10000
        yourLbl.Parent = panel

        local verdictLbl = Instance.new("TextLabel")
        verdictLbl.Name = "VerdictLabel"
        verdictLbl.Position = UDim2.new(0.33, 0, 0, 0)
        verdictLbl.Size = UDim2.new(0.34, 0, 1, 0)
        verdictLbl.BackgroundTransparency = 1
        verdictLbl.Font = Enum.Font.GothamBold
        verdictLbl.TextSize = 13
        verdictLbl.TextXAlignment = Enum.TextXAlignment.Center
        verdictLbl.ZIndex = 10000
        verdictLbl.Parent = panel

        local theirLbl = Instance.new("TextLabel")
        theirLbl.Name = "TheirValLabel"
        theirLbl.Position = UDim2.new(0.68, 0, 0, 0)
        theirLbl.Size = UDim2.new(0.32, -15, 1, 0)
        theirLbl.BackgroundTransparency = 1
        theirLbl.Font = Enum.Font.GothamBold
        theirLbl.TextColor3 = Color3.fromRGB(240, 243, 250)
        theirLbl.TextSize = 12
        theirLbl.TextXAlignment = Enum.TextXAlignment.Right
        theirLbl.ZIndex = 10000
        theirLbl.Parent = panel
    end

    panel.Visible = true
    local yLabel = panel:FindFirstChild("YourValLabel")
    local vLabel = panel:FindFirstChild("VerdictLabel")
    local tLabel = panel:FindFirstChild("TheirValLabel")

    if yLabel then yLabel.Text = "You: " .. self:FormatNumber(yourVal) .. " Val" end
    if tLabel then tLabel.Text = "Them: " .. self:FormatNumber(theirVal) .. " Val" end

    if vLabel then
        local diff = theirVal - yourVal
        if yourVal == 0 and theirVal == 0 then
            vLabel.Text = "Add items to calculate"
            vLabel.TextColor3 = self.Theme.TextDim
        elseif diff > 0 then
            vLabel.Text = "WIN (+" .. self:FormatNumber(diff) .. ")"
            vLabel.TextColor3 = Color3.fromRGB(50, 230, 100)
        elseif diff < 0 then
            vLabel.Text = "LOSS (" .. self:FormatNumber(diff) .. ")"
            vLabel.TextColor3 = Color3.fromRGB(255, 70, 80)
        else
            vLabel.Text = "FAIR (0)"
            vLabel.TextColor3 = Color3.fromRGB(255, 230, 0)
        end
    end
end


-- ==================== ADVANCED SKIN CHANGER (SKINS.JSON) ====================
local skinPropNope = {
    Anchored = true, Massless = true, CanCollide = true, CanQuery = true, CanTouch = true,
    Locked = true, Size = true, MeshId = true, MeshSize = true, Part0 = true, Part1 = true,
    Playing = true, TimeLength = true, IsLoaded = true, IsPlaying = true,
}

local skinFxClasses = {
    Attachment = true, Sound = true, ParticleEmitter = true, Beam = true, Trail = true,
    Decal = true, Texture = true, Fire = true, Smoke = true, Sparkles = true,
    PointLight = true, SpotLight = true, SurfaceLight = true, Highlight = true,
}

local skinOnHandleClasses = { Attachment = true, Sound = true, Beam = true }

function Hub:DecodeSkinEnum(raw)
    local group, item = string.match(raw, "^Enum%.([%w_]+)%.([%w_]+)$")
    if not group then return nil end
    local ok, val = pcall(function() return Enum[group][item] end)
    return ok and val or nil
end

function Hub:DecodeSkinProperty(current, raw)
    local k = type(raw)
    if k == "number" or k == "boolean" then return raw end
    local want = typeof(current)
    if k == "string" then
        if want == "EnumItem" then return self:DecodeSkinEnum(raw) end
        return raw
    end
    if k ~= "table" then return nil end

    if want == "Vector3" then
        return Vector3.new(raw[1], raw[2], raw[3])
    elseif want == "Vector2" then
        return Vector2.new(raw[1], raw[2])
    elseif want == "Color3" then
        return Color3.new(raw[1], raw[2], raw[3])
    elseif want == "NumberRange" then
        return NumberRange.new(raw[1], raw[2])
    elseif want == "CFrame" then
        return CFrame.new(table.unpack(raw))
    elseif want == "NumberSequence" then
        local keys = {}
        for i = 1, #raw do
            local pt = raw[i]
            keys[i] = NumberSequenceKeypoint.new(pt.t, pt.v, pt.e or 0)
        end
        if #keys < 2 then return NumberSequence.new(keys[1] and keys[1].Value or 0) end
        return NumberSequence.new(keys)
    elseif want == "ColorSequence" then
        local keys = {}
        for i = 1, #raw do
            local pt = raw[i]
            local rgb = pt.c
            keys[i] = ColorSequenceKeypoint.new(pt.t, Color3.new(rgb[1], rgb[2], rgb[3]))
        end
        if #keys < 2 then return ColorSequence.new(keys[1] and keys[1].Value or Color3.new(1, 1, 1)) end
        return ColorSequence.new(keys)
    end
    return nil
end

function Hub:ApplySkinProps(inst, props)
    if type(props) ~= "table" then return inst end
    for key, raw in pairs(props) do
        if not skinPropNope[key] then
            local ok, curr = pcall(function() return inst[key] end)
            if ok then
                local val = self:DecodeSkinProperty(curr, raw)
                if val ~= nil then
                    pcall(function() inst[key] = val end)
                end
            end
        end
    end
    return inst
end

function Hub:RegisterSkinGarbage(owner, inst)
    if not owner or not inst then return inst end
    local list = self.SkinSystem.Musor[owner]
    if not list then
        list = {}
        self.SkinSystem.Musor[owner] = list
    end
    list[#list + 1] = inst
    return inst
end

function Hub:ClearSkinGarbage(owner)
    local list = self.SkinSystem.Musor[owner]
    if not list then return end
    for i = #list, 1, -1 do
        local inst = list[i]
        if inst then
            pcall(function() inst:Destroy() end)
        end
        list[i] = nil
    end
end

function Hub:BackupSkinProp(inst, data)
    if not inst then return end
    if not self.SkinSystem.Saved[inst] then
        self.SkinSystem.Saved[inst] = data
    end
end

function Hub:CreateSkinPart(rec)
    local root = rec.display and rec.display.root
    local props = root and root.props
    if not props then return nil end

    if props.MeshId then
        local numId = tonumber(string.match(tostring(props.MeshId), "(%d+)"))
        if numId then
            local base = self.SkinSystem.Meshes[numId]
            if not base then
                local ok, mesh
                if Content and Content.fromAssetId and self.Services.AssetService and self.Services.AssetService.CreateMeshPartAsync then
                    ok, mesh = pcall(self.Services.AssetService.CreateMeshPartAsync, self.Services.AssetService, Content.fromAssetId(numId))
                end
                if not ok or not mesh then
                    local part = Instance.new("Part")
                    local sm = Instance.new("SpecialMesh")
                    sm.MeshType = Enum.MeshType.FileMesh
                    sm.MeshId = tostring(props.MeshId)
                    if props.TextureID then sm.TextureId = tostring(props.TextureID) end
                    sm.Parent = part
                    mesh = part
                end
                mesh.Parent = nil
                self.SkinSystem.Meshes[numId] = mesh
                base = mesh
            end
            local part = base:Clone()
            self:ApplySkinProps(part, props)
            if type(props.Size) == "table" then
                part.Size = Vector3.new(props.Size[1], props.Size[2], props.Size[3])
            end
            part.Anchored = false
            part.Massless = true
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.Locked = true
            return part
        end
    end

    local specialNode = nil
    if type(rec.display and rec.display.nodes) == "table" then
        for _, n in ipairs(rec.display.nodes) do
            if n.class == "SpecialMesh" and not n.parent and n.props and n.props.MeshId then
                specialNode = n
                break
            end
        end
    end

    if specialNode then
        local part = Instance.new("Part")
        self:ApplySkinProps(part, props)
        if type(props.Size) == "table" then
            part.Size = Vector3.new(props.Size[1], props.Size[2], props.Size[3])
        end
        part.Anchored = false
        part.Massless = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Locked = true

        local mesh = Instance.new("SpecialMesh")
        mesh.Name = specialNode.name or "Mesh"
        mesh.MeshType = Enum.MeshType.FileMesh
        self:ApplySkinProps(mesh, specialNode.props)
        pcall(function() mesh.MeshId = specialNode.props.MeshId end)
        mesh.Parent = part
        return part
    end

    return nil
end

function Hub:ApplySkinFX(rec, owner, body, handle)
    local paths = {}
    local sounds = {}
    local nodes = rec.display and rec.display.nodes
    if type(nodes) ~= "table" then return sounds end

    for _, node in ipairs(nodes) do
        local class = node.class
        if skinFxClasses[class] then
            local parent = node.parent and paths[node.parent]
            if not parent then
                parent = (skinOnHandleClasses[class] and handle) or body
            end
            local inst = Instance.new(class)
            inst.Name = node.name or class
            self:ApplySkinProps(inst, node.props)
            inst.Parent = parent

            if node.tags then
                for _, t in ipairs(node.tags) do
                    pcall(self.Services.CollectionService.AddTag, self.Services.CollectionService, inst, t)
                end
            end
            if node.attrs then
                for k, v in pairs(node.attrs) do
                    pcall(function() inst:SetAttribute(k, v) end)
                end
            end

            if node.path then paths[node.path] = inst end
            if class == "Sound" then sounds[node.name] = inst end
            self:RegisterSkinGarbage(owner, inst)
        end
    end
    return sounds
end

function Hub:FindToolBySlot(slot)
    local lp = self.Services.Players.LocalPlayer
    local char = lp and lp.Character
    local tool = char and char:FindFirstChild(slot)
    if tool and tool:IsA("Tool") then return tool end
    local bp = lp and lp:FindFirstChildOfClass("Backpack")
    tool = bp and bp:FindFirstChild(slot)
    if tool and tool:IsA("Tool") then return tool end
    return nil
end

function Hub:FindDisplayPedestal(slot)
    local lp = self.Services.Players.LocalPlayer
    local char = lp and lp.Character
    local ref = char and char:FindFirstChild("DisplayRef" .. slot)
    local part = ref and ref.Value
    if part and part.Parent then return part end
    return nil
end

function Hub:ApplySkinToTool(rec)
    local slot = rec.kind or (rec.meta and rec.meta.ItemType) or "Knife"
    local tool = self:FindToolBySlot(slot)
    if not tool then return false end
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
    if not handle then return false end

    self:BackupSkinProp(tool, { grip = tool.Grip })
    self:BackupSkinProp(handle, {
        size = handle.Size,
        trans = handle.Transparency,
        mod = handle.LocalTransparencyModifier,
    })
    self:ClearSkinGarbage(tool)

    local body = self:CreateSkinPart(rec)
    if not body then return false end

    body.Name = "CustomSkinMesh"
    body.Parent = tool
    body.CFrame = handle.CFrame
    self:RegisterSkinGarbage(tool, body)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = body
    weld.Parent = body
    self:RegisterSkinGarbage(tool, weld)

    if rec.display and rec.display.root and rec.display.root.props and rec.display.root.props.Size then
        local sz = rec.display.root.props.Size
        handle.Size = Vector3.new(sz[1], sz[2], sz[3])
    end
    handle.LocalTransparencyModifier = 1
    pcall(function() handle.Transparency = 1 end)

    local toolRoot = rec.tool and rec.tool.root
    local grip = toolRoot and toolRoot.props and toolRoot.props.Grip
    if grip and #grip >= 12 then
        pcall(function()
            tool.Grip = CFrame.new(table.unpack(grip))
        end)
    end

    local sounds = self:ApplySkinFX(rec, tool, body, handle)
    if next(sounds) then
        for _, inst in ipairs(tool:GetDescendants()) do
            if inst:IsA("Sound") and not sounds[inst.Name] then
                self:BackupSkinProp(inst, { volume = inst.Volume })
                pcall(function() inst.Volume = 0 end)
            end
        end
    end
    return true
end

function Hub:ApplySkinToDisplay(rec)
    if not self.SkinSystem.LobbyPedestal then return false end
    local slot = rec.kind or (rec.meta and rec.meta.ItemType) or "Knife"
    local display = self:FindDisplayPedestal(slot)
    if not display then return false end

    self:BackupSkinProp(display, {
        trans = display.Transparency,
        mod = display.LocalTransparencyModifier,
    })
    self:ClearSkinGarbage(display)

    display.LocalTransparencyModifier = 1
    pcall(function() display.Transparency = 1 end)

    local body = self:CreateSkinPart(rec)
    if not body then return false end

    body.Name = "CustomSkinMesh"
    body.Parent = display
    body.CFrame = display.CFrame
    self:RegisterSkinGarbage(display, body)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = display
    weld.Part1 = body
    weld.Parent = body
    self:RegisterSkinGarbage(display, weld)

    self:ApplySkinFX(rec, display, body, body)
    return true
end

function Hub:EquipSkin(name)
    local rec = self.SkinSystem.ByName[name]
    if not rec then
        return false
    end

    local slot = rec.kind or (rec.meta and rec.meta.ItemType) or "Knife"
    self.SkinSystem.Picked[slot] = rec
    if slot == "Knife" then
        self.SkinSystem.CurrentKnife = name
    else
        self.SkinSystem.CurrentGun = name
    end

    pcall(function()
        local rep = self.Services.ReplicatedStorage
        local ok, profile = pcall(require, rep.Modules.ProfileData)
        if ok and profile and profile.Weapons and profile.Weapons.Equipped then
            profile.Weapons.Equipped[slot] = rec.name
        end
        rep.Remotes.Inventory.Equip:FireServer(rec.name, "Weapons")
    end)

    task.wait(0.15)
    self:ApplySkinToDisplay(rec)
    return self:ApplySkinToTool(rec)
end

function Hub:UnequipSkin(slot)
    self.SkinSystem.Picked[slot] = nil
    if slot == "Knife" then
        self.SkinSystem.CurrentKnife = "None"
    else
        self.SkinSystem.CurrentGun = "None"
    end

    local tool = self:FindToolBySlot(slot)
    local display = self:FindDisplayPedestal(slot)
    if tool then self:ClearSkinGarbage(tool) end
    if display then self:ClearSkinGarbage(display) end

    for inst, data in pairs(self.SkinSystem.Saved) do
        if inst and inst.Parent then
            if data.grip then pcall(function() inst.Grip = data.grip end) end
            if data.size then pcall(function() inst.Size = data.size end) end
            if data.trans then pcall(function() inst.Transparency = data.trans end) end
            if data.mod then pcall(function() inst.LocalTransparencyModifier = data.mod end) end
            if data.volume then pcall(function() inst.Volume = data.volume end) end
        end
        self.SkinSystem.Saved[inst] = nil
    end
end

function Hub:ProcessSkinDatabase(data)
    table.clear(self.SkinSystem.ByName)
    table.clear(self.SkinSystem.ByRarity)
    table.clear(self.SkinSystem.BySlot.Knife)
    table.clear(self.SkinSystem.BySlot.Gun)

    local total = 0
    local entries = data.entries or data
    for _, rec in pairs(entries) do
        if type(rec) == "table" then
            local meta = rec.meta
        local name = rec.name or (meta and meta.ItemName)
        local slot = rec.kind or (meta and meta.ItemType)
        local bucket = slot and self.SkinSystem.BySlot[slot]
        if name and rec.display and bucket then
            bucket[#bucket + 1] = rec
            self.SkinSystem.ByName[name] = rec
            if meta and meta.ItemName and meta.ItemName ~= name then
                self.SkinSystem.ByName[meta.ItemName] = rec
            end

            -- Live values: extract value from skins.json (single unified database)
            local val = meta and (meta.Value or meta.Price or meta.val)
            if val and tonumber(val) then
                local numVal = tonumber(val)
                self.ValuesSystem.CachedValues[name] = numVal
                if meta and meta.ItemName then
                    self.ValuesSystem.CachedValues[meta.ItemName] = numVal
                end
            end

            local rarity = (meta and meta.Rarity) or "Unknown"
            local rares = self.SkinSystem.ByRarity[rarity]
            if not rares then
                rares = {}
                self.SkinSystem.ByRarity[rarity] = rares
            end
            rares[#rares + 1] = rec
            total = total + 1
        end
        end
    end
    self.SkinSystem.Loaded = true
    return total
end

function Hub:LoadSkinDatabase()
    local content = nil
    -- 1. Try local file skins.json
    local okFile, localContent = pcall(function()
        if readfile and (not isfile or isfile("skins.json")) then
            return readfile("skins.json")
        end
    end)
    if okFile and type(localContent) == "string" and #localContent > 1000 then
        content = localContent
    end

    -- 2. Try URL
    if not content then
        local url = self.SkinSystem.DatabaseURL
        if url and url ~= "" then
            local okNet, res = pcall(function()
                if game.HttpGet then
                    return game:HttpGet(url)
                end
            end)
            if okNet and type(res) == "string" and #res > 1000 then
                content = res
            end
        end
    end

    -- 3. Parse JSON
    if content then
        local okParse, data = pcall(self.Services.HttpService.JSONDecode, self.Services.HttpService, content)
        if okParse and type(data) == "table" then
            self:ProcessSkinDatabase(data)
            return true
        end
    end
    return false
end

-- ==================== MAPS & VOTE DUPLICATOR ====================
function Hub:GetLobby()
    return self.Services.Workspace:FindFirstChild("RegularLobby") or self.Services.Workspace:FindFirstChild("Lobby")
end

function Hub:IsVotingActive()
    local lobby = self:GetLobby()
    if not lobby then return false end
    if self.Services.Workspace:FindFirstChild("Map") or self.Services.Workspace:FindFirstChild("Normal") then
        return false
    end
    local pad = lobby:FindFirstChild("VotePad1")
    if not pad then return false end
    local vig = pad:FindFirstChild("VoteInfoGui")
    if vig then
        if vig:IsA("BillboardGui") or vig:IsA("SurfaceGui") then
            if not vig.Enabled then return false end
        end
        local mn = vig:FindFirstChild("MapName", true)
        if mn and mn:IsA("TextLabel") then
            local t = mn.Text:gsub("%s+", "")
            if t == "" or t == "Map" then return false end
        end
    end
    return true
end

function Hub:ScanMaps()
    local lobby = self:GetLobby()
    local pads = { "VotePad1", "VotePad2", "VotePad3" }
    local result = {}

    for _, padName in ipairs(pads) do
        local pad = lobby and lobby:FindFirstChild(padName)
        local mapName = ""
        local votes = ""
        local imageId = ""

        if pad then
            local vig = pad:FindFirstChild("VoteInfoGui")
            if vig then
                local mn = vig:FindFirstChild("MapName", true)
                if mn and mn:IsA("TextLabel") and mn.Text ~= "" then mapName = mn.Text end
                local vt = vig:FindFirstChild("Votes", true)
                if vt and vt:IsA("TextLabel") and vt.Text ~= "" then votes = vt.Text end
            end

            local mig = pad:FindFirstChild("MapInfoGui")
            if mig then
                local mi = mig:FindFirstChild("MapIcon", true)
                if mi and mi:IsA("ImageLabel") and mi.Image ~= "" then imageId = mi.Image end
            end

            local voteIcons = lobby:FindFirstChild("VoteIcons")
            if voteIcons then
                local viPad = voteIcons:FindFirstChild(padName)
                if viPad then
                    local img = viPad:FindFirstChildWhichIsA("ImageLabel", true)
                    if img and img.Image ~= "" then imageId = img.Image end
                end
            end
        end

        if not self.Maps.Cached[padName] then
            self.Maps.Cached[padName] = { MapName = padName, Votes = "0", Image = Icons.MapFallback }
        end
        if mapName ~= "" and mapName ~= "Unknown Map" then
            self.Maps.Cached[padName].MapName = mapName
        end
        if votes ~= "" then
            self.Maps.Cached[padName].Votes = votes
        end
        if imageId ~= "" then
            self.Maps.Cached[padName].Image = imageId
        end

        table.insert(result, {
            PadName = padName,
            Pad = pad,
            MapName = self.Maps.Cached[padName].MapName,
            Votes = self.Maps.Cached[padName].Votes,
            Image = self.Maps.Cached[padName].Image,
        })
    end

    return result
end

function Hub:TeleportToPad(padName)
    -- Телепорт строго во время фазы голосования
    if not self:IsVotingActive() then return end

    local lobby = self:GetLobby()
    local pad = lobby and lobby:FindFirstChild(padName)
    if not pad then return end

    local targetPart = pad:FindFirstChild("Pad") or pad:FindFirstChildWhichIsA("BasePart")
    local lp = self.Services.Players.LocalPlayer
    local char = lp.Character
    local root = self:GetRoot(char)

    if targetPart and root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = targetPart.CFrame + Vector3.new(0, 3.5, 0)
    end
end

function Hub:StartVoteDuplicator()
    if self.Maps.DupRunning then return end
    self.Maps.DupRunning = true

    task.spawn(function()
        while self.Config.Toggles.VoteDup and self.State.Gui and self.State.Gui.Parent do
            if not self:IsVotingActive() then
                -- Голосования нет -> статус "Ожидание голосования..."
                if self.Maps.StatusLabel then
                    self.Maps.StatusLabel.Text = "Статус: Ожидание голосования..."
                    self.Maps.StatusLabel.TextColor3 = self.Theme.TextMuted
                end
                task.wait(0.5)
            else
                local padName = self.Maps.SelectedPad
                if not padName then
                    -- Голосование идет, но игрок еще не нажал на карту -> ждем выбора карты
                    if self.Maps.StatusLabel then
                        self.Maps.StatusLabel.Text = "Статус: Нажмите на карту ниже для запуска дюпа"
                        self.Maps.StatusLabel.TextColor3 = self.Theme.HeroYellow
                    end
                    task.wait(0.3)
                else
                    self:UpdateMapCardsHighlight()

                    if self.Maps.StatusLabel then
                        local mapName = (self.Maps.Cached[padName] and self.Maps.Cached[padName].MapName) or padName
                        self.Maps.StatusLabel.Text = "Статус: Дюп голосов для " .. tostring(mapName) .. "..."
                        self.Maps.StatusLabel.TextColor3 = self.Theme.InnocentGreen
                    end

                    local lp = self.Services.Players.LocalPlayer
                    local char = lp.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local root = self:GetRoot(char)

                    if root and hum and hum.Health > 0 then
                        self:TeleportToPad(padName)
                        task.wait(0.25)

                        if self.Config.Toggles.VoteDup and self:IsVotingActive() and self.Maps.SelectedPad == padName then
                            hum.Health = 0
                        end
                    end

                -- Ожидание возрождения с защитой от зависания
                local deadChar = char
                local timeout = 0
                while self.Config.Toggles.VoteDup and self:IsVotingActive() and timeout < 35 do
                    local curChar = lp.Character
                    if curChar and curChar ~= deadChar and curChar:FindFirstChild("HumanoidRootPart") then
                        break
                    end
                    task.wait(0.1)
                    timeout = timeout + 1
                end
                task.wait(0.2)
            end
        end
    end
    self.Maps.DupRunning = false
end)
end

function Hub:UpdateMapCardsHighlight()
    for padName, cardData in pairs(self.Maps.Cards) do
        if cardData and cardData.CardStroke then
            if self.Maps.SelectedPad == padName then
                cardData.CardStroke.Color = self.Theme.InnocentGreen
                cardData.CardStroke.Thickness = 2
            else
                cardData.CardStroke.Color = self.Theme.Border
                cardData.CardStroke.Thickness = 1
            end
        end
    end
end

-- ==================== UI BUILDER ====================
function Hub:Init()
    local parentTarget = self:GetSafeParent()
    local old = parentTarget:FindFirstChild("Dynamic_Hub_MM2")
    if old then old:Destroy() end

    local screen = Instance.new("ScreenGui")
    screen.Name = "Dynamic_Hub_MM2"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = parentTarget
    self.State.Gui = screen

    -- Тень окна
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "DropShadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(0, 660, 0, 580)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.35
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = screen
    self.State.Shadow = shadow

    -- Главное окно
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Size = UDim2.new(0, 620, 0, 540)
    main.BackgroundColor3 = self.Theme.MainBg
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screen
    self.State.MainFrame = main
    self:Corner(main, 14)
    self:Stroke(main, self.Theme.Border, 1)

    -- ШАПКА ОКНА (DRAG HEADER)
    local topbar = Instance.new("Frame")
    topbar.Name = "TopBar"
    topbar.Size = UDim2.new(1, 0, 0, 46)
    topbar.BackgroundColor3 = self.Theme.TopBarBg
    topbar.BorderSizePixel = 0
    topbar.Parent = main
    self.State.TopBar = topbar

    local topBottomLine = Instance.new("Frame")
    topBottomLine.Size = UDim2.new(1, 0, 0, 1)
    topBottomLine.Position = UDim2.new(0, 0, 1, -1)
    topBottomLine.BackgroundColor3 = self.Theme.Border
    topBottomLine.BorderSizePixel = 0
    topBottomLine.Parent = topbar

    local logoText = Instance.new("TextLabel")
    logoText.Name = "DynamicLogo"
    logoText.Position = UDim2.new(0, 18, 0, 0)
    logoText.Size = UDim2.new(0, 85, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Font = Enum.Font.GothamBold
    logoText.Text = "DYNAMIC"
    logoText.TextColor3 = self.Theme.TextPrimary
    logoText.TextSize = 16
    logoText.TextXAlignment = Enum.TextXAlignment.Left
    logoText.Parent = topbar

    local badge = Instance.new("Frame")
    badge.Name = "ProBadge"
    badge.Size = UDim2.new(0, 56, 0, 18)
    badge.Position = UDim2.new(0, 106, 0.5, -9)
    badge.BackgroundColor3 = Color3.fromRGB(24, 34, 56)
    badge.Parent = topbar
    self:Corner(badge, 4)
    self:Stroke(badge, Color3.fromRGB(50, 85, 150), 1)

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Font = Enum.Font.GothamBold
    badgeText.Text = "MM2 PRO"
    badgeText.TextColor3 = self.Theme.Accent
    badgeText.TextSize = 10
    badgeText.Parent = badge

    -- Кнопка закрытия
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -36, 0.5, -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
    closeBtn.Image = Icons.Close
    closeBtn.ImageColor3 = self.Theme.TextDim
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = topbar
    self:Corner(closeBtn, 6)
    self:Stroke(closeBtn, self.Theme.Border, 1)

    closeBtn.MouseEnter:Connect(function()
        self:Tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(220, 50, 70), ImageColor3 = Color3.fromRGB(255, 255, 255) }, 0.2)
    end)
    closeBtn.MouseLeave:Connect(function()
        self:Tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(26, 30, 42), ImageColor3 = self.Theme.TextDim }, 0.2)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        self:ToggleMenu(false)
    end)

    -- БОКОВАЯ ПАНЕЛЬ
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Position = UDim2.new(0, 0, 0, 46)
    sidebar.Size = UDim2.new(0, 140, 1, -46)
    sidebar.BackgroundColor3 = self.Theme.SidebarBg
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main

    local sideRightLine = Instance.new("Frame")
    sideRightLine.Size = UDim2.new(0, 1, 1, 0)
    sideRightLine.Position = UDim2.new(1, -1, 0, 0)
    sideRightLine.BackgroundColor3 = self.Theme.Border
    sideRightLine.BorderSizePixel = 0
    sideRightLine.Parent = sidebar

    local tabListContainer = Instance.new("Frame")
    tabListContainer.Size = UDim2.new(1, -16, 1, -20)
    tabListContainer.Position = UDim2.new(0, 8, 0, 10)
    tabListContainer.BackgroundTransparency = 1
    tabListContainer.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabListContainer

    -- ОБЛАСТЬ КОНТЕНТА
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Position = UDim2.new(0, 140, 0, 46)
    contentArea.Size = UDim2.new(1, -140, 1, -46)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent = main

    local tabDefinitions = {
        { Name = "Combat", Icon = Icons.Combat, LayoutOrder = 1 },
        { Name = "Visuals", Icon = Icons.Visuals, LayoutOrder = 2 },
        { Name = "Misc", Icon = Icons.Misc, LayoutOrder = 3 },
        { Name = "Maps", Icon = Icons.Maps, LayoutOrder = 4 },
        { Name = "Animation", Icon = Icons.Animation, LayoutOrder = 5 },
        { Name = "Config", Icon = Icons.Config, LayoutOrder = 6 },
    }

    for _, def in ipairs(tabDefinitions) do
        self:CreateTabButton(tabListContainer, contentArea, def)
    end

    self:BuildCombatTab(self.State.Tabs["Combat"])
    self:BuildVisualsTab(self.State.Tabs["Visuals"])
    self:BuildMiscTab(self.State.Tabs["Misc"])
    self:BuildMapsTab(self.State.Tabs["Maps"])
    self:BuildAnimationTab(self.State.Tabs["Animation"])
    self:BuildConfigTab(self.State.Tabs["Config"])

    self:SwitchTab("Combat")
    self:SetupWindowDragging()
    self:SetupKeybinds()
    self:HookSilentAim()
    self:StartMainLoops()
end

function Hub:CreateTabButton(sidebarContainer, contentArea, def)
    local name = def.Name
    local btn = Instance.new("TextButton")
    btn.Name = "TabBtn_" .. name
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = def.LayoutOrder
    btn.Parent = sidebarContainer
    self:Corner(btn, 8)

    local activeInd = Instance.new("Frame")
    activeInd.Name = "ActiveInd"
    activeInd.Size = UDim2.new(0, 3, 0.6, 0)
    activeInd.Position = UDim2.new(0, 2, 0.2, 0)
    activeInd.BackgroundColor3 = self.Theme.Accent
    activeInd.BorderSizePixel = 0
    activeInd.Visible = false
    activeInd.Parent = btn
    self:Corner(activeInd, 2)

    local icon = Instance.new("ImageLabel")
    icon.Name = "TabIcon"
    icon.Size = UDim2.new(0, 18, 0, 18)
    icon.Position = UDim2.new(0, 12, 0.5, -9)
    icon.BackgroundTransparency = 1
    icon.Image = def.Icon
    icon.ImageColor3 = self.Theme.TextDim
    icon.Parent = btn

    local title = Instance.new("TextLabel")
    title.Name = "TabTitle"
    title.Position = UDim2.new(0, 38, 0, 0)
    title.Size = UDim2.new(1, -42, 1, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamMedium
    title.Text = name
    title.TextColor3 = self.Theme.TextDim
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 65)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = contentArea

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingTop = UDim.new(0, 14)
    pagePad.PaddingBottom = UDim.new(0, 14)
    pagePad.PaddingLeft = UDim.new(0, 14)
    pagePad.PaddingRight = UDim.new(0, 14)
    pagePad.Parent = page

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 10)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    btn.MouseEnter:Connect(function()
        if self.Config.ActiveTab ~= name then
            self:Tween(btn, { BackgroundTransparency = 0.5, BackgroundColor3 = self.Theme.CardHover }, 0.2)
            self:Tween(title, { TextColor3 = self.Theme.TextPrimary }, 0.2)
            self:Tween(icon, { ImageColor3 = self.Theme.TextPrimary }, 0.2)
        end
    end)

    btn.MouseLeave:Connect(function()
        if self.Config.ActiveTab ~= name then
            self:Tween(btn, { BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(20, 20, 26) }, 0.2)
            self:Tween(title, { TextColor3 = self.Theme.TextDim }, 0.2)
            self:Tween(icon, { ImageColor3 = self.Theme.TextDim }, 0.2)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        self:SwitchTab(name)
    end)

    self.State.Tabs[name] = page
    self.State.TabButtons[name] = { Button = btn, Icon = icon, Title = title }
end

function Hub:SwitchTab(tabName)
    self.Config.ActiveTab = tabName
    for name, data in pairs(self.State.TabButtons) do
        local page = self.State.Tabs[name]
        local ind = data.Button:FindFirstChild("ActiveInd")
        if name == tabName then
            page.Visible = true
            if ind then ind.Visible = true end
            self:Tween(data.Button, { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(26, 32, 46) }, 0.2)
            self:Tween(data.Title, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.2)
            self:Tween(data.Icon, { ImageColor3 = self.Theme.Accent }, 0.2)
        else
            page.Visible = false
            if ind then ind.Visible = false end
            self:Tween(data.Button, { BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(20, 20, 26) }, 0.2)
            self:Tween(data.Title, { TextColor3 = self.Theme.TextDim }, 0.2)
            self:Tween(data.Icon, { ImageColor3 = self.Theme.TextDim }, 0.2)
        end
    end

    if tabName == "Visuals" then
        task.spawn(function()
            task.wait(0.05)
            self:CloneLocalPlayerModel()
        end)
        if self.World.Section then
            self.World.Section.Visible = true
            self:Tween(self.World.Section, { BackgroundTransparency = 0 }, 0.3)
        end
    else
        if self.World.Section then
            self.World.Section.Visible = false
        end
    end
end

-- ==================== UI HELPERS ====================
function Hub:CreateDualColumnPage(container)
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 0)
    wrapper.AutomaticSize = Enum.AutomaticSize.Y
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = container

    local leftCol = Instance.new("Frame")
    leftCol.Size = UDim2.new(0.5, -6, 0, 0)
    leftCol.AutomaticSize = Enum.AutomaticSize.Y
    leftCol.BackgroundTransparency = 1
    leftCol.Parent = wrapper

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.Padding = UDim.new(0, 10)
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Parent = leftCol

    local rightCol = Instance.new("Frame")
    rightCol.Size = UDim2.new(0.5, -6, 0, 0)
    rightCol.Position = UDim2.new(0.5, 6, 0, 0)
    rightCol.AutomaticSize = Enum.AutomaticSize.Y
    rightCol.BackgroundTransparency = 1
    rightCol.Parent = wrapper

    local rightLayout = Instance.new("UIListLayout")
    rightLayout.Padding = UDim.new(0, 10)
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Parent = rightCol

    return leftCol, rightCol
end

function Hub:CreateSection(parent, title)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1, 0, 0, 0)
    sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.BackgroundColor3 = self.Theme.CardBg
    sec.BorderSizePixel = 0
    sec.Parent = parent
    self:Corner(sec, 8)
    self:Stroke(sec, self.Theme.Border, 1)

    local secPad = Instance.new("UIPadding")
    secPad.PaddingTop = UDim.new(0, 10)
    secPad.PaddingBottom = UDim.new(0, 10)
    secPad.PaddingLeft = UDim.new(0, 10)
    secPad.PaddingRight = UDim.new(0, 10)
    secPad.Parent = sec

    local secLayout = Instance.new("UIListLayout")
    secLayout.Padding = UDim.new(0, 8)
    secLayout.SortOrder = Enum.SortOrder.LayoutOrder
    secLayout.Parent = sec

    local headerContainer = Instance.new("Frame")
    headerContainer.Size = UDim2.new(1, 0, 0, 18)
    headerContainer.BackgroundTransparency = 1
    headerContainer.Parent = sec

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 5, 0, 5)
    dot.Position = UDim2.new(0, 2, 0.5, -2)
    dot.BackgroundColor3 = self.Theme.Accent
    dot.BorderSizePixel = 0
    dot.Parent = headerContainer
    self:Corner(dot, 3)

    local header = Instance.new("TextLabel")
    header.Position = UDim2.new(0, 12, 0, 0)
    header.Size = UDim2.new(1, -12, 1, 0)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.Text = title
    header.TextColor3 = self.Theme.TextPrimary
    header.TextSize = 12
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = headerContainer

    return sec
end

function Hub:CreateToggle(section, title, defaultState, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
    row.Parent = section
    self:Corner(row, 6)
    self:Stroke(row, Color3.fromRGB(32, 36, 48), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(1, -54, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = title
    lbl.TextColor3 = defaultState and self.Theme.TextPrimary or self.Theme.TextDim
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 36, 0, 18)
    switch.Position = UDim2.new(1, -44, 0.5, -9)
    switch.BackgroundColor3 = defaultState and self.Theme.Accent or Color3.fromRGB(34, 38, 50)
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.Parent = row
    self:Corner(switch, 10)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = defaultState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = switch
    self:Corner(circle, 7)

    local state = defaultState
    switch.MouseButton1Click:Connect(function()
        state = not state
        local targetColor = state and self.Theme.Accent or Color3.fromRGB(34, 38, 50)
        local targetPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        local textColor = state and self.Theme.TextPrimary or self.Theme.TextDim
        self:Tween(switch, { BackgroundColor3 = targetColor }, 0.2)
        self:Tween(circle, { Position = targetPos }, 0.2)
        self:Tween(lbl, { TextColor3 = textColor }, 0.2)
        if callback then callback(state) end
    end)

    return row
end

function Hub:CreateDropdown(section, title, options, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
    row.Parent = section
    self:Corner(row, 6)
    self:Stroke(row, Color3.fromRGB(32, 36, 48), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(0.48, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = title
    lbl.TextColor3 = self.Theme.TextDim
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 105, 0, 20)
    btn.Position = UDim2.new(1, -112, 0.5, -10)
    btn.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
    btn.Font = Enum.Font.GothamBold
    btn.Text = default or "Select"
    btn.TextColor3 = self.Theme.Accent
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Parent = row
    self:Corner(btn, 5)
    self:Stroke(btn, Color3.fromRGB(38, 43, 58), 1)

    local curr = default
    btn.MouseEnter:Connect(function()
        self:Tween(btn, { BackgroundColor3 = Color3.fromRGB(34, 40, 56) }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        self:Tween(btn, { BackgroundColor3 = Color3.fromRGB(26, 30, 42) }, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        local opts = (type(options) == "function") and options() or options
        if not opts or #opts == 0 then
            btn.Text = "None"
            return
        end

        local found = false
        for idx, val in ipairs(opts) do
            if val == curr then
                curr = opts[(idx % #opts) + 1]
                found = true
                break
            end
        end
        if not found then
            curr = opts[1]
        end

        btn.Text = tostring(curr)
        if callback then callback(curr) end
    end)
    return btn
end

function Hub:CreateSlider(section, title, minVal, maxVal, defaultVal, suffix, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
    row.Parent = section
    self:Corner(row, 6)
    self:Stroke(row, Color3.fromRGB(32, 36, 48), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.new(0, 10, 0, 3)
    lbl.Size = UDim2.new(0.65, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = title
    lbl.TextColor3 = self.Theme.TextDim
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 48, 0, 16)
    badge.Position = UDim2.new(1, -56, 0, 3)
    badge.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
    badge.Parent = row
    self:Corner(badge, 4)
    self:Stroke(badge, Color3.fromRGB(38, 43, 58), 1)

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, 0, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold
    valLbl.Text = tostring(defaultVal) .. (suffix or "")
    valLbl.TextColor3 = self.Theme.Accent
    valLbl.TextSize = 10
    valLbl.TextXAlignment = Enum.TextXAlignment.Center
    valLbl.Parent = badge

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 25)
    bar.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    bar.Parent = row
    self:Corner(bar, 3)

    local fill = Instance.new("Frame")
    local pct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = self.Theme.Accent
    fill.Parent = bar
    self:Corner(fill, 3)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(1, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = fill
    self:Corner(knob, 5)

    local dragging = false
    local function update(input)
        local x = input.Position.X - bar.AbsolutePosition.X
        local ratio = math.clamp(x / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * ratio)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valLbl.Text = tostring(val) .. (suffix or "")
        if callback then callback(val) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    self.Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)

    self.Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return row
end

function Hub:CreateButton(section, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    btn.Text = text
    btn.Font = Enum.Font.GothamMedium
    btn.TextColor3 = self.Theme.TextPrimary
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = section
    self:Corner(btn, 6)
    self:Stroke(btn, Color3.fromRGB(35, 42, 58), 1)

    btn.MouseEnter:Connect(function()
        self:Tween(btn, { BackgroundColor3 = Color3.fromRGB(32, 40, 58), TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        self:Tween(btn, { BackgroundColor3 = Color3.fromRGB(22, 26, 36), TextColor3 = self.Theme.TextPrimary }, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then callback(btn) end
    end)
    return btn
end

-- ==================== ВКЛАДКА COMBAT ====================
function Hub:BuildCombatTab(container)
    local leftCol, rightCol = self:CreateDualColumnPage(container)

    -- Левая колонка: Шериф
    local sheriffSec = self:CreateSection(leftCol, "Sheriff / Gunner")
    self:CreateToggle(sheriffSec, "Silent Aim", self.Config.Toggles.SilentAim, function(v)
        self.Config.Toggles.SilentAim = v
    end)
    self:CreateToggle(sheriffSec, "Wallbang (No Dist Limit)", self.Config.Toggles.AimWallbang, function(v)
        self.Config.Toggles.AimWallbang = v
    end)
    self:CreateToggle(sheriffSec, "Flick Shot", self.Config.Toggles.FlickShot, function(v)
        self.Config.Toggles.FlickShot = v
    end)
    self:CreateDropdown(sheriffSec, "Flick Mode", { "Mouse", "ShiftLock / Cam" }, self.Config.Values.FlickMode, function(v)
        self.Config.Values.FlickMode = v
    end)
    self:CreateToggle(sheriffSec, "Enable Prediction", self.Config.Toggles.AimPrediction, function(v)
        self.Config.Toggles.AimPrediction = v
    end)
    self:CreateSlider(sheriffSec, "Prediction", 0, 100, self.Config.Values.PredictionPercent, "%", function(v)
        self.Config.Values.PredictionPercent = v
    end)
    self:CreateToggle(sheriffSec, "Auto Shot Murderer", self.Config.Toggles.AutoShotMurderer, function(v)
        self.Config.Toggles.AutoShotMurderer = v
    end)
    self:CreateToggle(sheriffSec, "Auto Grab Dropped Gun", self.Config.Toggles.AutoGrabGun, function(v)
        self.Config.Toggles.AutoGrabGun = v
    end)

    -- Бинд клавиши выстрела
    local bindRow = Instance.new("Frame")
    bindRow.Size = UDim2.new(1, 0, 0, 28)
    bindRow.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    bindRow.Parent = sheriffSec
    self:Corner(bindRow, 6)

    local bLbl = Instance.new("TextLabel")
    bLbl.Position = UDim2.new(0, 8, 0, 0)
    bLbl.Size = UDim2.new(0.6, 0, 1, 0)
    bLbl.BackgroundTransparency = 1
    bLbl.Font = Enum.Font.GothamMedium
    bLbl.Text = "Shoot Murderer Key"
    bLbl.TextColor3 = self.Theme.TextDim
    bLbl.TextSize = 11
    bLbl.TextXAlignment = Enum.TextXAlignment.Left
    bLbl.Parent = bindRow

    local bBtn = Instance.new("TextButton")
    bBtn.Size = UDim2.new(0, 50, 0, 20)
    bBtn.Position = UDim2.new(1, -56, 0.5, -10)
    bBtn.BackgroundColor3 = self.Theme.CardHover
    bBtn.Font = Enum.Font.GothamBold
    bBtn.Text = (self.Config.ShootKey == Enum.KeyCode.Unknown or not self.Config.ShootKey) and "None" or self.Config.ShootKey.Name
    bBtn.TextColor3 = self.Theme.TextPrimary
    bBtn.TextSize = 10
    bBtn.AutoButtonColor = false
    bBtn.Parent = bindRow
    self:Corner(bBtn, 5)

    bBtn.MouseButton1Click:Connect(function()
        self.Config.IsListeningShootKey = true
        bBtn.Text = "..."
    end)

    self.Services.UserInputService.InputBegan:Connect(function(input)
        if self.Config.IsListeningShootKey then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                    self.Config.ShootKey = Enum.KeyCode.Unknown
                    bBtn.Text = "None"
                else
                    self.Config.ShootKey = input.KeyCode
                    bBtn.Text = input.KeyCode.Name
                end
                self.Config.IsListeningShootKey = false
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                self.Config.ShootKey = input.UserInputType
                bBtn.Text = input.UserInputType.Name
                self.Config.IsListeningShootKey = false
            end
        end
    end)

    -- Правая колонка: УБИЙЦА (ЕДИНЫЙ РАЗДЕЛ)
    local murdererSec = self:CreateSection(rightCol, "Murderer")

    -- 1. KILL ALL (СВЕРХУ)
    self:CreateToggle(murdererSec, "Kill All (Авто)", self.Config.Toggles.KillAll, function(v)
        self.Config.Toggles.KillAll = v
    end)
    self:CreateDropdown(murdererSec, "Kill All Mode", { "Classic", "Silent" }, self.Config.Values.KillAllMode, function(v)
        self.Config.Values.KillAllMode = v
    end)

    local killAllNowBtn = Instance.new("TextButton")
    killAllNowBtn.Size = UDim2.new(1, 0, 0, 30)
    killAllNowBtn.BackgroundColor3 = Color3.fromRGB(38, 18, 22)
    killAllNowBtn.Text = "Kill All Now"
    killAllNowBtn.Font = Enum.Font.GothamBold
    killAllNowBtn.TextColor3 = Color3.fromRGB(255, 80, 90)
    killAllNowBtn.TextSize = 11
    killAllNowBtn.Parent = murdererSec
    self:Corner(killAllNowBtn, 6)

    killAllNowBtn.MouseButton1Click:Connect(function()
        self:ExecuteKillAll()
    end)

    -- 2. KILL AURA
    self:CreateToggle(murdererSec, "Kill Aura", self.Config.Toggles.KillAura, function(v)
        self.Config.Toggles.KillAura = v
    end)
    self:CreateDropdown(murdererSec, "Aura Mode", { "Classic", "Silent" }, self.Config.Values.KillMode, function(v)
        self.Config.Values.KillMode = v
    end)
    self:CreateSlider(murdererSec, "Aura Distance", 10, 45, self.Config.Values.KillAuraDist, "m", function(v)
        self.Config.Values.KillAuraDist = v
    end)

    -- 3. KILL SHERIFF (ПОД КИЛЛ АУРОЙ)
    self:CreateToggle(murdererSec, "Auto Kill Sheriff", self.Config.Toggles.AutoKillSheriff, function(v)
        self.Config.Toggles.AutoKillSheriff = v
    end)
    self:CreateDropdown(murdererSec, "Kill Sheriff Mode", { "Classic", "Silent" }, self.Config.Values.KillSheriffMode, function(v)
        self.Config.Values.KillSheriffMode = v
    end)

    local killSheriffBtn = Instance.new("TextButton")
    killSheriffBtn.Size = UDim2.new(1, 0, 0, 30)
    killSheriffBtn.BackgroundColor3 = Color3.fromRGB(20, 28, 45)
    killSheriffBtn.Text = "Kill Sheriff / Hero Now"
    killSheriffBtn.Font = Enum.Font.GothamBold
    killSheriffBtn.TextColor3 = Color3.fromRGB(100, 180, 255)
    killSheriffBtn.TextSize = 11
    killSheriffBtn.Parent = murdererSec
    self:Corner(killSheriffBtn, 6)

    killSheriffBtn.MouseButton1Click:Connect(function()
        self:KillSheriff()
    end)

    -- 4. SELECT KILL (ТОЛЬКО ПОТОМ СЕЛЕКТ, КНОПКА А НЕ ПЕРЕКЛЮЧАТЕЛЬ)
    local function getPlayerNames()
        local names = {}
        for _, p in ipairs(Hub.Services.Players:GetPlayers()) do
            if p ~= Hub.Services.Players.LocalPlayer then
                table.insert(names, p.Name)
            end
        end
        return names
    end

    local targetDisplay = Instance.new("TextLabel")
    targetDisplay.Size = UDim2.new(1, 0, 0, 16)
    targetDisplay.BackgroundTransparency = 1
    targetDisplay.Font = Enum.Font.GothamMedium
    targetDisplay.Text = "Target: None"
    targetDisplay.TextColor3 = self.Theme.TextDim
    targetDisplay.TextSize = 10
    targetDisplay.TextXAlignment = Enum.TextXAlignment.Left
    targetDisplay.Parent = murdererSec

    self:CreateDropdown(murdererSec, "Select Target", getPlayerNames, "Select", function(selectedName)
        self.Config.SelectedTargetPlayer = Hub.Services.Players:FindFirstChild(selectedName)
        targetDisplay.Text = "Target: " .. tostring(selectedName)
    end)

    local killTargetBtn = Instance.new("TextButton")
    killTargetBtn.Size = UDim2.new(1, 0, 0, 30)
    killTargetBtn.BackgroundColor3 = Color3.fromRGB(45, 20, 25)
    killTargetBtn.Text = "Kill Selected Player"
    killTargetBtn.Font = Enum.Font.GothamBold
    killTargetBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    killTargetBtn.TextSize = 11
    killTargetBtn.Parent = murdererSec
    self:Corner(killTargetBtn, 6)

    killTargetBtn.MouseButton1Click:Connect(function()
        local target = self.Config.SelectedTargetPlayer
        local knife = self:FindKnife()
        if target and target.Character and knife then
            task.spawn(function()
                if self.Config.Values.KillMode == "Silent" then
                    self:StabSilent(target, knife)
                else
                    self:StabClassic(target, knife)
                end
            end)
        end
    end)
end

-- ==================== ВКЛАДКА VISUALS ====================
function Hub:BuildVisualsTab(container)
    local leftCol, rightCol = self:CreateDualColumnPage(container)

    -- 3D Character Preview
    local previewSec = self:CreateSection(leftCol, "Character Preview")
    self:SetupPreview(previewSec)
    self:CreateToggle(previewSec, "Idle Rotation", self.Config.Toggles.PreviewRotate, function(v)
        self.Config.Toggles.PreviewRotate = v
    end)
    self:CreateToggle(previewSec, "Preview Aura", self.Config.Toggles.PreviewAura, function(v)
        self:TogglePreviewAura(v)
    end)

    -- ESP Roles
    local espSec = self:CreateSection(rightCol, "ESP Roles (Interception)")
    self:CreateToggle(espSec, "Enable ESP Roles", self.Config.Toggles.ESPRoles, function(v)
        self.Config.Toggles.ESPRoles = v
        self:RenderESP()
    end)
    self:CreateToggle(espSec, "Local Player ESP (Self)", self.Config.Toggles.LocalESP, function(v)
        self.Config.Toggles.LocalESP = v
        self:UpdatePreviewLocalESP()
        self:RenderESP()
    end)
    self:CreateToggle(espSec, "Role Text (Above)", self.Config.Toggles.ESPRoleText, function(v)
        self.Config.Toggles.ESPRoleText = v
        self:RenderESP()
    end)
    self:CreateToggle(espSec, "Nicknames (Above)", self.Config.Toggles.ESPNickname, function(v)
        self.Config.Toggles.ESPNickname = v
        self:RenderESP()
    end)
    self:CreateToggle(espSec, "Distance (Below Feet)", self.Config.Toggles.ESPDist, function(v)
        self.Config.Toggles.ESPDist = v
        self:RenderESP()
    end)
    self:CreateToggle(espSec, "2D Boxes", self.Config.Toggles.ESPBoxes, function(v)
        self.Config.Toggles.ESPBoxes = v
        if not v then
            for _, d in pairs(self.ESP.Drawings) do
                if d.Box then d.Box.Visible = false end
            end
        end
        self:RenderESP()
    end)
    self:CreateToggle(espSec, "Tracers", self.Config.Toggles.ESPTracers, function(v)
        self.Config.Toggles.ESPTracers = v
        if not v then
            for _, d in pairs(self.ESP.Drawings) do
                if d.Tracer then d.Tracer.Visible = false end
            end
        end
        self:RenderESP()
    end)
    self:CreateToggle(espSec, "Gun ESP (Dropped Gun)", self.Config.Toggles.ESPGun, function(v)
        self.Config.Toggles.ESPGun = v
        if not v then
            self:ClearGunESP()
        end
        self:RenderESP()
    end)

    -- Выезжающий снизу раздел World
    local worldSec = self:CreateSection(container, "World & Environment Settings")
    worldSec.Name = "WorldSection"
    self.World.Section = worldSec

    self:CreateToggle(worldSec, "X-Ray (Просвечивание стен)", self.Config.Toggles.XRay, function(v)
        self.Config.Toggles.XRay = v
        if v then
            self:ApplyXRay()
        else
            self:DisableXRay()
        end
    end)
    self:CreateSlider(worldSec, "X-Ray Transparency", 0, 100, self.Config.Values.XRayTransparency, "%", function(v)
        self.Config.Values.XRayTransparency = v
        if self.Config.Toggles.XRay then
            self:UpdateXRayTransparency()
        end
    end)
    self:CreateToggle(worldSec, "FullBright (Яркость мира)", self.Config.Toggles.FullBright, function(v)
        self.Config.Toggles.FullBright = v
        self:ApplyWorldSettings()
    end)
    self:CreateToggle(worldSec, "Remove Fog (Убрать туман)", self.Config.Toggles.NoFog, function(v)
        self.Config.Toggles.NoFog = v
        self:ApplyWorldSettings()
    end)
    self:CreateToggle(worldSec, "Global Shadows (Тени)", self.Config.Toggles.WorldShadows, function(v)
        self.Config.Toggles.WorldShadows = v
        self:ApplyWorldSettings()
    end)
    self:CreateSlider(worldSec, "Time of Day (Время)", 0, 24, self.Config.Values.ClockTime, "h", function(v)
        self.Config.Values.ClockTime = v
        self:ApplyWorldSettings()
    end)
    self:CreateSlider(worldSec, "Camera FOV (Угол обзора)", 70, 120, self.Config.Values.CameraFOV, "°", function(v)
        self.Config.Values.CameraFOV = v
        self:ApplyWorldSettings()
    end)
    self:CreateDropdown(worldSec, "Ambient Tint (Тинт)", { "Default", "Neon Purple", "Sunset Warm", "Midnight Blue" }, self.Config.Values.AmbientTint, function(v)
        self.Config.Values.AmbientTint = v
        self:ApplyWorldSettings()
    end)
end

-- ==================== TAB: MISC (SUPREME VALUES & UTILITIES) ====================
function Hub:BuildMiscTab(container)
    local leftCol, rightCol = self:CreateDualColumnPage(container)

    -- SECTION: SUPREME VALUES (ПОКАЗ ВАЛЮТ)
    local valSec = self:CreateSection(leftCol, "Supreme Values (Показ валют)")
    self:CreateToggle(valSec, "Show Values", self.Config.Toggles.ShowSkinValues, function(st)
        self.Config.Toggles.ShowSkinValues = st
        self.Config.Toggles.ShowInventoryValues = st
        self.Config.Toggles.ShowTradeValues = st
        if not st then
            self:CleanValuesBadges()
        else
            self:UpdateInventoryValues()
            self:UpdateTradeValues()
        end
    end)

    -- SECTION: MOVEMENT CHEATS
    local moveSec = self:CreateSection(leftCol, "Movement Cheats")
    self:CreateToggle(moveSec, "Speed Hack", self.Config.Toggles.SpeedHack, function(v)
        self.Config.Toggles.SpeedHack = v
        local hum = self.Services.Players.LocalPlayer.Character and self.Services.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and self.Config.Values.WalkSpeed or 16 end
    end)
    self:CreateSlider(moveSec, "Speed Value", 16, 120, self.Config.Values.WalkSpeed, " ws", function(v)
        self.Config.Values.WalkSpeed = v
        if self.Config.Toggles.SpeedHack then
            local hum = self.Services.Players.LocalPlayer.Character and self.Services.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end)
    self:CreateToggle(moveSec, "Infinite Jump", self.Config.Toggles.InfiniteJump, function(v)
        self.Config.Toggles.InfiniteJump = v
    end)
    self:CreateToggle(moveSec, "NoClip", self.Config.Toggles.NoClip, function(v)
        self.Config.Toggles.NoClip = v
    end)

    -- RIGHT COLUMN: ANTI-AFK & AUTOMATION
    local afkSec = self:CreateSection(rightCol, "Anti-AFK & Automation")
    local afkBtn = nil
    self:CreateToggle(afkSec, "Anti-AFK (20m Kick Shield)", self.Config.Toggles.AntiAFK, function(v)
        self.Config.Toggles.AntiAFK = v
        if afkBtn then
            afkBtn.Text = v and "Anti-AFK: ACTIVE [ON]" or "Anti-AFK: DISABLED"
            afkBtn.TextColor3 = v and self.Theme.Accent or self.Theme.TextDim
        end
    end)
    afkBtn = self:CreateButton(afkSec, self.Config.Toggles.AntiAFK and "Anti-AFK: ACTIVE [ON]" or "Anti-AFK: DISABLED", function(b)
        self.Config.Toggles.AntiAFK = not self.Config.Toggles.AntiAFK
        b.Text = self.Config.Toggles.AntiAFK and "Anti-AFK: ACTIVE [ON]" or "Anti-AFK: DISABLED"
        b.TextColor3 = self.Config.Toggles.AntiAFK and self.Theme.Accent or self.Theme.TextDim
    end)

    -- SECTION: EXTRA ACTIONS
    local extraSec = self:CreateSection(rightCol, "Extra Actions")
    self:CreateButton(extraSec, "Reload 3D Preview Model", function()
        self:CloneLocalPlayerModel()
    end)
    self:CreateButton(extraSec, "Fix Gun Grip & Reset Anim", function()
        self:FixToolGrip()
    end)
end

Hub.BuildFunTab = Hub.BuildMiscTab

-- ==================== ВКЛАДКА MAPS (3 ГОРИЗОНТАЛЬНЫЕ КАРТОЧКИ В РЯД) ====================
function Hub:BuildMapsTab(container)
    -- 1. Верхняя секция: Vote Duplicator
    local dupSec = self:CreateSection(container, "Vote Duplicator (Дюп голосов)")

    self:CreateToggle(dupSec, "Enable Vote Duplicator", self.Config.Toggles.VoteDup, function(v)
        self.Config.Toggles.VoteDup = v
        if v then
            -- Не выбираем карту сами: игрок должен нажать на нужную карту
            self.Maps.SelectedPad = nil
            self:UpdateMapCardsHighlight()
            self:StartVoteDuplicator()
        else
            self.Maps.SelectedPad = nil
            self:UpdateMapCardsHighlight()
        end
    end)

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, 0, 0, 18)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Font = Enum.Font.GothamMedium
    statusLbl.Text = "Статус: Ожидание голосования..."
    statusLbl.TextColor3 = self.Theme.TextMuted
    statusLbl.TextSize = 11
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Parent = dupSec
    self.Maps.StatusLabel = statusLbl

    local infoDesc = Instance.new("TextLabel")
    infoDesc.Size = UDim2.new(1, 0, 0, 20)
    infoDesc.BackgroundTransparency = 1
    infoDesc.Font = Enum.Font.Gotham
    infoDesc.Text = "Click any map card below to vote. With Duplicator ON, it will duplicate votes for that card."
    infoDesc.TextColor3 = self.Theme.TextDim
    infoDesc.TextSize = 10
    infoDesc.TextXAlignment = Enum.TextXAlignment.Left
    infoDesc.Parent = dupSec

    -- 2. Нижняя секция: 3 Карточки рядом друг с другом
    local cardsSec = self:CreateSection(container, "Active Voting Maps")

    local cardsRow = Instance.new("Frame")
    cardsRow.Size = UDim2.new(1, 0, 0, 160)
    cardsRow.BackgroundTransparency = 1
    cardsRow.Parent = cardsSec

    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding = UDim.new(0, 8)
    rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rowLayout.Parent = cardsRow

    local padKeys = { "VotePad1", "VotePad2", "VotePad3" }
    for idx, padName in ipairs(padKeys) do
        local card = Instance.new("Frame")
        card.Name = "MapCard_" .. padName
        card.Size = UDim2.new(0, 142, 1, 0)
        card.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
        card.LayoutOrder = idx
        card.Parent = cardsRow
        self:Corner(card, 8)
        local cardStroke = self:Stroke(card, self.Theme.Border, 1)

        -- Картинка карты
        local img = Instance.new("ImageLabel")
        img.Name = "MapImage"
        img.Size = UDim2.new(1, -12, 0, 78)
        img.Position = UDim2.new(0, 6, 0, 6)
        img.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
        img.Image = self.Maps.Cached[padName].Image
        img.ScaleType = Enum.ScaleType.Crop
        img.Parent = card
        self:Corner(img, 6)

        -- Название карты (БЕЗ надписи VotePad!)
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "MapName"
        nameLbl.Position = UDim2.new(0, 6, 0, 88)
        nameLbl.Size = UDim2.new(1, -12, 0, 18)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.Text = self.Maps.Cached[padName].MapName
        nameLbl.TextColor3 = self.Theme.TextPrimary
        nameLbl.TextSize = 12
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.TextXAlignment = Enum.TextXAlignment.Center
        nameLbl.Parent = card

        -- Количество голосов
        local voteLbl = Instance.new("TextLabel")
        voteLbl.Name = "VoteCount"
        voteLbl.Position = UDim2.new(0, 6, 0, 106)
        voteLbl.Size = UDim2.new(1, -12, 0, 16)
        voteLbl.BackgroundTransparency = 1
        voteLbl.Font = Enum.Font.GothamMedium
        voteLbl.Text = "Votes: " .. tostring(self.Maps.Cached[padName].Votes)
        voteLbl.TextColor3 = self.Theme.TextDim
        voteLbl.TextSize = 11
        voteLbl.TextXAlignment = Enum.TextXAlignment.Center
        voteLbl.Parent = card

        -- Кнопка действия (Vote)
        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.new(1, -16, 0, 24)
        actionBtn.Position = UDim2.new(0, 8, 1, -30)
        actionBtn.BackgroundColor3 = self.Theme.CardHover
        actionBtn.Font = Enum.Font.GothamBold
        actionBtn.Text = "Vote"
        actionBtn.TextColor3 = self.Theme.TextPrimary
        actionBtn.TextSize = 10
        actionBtn.AutoButtonColor = false
        actionBtn.Parent = card
        self:Corner(actionBtn, 5)

        local function handleCardClick()
            if self.Config.Toggles.VoteDup then
                self.Maps.SelectedPad = padName
                self:UpdateMapCardsHighlight()
                if not self.Maps.DupRunning then
                    self:StartVoteDuplicator()
                end
            else
                self:TeleportToPad(padName)
            end
        end

        actionBtn.MouseButton1Click:Connect(handleCardClick)

        local clickCatcher = Instance.new("TextButton")
        clickCatcher.Size = UDim2.new(1, 0, 1, -34)
        clickCatcher.BackgroundTransparency = 1
        clickCatcher.Text = ""
        clickCatcher.Parent = card
        clickCatcher.MouseButton1Click:Connect(handleCardClick)

        self.Maps.Cards[padName] = {
            Card = card,
            CardStroke = cardStroke,
            Image = img,
            NameLabel = nameLbl,
            VoteLabel = voteLbl,
            Button = actionBtn,
        }
    end

    -- Частое обновление голосов и состояния раунда (каждые 0.15 сек)
    task.spawn(function()
        while self.State.Gui and self.State.Gui.Parent do
            local maps = self:ScanMaps()
            local isVoting = self:IsVotingActive()

            if not isVoting then
                if not self.Config.Toggles.VoteDup and self.Maps.SelectedPad ~= nil then
                    self.Maps.SelectedPad = nil
                    self:UpdateMapCardsHighlight()
                end
                if self.Maps.StatusLabel then
                    self.Maps.StatusLabel.Text = "Статус: Ожидание голосования..."
                    self.Maps.StatusLabel.TextColor3 = self.Theme.TextMuted
                end
            end

            for _, m in ipairs(maps) do
                local uiCard = self.Maps.Cards[m.PadName]
                if uiCard then
                    if m.Image and m.Image ~= "" then
                        uiCard.Image.Image = m.Image
                    end
                    uiCard.NameLabel.Text = m.MapName
                    uiCard.VoteLabel.Text = "Votes: " .. tostring(m.Votes)
                end
            end

            task.wait(0.15)
        end
    end)
end

-- ==================== ВКЛАДКА ANIMATION ====================
function Hub:ResolveAnimationId(assetId)
    local rawId = tostring(assetId)
    local ok, objs = pcall(game.GetObjects, game, "rbxassetid://" .. rawId)
    if ok and objs and #objs > 0 then
        for _, obj in ipairs(objs) do
            if obj:IsA("Animation") and obj.AnimationId ~= "" then
                return obj.AnimationId
            end
            local found = obj:FindFirstChildWhichIsA("Animation", true)
            if found and found.AnimationId ~= "" then
                return found.AnimationId
            end
        end
    end
    return "rbxassetid://" .. rawId
end

function Hub:BuildAnimationTab(container)
    local topPanel = Instance.new("Frame")
    topPanel.Size = UDim2.new(1, 0, 0, 72)
    topPanel.BackgroundTransparency = 1
    topPanel.Parent = container

    local searchBar = Instance.new("TextBox")
    searchBar.Size = UDim2.new(1, -110, 0, 30)
    searchBar.BackgroundColor3 = self.Theme.CardBg
    searchBar.PlaceholderText = "Search emotes & walk styles..."
    searchBar.PlaceholderColor3 = self.Theme.TextMuted
    searchBar.Text = ""
    searchBar.Font = Enum.Font.GothamMedium
    searchBar.TextColor3 = self.Theme.TextPrimary
    searchBar.TextSize = 11
    searchBar.TextXAlignment = Enum.TextXAlignment.Left
    searchBar.Parent = topPanel
    self:Corner(searchBar, 6)
    self:Stroke(searchBar, self.Theme.Border, 1)

    local searchPad = Instance.new("UIPadding")
    searchPad.PaddingLeft = UDim.new(0, 10)
    searchPad.Parent = searchBar

    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 100, 0, 30)
    stopBtn.Position = UDim2.new(1, -100, 0, 0)
    stopBtn.BackgroundColor3 = Color3.fromRGB(45, 20, 25)
    stopBtn.Text = "Stop Emote"
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextColor3 = Color3.fromRGB(255, 90, 100)
    stopBtn.TextSize = 10
    stopBtn.AutoButtonColor = false
    stopBtn.Parent = topPanel
    self:Corner(stopBtn, 6)

    stopBtn.MouseButton1Click:Connect(function()
        self:StopAnimation()
    end)

    local subTabs = Instance.new("Frame")
    subTabs.Size = UDim2.new(1, 0, 0, 28)
    subTabs.Position = UDim2.new(0, 0, 0, 38)
    subTabs.BackgroundTransparency = 1
    subTabs.Parent = topPanel

    local subLayout = Instance.new("UIListLayout")
    subLayout.FillDirection = Enum.FillDirection.Horizontal
    subLayout.Padding = UDim.new(0, 8)
    subLayout.Parent = subTabs

    local cats = { "Emotes", "Walk Styles", "Favorites" }
    local subBtns = {}
    for _, cat in ipairs(cats) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 90, 1, 0)
        b.BackgroundColor3 = (cat == "Emotes") and Color3.fromRGB(35, 35, 48) or Color3.fromRGB(18, 18, 24)
        b.Text = cat
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = (cat == "Emotes") and Color3.fromRGB(255, 255, 255) or self.Theme.TextDim
        b.TextSize = 10
        b.AutoButtonColor = false
        b.Parent = subTabs
        self:Corner(b, 5)
        subBtns[cat] = b

        b.MouseButton1Click:Connect(function()
            self.Animations.ActiveTab = cat
            for cName, cBtn in pairs(subBtns) do
                if cName == cat then
                    cBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
                    cBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    cBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
                    cBtn.TextColor3 = self.Theme.TextDim
                end
            end
            self:RenderAnimationList()
        end)
    end

    local gridScroll = Instance.new("ScrollingFrame")
    gridScroll.Position = UDim2.new(0, 0, 0, 80)
    gridScroll.Size = UDim2.new(1, 0, 1, -80)
    gridScroll.BackgroundTransparency = 1
    gridScroll.BorderSizePixel = 0
    gridScroll.ScrollBarThickness = 3
    gridScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 65)
    gridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    gridScroll.Parent = container
    self.Animations.ListContainer = gridScroll

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 134, 0, 150)
    grid.CellPadding = UDim2.new(0, 10, 0, 10)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = gridScroll

    searchBar:GetPropertyChangedSignal("Text"):Connect(function()
        self.Animations.SearchQuery = searchBar.Text:lower()
        self:RenderAnimationList()
    end)

    self:RenderAnimationList()
end

function Hub:RenderAnimationList()
    local container = self.Animations.ListContainer
    if not container then return end

    for _, c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local tab = self.Animations.ActiveTab
    local q = self.Animations.SearchQuery

    for _, anim in ipairs(self.Animations.List) do
        local matchesTab = (tab == "Favorites" and self.Animations.Favorites[anim.Id]) or (anim.Category == tab)
        local matchesSearch = (q == "") or (anim.Name:lower():find(q) ~= nil)

        if matchesTab and matchesSearch then
            local card = Instance.new("Frame")
            card.BackgroundColor3 = self.Theme.CardBg
            card.Parent = container
            self:Corner(card, 8)
            self:Stroke(card, self.Theme.Border, 1)

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(1, -12, 0, 80)
            thumb.Position = UDim2.new(0, 6, 0, 6)
            thumb.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
            thumb.Image = anim.Icon
            thumb.ScaleType = Enum.ScaleType.Fit
            thumb.Parent = card
            self:Corner(thumb, 6)

            local starBtn = Instance.new("ImageButton")
            starBtn.Size = UDim2.new(0, 18, 0, 18)
            starBtn.Position = UDim2.new(1, -24, 0, 8)
            starBtn.BackgroundTransparency = 1
            starBtn.Image = self.Animations.Favorites[anim.Id] and Icons.StarFilled or Icons.StarOutline
            starBtn.ImageColor3 = self.Animations.Favorites[anim.Id] and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 180, 190)
            starBtn.Parent = card

            starBtn.MouseButton1Click:Connect(function()
                self.Animations.Favorites[anim.Id] = not self.Animations.Favorites[anim.Id]
                starBtn.Image = self.Animations.Favorites[anim.Id] and Icons.StarFilled or Icons.StarOutline
                starBtn.ImageColor3 = self.Animations.Favorites[anim.Id] and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 180, 190)
                if tab == "Favorites" then self:RenderAnimationList() end
            end)

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -12, 0, 24)
            title.Position = UDim2.new(0, 6, 0, 90)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamMedium
            title.Text = anim.Name
            title.TextColor3 = self.Theme.TextPrimary
            title.TextSize = 10
            title.TextWrapped = true
            title.Parent = card

            local playBtn = Instance.new("TextButton")
            playBtn.Size = UDim2.new(1, -12, 0, 22)
            playBtn.Position = UDim2.new(0, 6, 1, -28)
            playBtn.BackgroundColor3 = self.Theme.CardHover
            playBtn.Font = Enum.Font.GothamBold
            playBtn.Text = "Play"
            playBtn.TextColor3 = self.Theme.TextPrimary
            playBtn.TextSize = 10
            playBtn.AutoButtonColor = false
            playBtn.Parent = card
            self:Corner(playBtn, 5)

            playBtn.MouseButton1Click:Connect(function()
                self:PlayCatalogAnimation(anim.Id, anim.Category)
            end)
        end
    end
end

function Hub:PlayCatalogAnimation(assetId, category)
    local char = self.Services.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    self:StopAnimation()

    task.spawn(function()
        local realAnimId = self:ResolveAnimationId(assetId)
        local anim = Instance.new("Animation")
        anim.AnimationId = realAnimId

        local animator = hum:FindFirstChildOfClass("Animator") or hum
        local track = animator:LoadAnimation(anim)
        if category == "Walk Styles" then
            track.Priority = Enum.AnimationPriority.Movement
        else
            track.Priority = Enum.AnimationPriority.Action
        end
        track.Looped = true
        track:Play()
        self.Animations.CurrentTrack = track
    end)
end

function Hub:StopAnimation()
    if self.Animations.CurrentTrack then
        pcall(function() self.Animations.CurrentTrack:Stop() end)
        self.Animations.CurrentTrack = nil
    end

    local lp = self.Services.Players.LocalPlayer
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
            if t.Priority == Enum.AnimationPriority.Action or t.Priority == Enum.AnimationPriority.Action4 then
                pcall(function() t:Stop() end)
            end
        end
    end
end

-- ==================== ВКЛАДКА CONFIG ====================
function Hub:BuildConfigTab(container)
    local leftCol, rightCol = self:CreateDualColumnPage(container)

    local menuSec = self:CreateSection(leftCol, "Menu Settings")
    local bindRow = Instance.new("Frame")
    bindRow.Size = UDim2.new(1, 0, 0, 28)
    bindRow.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    bindRow.Parent = menuSec
    self:Corner(bindRow, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = "Toggle Menu Key"
    lbl.TextColor3 = self.Theme.TextDim
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = bindRow

    local bBtn = Instance.new("TextButton")
    bBtn.Size = UDim2.new(0, 70, 0, 20)
    bBtn.Position = UDim2.new(1, -76, 0.5, -10)
    bBtn.BackgroundColor3 = self.Theme.CardHover
    bBtn.Font = Enum.Font.GothamBold
    bBtn.Text = self.Config.MenuKey.Name
    bBtn.TextColor3 = self.Theme.TextPrimary
    bBtn.TextSize = 10
    bBtn.AutoButtonColor = false
    bBtn.Parent = bindRow
    self:Corner(bBtn, 5)

    bBtn.MouseButton1Click:Connect(function()
        self.Config.IsListeningMenuKey = true
        bBtn.Text = "..."
    end)

    self.Services.UserInputService.InputBegan:Connect(function(input)
        if self.Config.IsListeningMenuKey and input.UserInputType == Enum.UserInputType.Keyboard then
            self.Config.MenuKey = input.KeyCode
            bBtn.Text = input.KeyCode.Name
            self.Config.IsListeningMenuKey = false
        end
    end)

    local actSec = self:CreateSection(rightCol, "Script Control")
    local unloadBtn = Instance.new("TextButton")
    unloadBtn.Size = UDim2.new(1, 0, 0, 32)
    unloadBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 25)
    unloadBtn.Text = "Unload Script (Clean Exit)"
    unloadBtn.Font = Enum.Font.GothamBold
    unloadBtn.TextColor3 = Color3.fromRGB(255, 90, 100)
    unloadBtn.TextSize = 11
    unloadBtn.Parent = actSec
    self:Corner(unloadBtn, 6)

    unloadBtn.MouseButton1Click:Connect(function()
        self:Unload()
    end)
end

-- ==================== DRAGGING & CONTROLS ====================
function Hub:ToggleMenu(state)
    if state == nil then state = not self.State.IsOpen end
    self.State.IsOpen = state

    if state then
        self.State.MainFrame.Visible = true
        if self.State.Shadow then self.State.Shadow.Visible = true end
        self:Tween(self.State.MainFrame, { Size = UDim2.new(0, 620, 0, 540) }, 0.25)
    else
        if self.State.Shadow then self.State.Shadow.Visible = false end
        local tw = self:Tween(self.State.MainFrame, { Size = UDim2.new(0, 620, 0, 0) }, 0.2)
        tw.Completed:Connect(function()
            if not self.State.IsOpen then
                self.State.MainFrame.Visible = false
            end
        end)
    end
end

function Hub:SetupWindowDragging()
    local drag = { Dragging = false, Start = Vector3.zero, Pos = UDim2.new() }
    local topbar = self.State.TopBar
    local main = self.State.MainFrame
    local shadow = self.State.Shadow

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag.Dragging = true
            drag.Start = input.Position
            drag.Pos = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    drag.Dragging = false
                end
            end)
        end
    end)

    self.Services.UserInputService.InputChanged:Connect(function(input)
        if drag.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - drag.Start
            local newPos = UDim2.new(
                drag.Pos.X.Scale,
                drag.Pos.X.Offset + delta.X,
                drag.Pos.Y.Scale,
                drag.Pos.Y.Offset + delta.Y
            )
            main.Position = newPos
            if shadow then shadow.Position = newPos end
        end
    end)
end

function Hub:SetupKeybinds()
    self.Services.UserInputService.InputBegan:Connect(function(input, gp)
        if not self.Config.IsListeningMenuKey and input.KeyCode == self.Config.MenuKey then
            self:ToggleMenu()
        end
        if not self.Config.IsListeningShootKey and self.Config.ShootKey and self.Config.ShootKey ~= Enum.KeyCode.Unknown then
            if input.KeyCode == self.Config.ShootKey or input.UserInputType == self.Config.ShootKey then
                self:ShootMurderer()
            end
        end
    end)

    self.Services.UserInputService.JumpRequest:Connect(function()
        if self.Config.Toggles.InfiniteJump then
            local hum = self.Services.Players.LocalPlayer.Character and self.Services.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end

-- ==================== MAIN LOOPS ====================
function Hub:StartMainLoops()
    -- ESP Loop
    self.Services.RunService.RenderStepped:Connect(function()
        if self.Config.Toggles.ESPRoles or self.Config.Toggles.ESPGun then
            self:RenderESP()
        end
    end)

    -- Auto Shot Loop
    task.spawn(function()
        while self.State.Gui and self.State.Gui.Parent do
            if self.Config.Toggles.AutoShotMurderer and (os.clock() - self.Combat.LastShot > 0.4) then
                self:ShootMurderer()
            end
            task.wait(0.2)
        end
    end)

    -- Kill All Loop (когда включен переключатель — моментальное параллельное уничтожение всех)
    task.spawn(function()
        while self.State.Gui and self.State.Gui.Parent do
            if self.Config.Toggles.KillAll then
                self:ExecuteKillAll()
            end
            task.wait(0.2)
        end
    end)

    -- Kill Aura Loop (моментальное параллельное уничтожение всех в радиусе)
    task.spawn(function()
        while self.State.Gui and self.State.Gui.Parent do
            if self.Config.Toggles.KillAura then
                local knife = self:FindKnife()
                local lp = self.Services.Players.LocalPlayer
                local myRoot = self:GetRoot(lp.Character)
                if knife and myRoot then
                    local mode = self.Config.Values.KillMode or "Classic"
                    local maxDist = self.Config.Values.KillAuraDist or 18
                    for _, p in ipairs(self.Services.Players:GetPlayers()) do
                        if p ~= lp then
                            local ch = p.Character
                            local root = self:GetRoot(ch)
                            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                            if root and hum and hum.Health > 0 then
                                local dist = (root.Position - myRoot.Position).Magnitude
                                if dist <= maxDist then
                                    task.spawn(function()
                                        if mode == "Silent" then
                                            self:StabSilent(p, knife)
                                        else
                                            self:StabClassic(p, knife)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)

    -- Auto Kill Sheriff Loop
    task.spawn(function()
        while self.State.Gui and self.State.Gui.Parent do
            if self.Config.Toggles.AutoKillSheriff then
                self:KillSheriff()
            end
            task.wait(0.2)
        end
    end)

    -- Auto Grab Dropped Gun Loop
    task.spawn(function()
        while self.State.Gui and self.State.Gui.Parent do
            if self.Config.Toggles.AutoGrabGun then
                self:GrabDroppedGun()
            end
            task.wait(0.25)
        end
    end)

    -- Постоянный Speed Hack (не сбрасывается смертью или новым раундом)
    self.Services.RunService.Heartbeat:Connect(function()
        if self.Config.Toggles.SpeedHack then
            local lp = self.Services.Players.LocalPlayer
            local char = lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= self.Config.Values.WalkSpeed then
                hum.WalkSpeed = self.Config.Values.WalkSpeed
            end
        end
    end)

    -- NoClip
    self.Services.RunService.Stepped:Connect(function()
        if self.Config.Toggles.NoClip then
            local char = self.Services.Players.LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end
    end)

    -- Character Added / Respawn (сохранение скорости, превью и локального ESP)
    self.Services.Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.25)
        local hum = newChar:WaitForChild("Humanoid", 3)
        if hum and self.Config.Toggles.SpeedHack then
            hum.WalkSpeed = self.Config.Values.WalkSpeed
        end
        self:CloneLocalPlayerModel()
        self:ApplyWorldSettings()
        if self.Config.Toggles.LocalESP then
            self:UpdatePreviewLocalESP()
        end
        if self.SkinSystem.AutoReapply then
            for slot, rec in pairs(self.SkinSystem.Picked) do
                self:ApplySkinToDisplay(rec)
                self:ApplySkinToTool(rec)
            end
        end
    end)

    -- Anti-AFK Initialization
    self:SetupAntiAFK()

    -- Pre-populate CachedValues from FallbackValues immediately (zero delay)
    for k, v in pairs(self.ValuesSystem.FallbackValues) do
        local sKey = tostring(k)
        self.ValuesSystem.CachedValues[sKey] = v
        self.ValuesSystem.CachedValues[sKey:lower()] = v
        local alpha = sKey:lower():gsub("%W", "")
        if alpha ~= "" then self.ValuesSystem.CachedValues[alpha] = v end
    end

    -- Supreme Values Auto-updater loop (каждые 5 минут)
    task.spawn(function()
        self:FetchValues()
        while self.State.Gui and self.State.Gui.Parent do
            task.wait(10)
            if (os.clock() - self.ValuesSystem.LastFetch) >= self.ValuesSystem.FetchInterval then
                self:FetchValues()
            end
        end
    end)

    -- Inventory & Trade Values Monitor Loop (каждые 0.25с для мгновенного отклика при переключении вкладок)
    task.spawn(function()
        while self.State.Gui and self.State.Gui.Parent do
            if self.Config.Toggles.ShowSkinValues then
                self:UpdateInventoryValues()
                self:UpdateTradeValues()
            end
            task.wait(0.25)
        end
    end)

    -- Skin Database Loader for asset ID resolution
    task.spawn(function()
        self:LoadSkinDatabase()
    end)
end

function Hub:Unload()
    self:StopAnimation()
    self:ClearAllESP()
    self:DisableXRay()
    if self.State.Gui then
        self.State.Gui:Destroy()
    end
end

-- Старт
Hub:Init()
print("Welcome to Dynamic Hub")
