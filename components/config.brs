function GetAirsonicConfig() as Object
    return {
        serverUrl: "http://demo.subsonic.org:80",
        username: "guest",
        password: "guest",  ' MD5-encoded password
        apiVersion: "1.15",
        clientName: "rokuApp",
        format: "json"
    }
end function