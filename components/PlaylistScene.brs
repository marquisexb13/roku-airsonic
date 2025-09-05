' *************** PlaylistScene.brs ***************
' SceneGraph code-behind for PlaylistScene
' Implements:
'  - Airsonic/Subsonic token auth (t + s) using MD5(password + salt)
'  - MarkupList content via ContentNode tree
'  - Single Audio node to play entire playlist
'  - Defensive JSON parsing & UI feedback

'==================================================
' ============ Scene lifecycle ====================
'==================================================

sub init()
    m.playlistList = m.top.findNode("playlistList")
    m.debugLabel   = m.top.findNode("debuglabel")

    ' Be sure the XML uses id="playlistList" and id="debuglabel"
    ' Handle user selection
    m.playlistList.observeField("itemSelected", "onPlaylistSelected")

    if m.debugLabel <> invalid then
        m.debugLabel.text = "Loading playlists..."
    end if

    ' Lazy-create Audio node used for playback
    m.audio = CreateObject("roSGNode", "Audio")
    m.top.appendChild(m.audio)
    ' (Optional) Observe audio state if you want UI updates
    ' m.audio.observeField("state", "onAudioStateChanged")

    fetchPlaylists()
end sub


'==================================================
' ============ Data fetching helpers ===============
'==================================================

' Build the full base URL for an endpoint, including auth query string.
' Example: BuildEndpointUrl("getPlaylists") -> http(s)://.../rest/getPlaylists.view?...auth...
function BuildEndpointUrl(endpoint as string) as string
    config = GetAirsonicConfig()
    base = config.serverUrl
    if right(base, 1) <> "/" then base = base + "/"
    return base + "rest/" + endpoint + ".view?" + BuildAuthQuery(config)
end function

' Build Subsonic/Airsonic token auth parameters: u, t, s, v, c, f
' t = md5(password + salt), s = random salt
function BuildAuthQuery(config as object) as string
    'Randomize(0) ' seed RNG once per run
    salt = StrI(Rnd(100000000)) ' simple random numeric salt as string

    md5 = CreateObject("roEVPDigest")
    md5.Setup("md5")
    md5.Update(config.password + salt)
    token = LCase(md5.Final())

    'esc = CreateObject("roUrlTransfer") ' use Escape for URL encoding where needed
    u = config.username
    c = config.clientName
	p = config.password
    ' apiVersion and format are already sane strings

    'return "u=" + u + "&t=" + token + "&s=" + salt + "&v=" + config.apiVersion + "&c=" + c + "&f=" + config.format
    return "u=" + u + "&p=" + p + "&v=" + config.apiVersion + "&c=" + c + "&f=" + config.format
end function

' Generic GET helper that returns parsed JSON object or invalid on failure
function HttpGetJson(url as string) as dynamic
    ' 1. Create the objects needed for the request
    http = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    http.SetPort(port)
	setDebug("getting url:" + url)

    http.SetUrl(url)

    ' 2. Start the asynchronous download
    if not http.AsyncGetToString()
        print "Error: Could not start URL transfer."
        return invalid
    end if

    ' 3. Wait for a response on the message port
    print "Downloading data from: "; url
    msg = wait(10000, port) ' Wait up to 10 seconds for a message

    ' 4. Process the response event
    if type(msg) = "roUrlEvent"
        ' Check for a successful HTTP status code (e.g., 200 OK)
        if msg.GetResponseCode() = 200
            jsonString = msg.GetString()
            
            ' 5. Parse the JSON string safely using a try/catch block
            try
                parsedJson = ParseJson(jsonString)
                if parsedJson = invalid
                    print "Error: Failed to parse JSON. The data might be malformed."
                    return invalid
                else
                    print "Success: Downloaded and parsed JSON."
                    return parsedJson ' Success! Return the parsed object
                end if
            catch e
                print "Error: An exception occurred during JSON parsing: "; e
                return invalid
            end try
        else
            ' Handle HTTP errors
            print "Error: Received HTTP Status "; msg.GetResponseCode()
            print "Failure Reason: "; msg.GetFailureReason()
            return invalid
        end if
    else if msg = invalid
        ' Handle timeouts
        print "Error: Request timed out."
        return invalid
    else
        ' Handle other unexpected messages
        print "Error: Received an unexpected message type: "; type(msg)
        return invalid
    end if
end function


'==================================================
' ============ Playlists: fetch & bind =============
'==================================================

sub fetchPlaylists()
    url = BuildEndpointUrl("getPlaylists")

    j = HttpGetJson(url)
    if j = invalid then
        setDebug("Network error: failed to fetch playlists")
        return
    end if

    root = j["subsonic-response"]
    if root = invalid then
        setDebug("Unexpected response: missing subsonic-response")
        return
    end if

    if LCase(root.status) <> "ok" then
        setDebug("Server status: " + toString(root.status))
        return
    end if

    playlistsBlock = root.playlists
    if playlistsBlock = invalid or playlistsBlock.playlist = invalid then
        setDebug("No playlists found")
        return
    end if

    playlists = playlistsBlock.playlist
    ' playlists can be a single object or an array
    if Type(playlists) <> "roArray" then
        playlists = [playlists]
    end if

    ' Build ContentNode tree for MarkupList
    contentRoot = CreateObject("roSGNode", "ContentNode")
    for each p in playlists
        if p <> invalid
            row = CreateObject("roSGNode", "ContentNode")
            ' MarkupList default renderer uses .title
            row.title = toString(p.name)
            ' keep playlist id as custom field
            row.addField("playlistId", "string", true)
            row.playlistId = toString(p.id)
            contentRoot.appendChild(row)
        end if
    end for

    m.playlistList.content = contentRoot
    setDebug("Select a playlist")
end sub


'==================================================
' ============ Selection -> play ===================
'==================================================

sub onPlaylistSelected()
    idx = m.playlistList.itemSelected
    if idx = invalid then return

    item = invalid
    if m.playlistList.content <> invalid and idx >= 0 and idx < m.playlistList.content.getChildCount()
        item = m.playlistList.content.getChild(idx)
    end if

    if item = invalid or item.playlistId = invalid then
        setDebug("Unable to determine selected playlist")
        return
    end if

    playPlaylist(item.playlistId)
end sub


'==================================================
' ============ Build & play audio queue ============
'==================================================

sub playPlaylist(playlistId as string)
    setDebug("Loading tracks...")

    url = BuildEndpointUrl("getPlaylist") + "&id=" + playlistId
    j = HttpGetJson(url)
    if j = invalid then
        setDebug("Network error: failed to fetch playlist")
        return
    end if

    root = j["subsonic-response"]
    if root = invalid or LCase(root.status) <> "ok" then
        setDebug("Server error fetching playlist")
        return
    end if

    pl = root.playlist
    if pl = invalid or pl.entry = invalid then
        setDebug("No tracks in playlist")
        return
    end if

    entries = pl.entry
    if Type(entries) <> "roArray" then
        entries = [entries]
    end if

    ' Build audio queue as ContentNode list
    queueRoot = CreateObject("roSGNode", "ContentNode")

    for each t in entries
        if t <> invalid
            ' Airsonic/Subsonic stream endpoint; must include auth each time
            streamUrl = BuildEndpointUrl("stream") + "&id=" + toString(t.id)

            trackNode = CreateObject("roSGNode", "ContentNode")
            trackNode.url   = streamUrl
            trackNode.title = toString(t.title)
            ' (Optional) set metadata if your UI/Audio needs it:
            ' trackNode.artist = toString(t.artist)
            ' trackNode.album  = toString(t.album)

            queueRoot.appendChild(trackNode)
        end if
    end for

    if queueRoot.getChildCount() = 0 then
        setDebug("No playable tracks")
        return
    end if

    ' Stop any current playback, set new content, and play
    m.audio.control = "stop"
    m.audio.content = queueRoot
    m.audio.control = "play"

    setDebug("Playing: " + queueRoot.getChild(0).title)
end sub


'==================================================
' ============ (Optional) Audio state ==============
'==================================================

sub onAudioStateChanged()
    ' states: "none", "playing", "paused", "stopped", "finished", "error"
    s = m.audio.state
    if s = "error" then
        setDebug("Audio error")
    else if s = "finished" then
        setDebug("Playback finished")
    end if
end sub


'==================================================
' ============ Small utilities =====================
'==================================================

sub setDebug(msg as string)
    if m.debugLabel <> invalid then
        m.debugLabel.text = msg
    end if
    print "[PlaylistScene] "; msg
end sub
