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

local rock1 = "lain"
local rock2name = "freedesktop"
local rock2module = "lcpz/awesome-freedesktop"

if not is_rock_installed(rock1) then
    print(rock1 .. " not found, installing...")
    os.execute("luarocks install --local " .. rock1)
else
    print(rock1 .. " is already installed.")
end

if not is_rock_installed(rock2name) then
    print(rock2name .. " not found, installing...")
    os.execute("cd ~/.luarocks/share/lua/5.3/")
    os.execute("git clone https://github.com/lcpz/awesome-freedesktop.git ~/.luarocks/share/lua/5.3/freedesktop")
else
    print(rock2name .. " is already installed.")
end
