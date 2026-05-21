' ApiClient.brs
' Thin wrapper around Subsonic/OpenSubsonic REST endpoints.
' Uses token auth (t) + salt (s) per Subsonic API.
'
function ApiClient_new(baseUrl as String, username as String, password as String, apiVersion = "1.15.1" as String) as Object
    o = {
        baseUrl: baseUrl
        username: username
        password: password
        apiVersion: apiVersion
        clientId: "SubsonicRoku"
    }

    ' public
    o.ping = ApiClient_ping
    o.getArtists = ApiClient_getArtists
    o.getAlbum = ApiClient_getAlbum
    o.getPlaylists = ApiClient_getPlaylists
    o.getPlaylist = ApiClient_getPlaylist
    o.streamUrl = ApiClient_streamUrl

    ' private
    o._getJson = ApiClient__getJson
    o._buildUrl = ApiClient__buildUrl

    return o
end function

function ApiClient_ping() as Object
    return m._getJson("ping.view", invalid, {})
end function

function ApiClient_getArtists() as Object
    return m._getJson("getArtists.view", invalid, {})
end function

function ApiClient_getAlbum(id as String) as Object
    return m._getJson("getAlbum.view", id, {})
end function

function ApiClient_getPlaylists() as Object
    return m._getJson("getPlaylists.view", invalid, {})
end function

function ApiClient_getPlaylist(id as String) as Object
    return m._getJson("getPlaylist.view", id, {})
end function

function ApiClient_streamUrl(id as String, opts = {} as Object) as String
    ' Returns a URL suitable for a Video node
    return m._buildUrl("stream.view", id, opts)
end function

' --- private helpers ---

function ApiClient__getJson(cmd as String, id as Dynamic, opts as Object) as Object
    url = m._buildUrl(cmd, id, opts)
    xfer = CreateObject("roUrlTransfer")
    xfer.SetUrl(url)
    xfer.AddHeader("Accept", "application/json")
    rsp = xfer.GetToString()
    if rsp = invalid or rsp = "" then return invalid
    return ParseJson(rsp)
end function

function ApiClient__buildUrl(cmd as String, id as Dynamic, opts as Object) as String
    
	params = {}
	params.u = m.username

	' SIMPLE AUTH (REPLACE TOKEN FLOW)
	params.p = m.password

	params.v = m.apiVersion
	params.c = m.clientId
	params.f = "json"


    if id <> invalid then params.id = id
    if opts <> invalid
        for each k in opts
            params[k] = opts[k]
        end for
    end if

	qs = ""
	sep = "?"
	for each k in params
		qs = qs + sep + k + "=" + ToStr(params[k])
		'UrlEncode(ToStr(params[k]))
		sep = "&"
	end for

   base = m.baseUrl
    if right(base, 1) = "/" then base = left(base, len(base)-1)

    return base + "/rest/" + cmd + qs
end function

function ToStr(v as Dynamic) as String
    if v = invalid then return ""
    if type(v) = "roString" then return v
    return v.ToStr()
end function
