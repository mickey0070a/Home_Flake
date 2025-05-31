local function is_rock_installed(rock_name)
    local handle = io.popen("luarocks list")
    local result = handle:read("*a")
    handle:close()

    for line in result:gmatch("[^\r\n]+") do
        if line:match("^" .. rock_name .. "%s") then
            return true
        end
    end
    return false
end

local rock = "lain"
local rock2 = "lcpz/awesome-freedesktop" 

if not is_rock_installed(rock) then
    print(rock .. " not found, installing...")
    os.execute("luarocks install " .. rock)
else
    print(rock .. " is already installed.")
end

if not is_rock_installed(rock2) then
    print(rock2 .. " not found, installing...")
    os.execute("luarocks install " .. rock2)
    os.execute("cd ~/.luarocks/")
    os.execute("git clone https://github.com/lcpz/awesome-freedesktop.git")
else
    print(rock2 .. " is already installed.")
end