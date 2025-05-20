local function require_or_install(module_name, rock_name)
    local ok, mod = pcall(require, module_name)
    if ok then return mod end

    -- Notify the user (optional)
    naughty.notify {
        title = "Installing missing plugin",
        text = "Installing '" .. (rock_name or module_name) .. "' via LuaRocks..."
    }

    -- Install via LuaRocks
    local install_cmd = "luarocks install " .. (rock_name or module_name)
    local success = os.execute(install_cmd)

    -- Try loading again
    if success then
        local ok2, mod2 = pcall(require, module_name)
        if ok2 then return mod2 end
    end

    -- Final failure notice
    naughty.notify {
        title = "Plugin install failed",
        text = "Could not load '" .. module_name .. "' after install."
    }
    return nil
end

return require_or_install
