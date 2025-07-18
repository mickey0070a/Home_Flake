local function require_or_install(module_name, rock_name)

    local ok, mod = pcall(require, module_name)
    if ok then return mod end


    -- Install via LuaRocks
    local install_cmd = "luarocks install --local " .. (rock_name or module_name)
    local success = os.execute(install_cmd)
    os.execute("git clone https://github.com/lcpz/awesome-freedesktop ~/.config/awesome/freedesktop")


    -- Try loading again
    if success then
        local ok2, mod2 = pcall(require, module_name)
        if ok2 then return mod2 end
    end
    return nil
end

return require_or_install
