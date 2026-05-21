' Storage.brs
' Simple registry-backed persistence for server settings.

function Storage_loadSettings() as Object
    sec = CreateObject("roRegistrySection", "SubsonicRoku")
    baseUrl = sec.Read("baseUrl")
    username = sec.Read("username")
    password = sec.Read("password")

    if baseUrl = invalid or baseUrl = "" then return invalid
    if username = invalid or username = "" then return invalid

    return { baseUrl: baseUrl, username: username, password: password }
end function

sub Storage_saveSettings(baseUrl as String, username as String, password as String)
    sec = CreateObject("roRegistrySection", "SubsonicRoku")
    sec.Write("baseUrl", baseUrl)
    sec.Write("username", username)
    sec.Write("password", password)
    sec.Flush()
end sub

sub Storage_clearSettings()
    sec = CreateObject("roRegistrySection", "SubsonicRoku")
    sec.Delete("baseUrl")
    sec.Delete("username")
    sec.Delete("password")
    sec.Flush()
end sub
