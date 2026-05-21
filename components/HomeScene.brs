sub init()
    ?"HomeScene init"
	

    m.status = m.top.findNode("status")
    'm.label = m.top.findNode("playlistLabel")
	
	m.grid = m.top.findNode("playlistGrid")
	m.grid.observeField("itemSelected", "onPlaylistSelected")
	
	'm.grid = m.top.findNode("playlistGrid")
	'm.grid.observeField("itemSelected", "onPlaylistSelected")

    ?"HomeScene nodes:"
    ?"status = "; m.status
    ?"label = "; m.label

    m.top.observeField("loginData", "onLoginReady")
end sub


' after login
sub onLoginReady()
    ?"HomeScene received loginData"
    data = m.top.loginData
	m.top.visible = true

    m.api = ApiClient_new(data.baseUrl, data.username, data.password)

    if m.status <> invalid then m.status.text = "Loading playlists..."

    loadPlaylists()
end sub


sub loadPlaylists()
    ?"loadPlaylists"

    url = m.api._buildUrl("getPlaylists.view", invalid, {})

    if m.task = invalid then
        m.task = CreateObject("roSGNode", "HttpGetTask")
        m.task.observeField("response", "onPlaylistsResponse")
        m.task.observeField("error", "onPlaylistsError")
    end if

    m.task.response = ""
    m.task.error = ""
    m.task.requestUrl = url
    m.task.control = "run"
end sub



sub onPlaylistsResponse()
    body = m.task.response

    ?"Playlists raw: "; Left(body, 200)

    json = ParseJson(body)
    if json = invalid then
        if m.status <> invalid then m.status.text = "Invalid playlist response"
        return
    end if

    root = json["subsonic-response"]
    if root = invalid then
        if m.status <> invalid then m.status.text = "Missing subsonic-response"
        return
    end if

    if root.playlists = invalid or root.playlists.playlist = invalid then
        if m.status <> invalid then m.status.text = "No playlists found"
        if m.label <> invalid then m.label.text = "(no playlists)"
        return
    end if

    list = root.playlists.playlist

    ' Normalize to an array so "for each" is always safe
    if type(list) <> "roArray" then
        list = [list]
    end if

    ?"Playlist count: "; list.Count()


	content = CreateObject("roSGNode", "ContentNode")

	for each p in list
		item = CreateObject("roSGNode", "ContentNode")
		item.title = p.name
		item.id = p.id
		content.appendChild(item)
	end for

	m.grid.content = content
	m.grid.setFocus(true)

	m.status.text = "Select a playlist"



    if m.status <> invalid then m.status.text = "Playlists loaded (use OK to continue)"
end sub



sub onPlaylistsError()
    err = m.task.error
    if err <> invalid and err <> "" then
        m.status.text = "Playlist error: " + err
    end if
end sub


' playlist clicked
sub onPlaylistSelected()
    idx = m.grid.itemSelected
    node = m.grid.content.getChild(idx)

    ?"Selected playlist"; node.title

    ' For now just show selection
    'm.status.text = "Selected: " + node.title
	m.status.text = "Loading playlist: " + node.title
	loadPlaylistTracks(node.id)
end sub


' load tracks
sub loadPlaylistTracks(id as String)
    ?"Loading playlist tracks for id: "; id

    url = m.api._buildUrl("getPlaylist.view", invalid, { id: id })

    if m.trackTask = invalid then
        m.trackTask = CreateObject("roSGNode", "HttpGetTask")
        m.trackTask.observeField("response", "onPlaylistTracksResponse")
        m.trackTask.observeField("error", "onPlaylistTracksError")
    end if

    m.trackTask.response = ""
    m.trackTask.error = ""
    m.trackTask.requestUrl = url
    m.trackTask.control = "run"

    m.status.text = "Loading tracks..."
end sub


sub onPlaylistTracksResponse()
    body = m.trackTask.response

    ?"Tracks raw: "; Left(body, 200)

    json = ParseJson(body)
    if json = invalid then
        m.status.text = "Invalid track response"
        return
    end if

    root = json["subsonic-response"]

    if root = invalid or root.playlist = invalid or root.playlist.entry = invalid then
        m.status.text = "No tracks found"
        return
    end if

    tracks = root.playlist.entry

    ' Normalize
    if type(tracks) <> "roArray" then
        tracks = [tracks]
    end if

    ?"Track count: "; tracks.Count()

    ' Build new content node
    content = CreateObject("roSGNode", "ContentNode")

    for each t in tracks
        item = CreateObject("roSGNode", "ContentNode")

        line = t.title
        if t.artist <> invalid and t.artist <> "" then
            line = line + " - " + t.artist
        end if

        item.title = line
        item.id = t.id

        content.appendChild(item)
    end for

    ' IMPORTANT: force refresh
    m.grid.content = invalid   ' clear old data first
    m.grid.content = content   ' assign new data

    ?"Grid child count: "; m.grid.content.getChildCount()

    m.grid.setFocus(true)
    m.grid.jumpToItem = 0      ' ensure visible selection

    m.status.text = "Tracks loaded"
end sub


sub onPlaylistTracksResponseBAD()
    body = m.trackTask.response

    ?"Tracks raw: "; Left(body, 200)

    json = ParseJson(body)
    if json = invalid then
        m.status.text = "Invalid track response"
        return
    end if

    root = json["subsonic-response"]

    if root = invalid or root.playlist = invalid or root.playlist.entry = invalid then
        m.status.text = "No tracks found"
        return
    end if

    tracks = root.playlist.entry

    ' Normalize
    if type(tracks) <> "roArray" then
        tracks = [tracks]
    end if

    ?"Track count: "; tracks.Count()

    text = ""
    for each t in tracks
        line = t.title
        if t.artist <> invalid and t.artist <> "" then
            line = line + " - " + t.artist
        end if
        text = text + line + Chr(10)
    end for

    if m.label <> invalid then
        m.grid.content = content
		'm.label.text = text
    end if

    m.status.text = "Tracks loaded"

end sub


sub onPlaylistTracksError()
    err = m.trackTask.error
    if err <> invalid and err <> "" then
        m.status.text = "Track error: " + err
    end if
end sub

' track selected
sub onTrackSelected()
    idx = m.list.itemSelected
    node = m.list.content.getChild(idx)

    ?"Track selected"; node.title

    showTrackMenu(node)
end sub


' menu
sub showTrackMenu(trackNode as Object)
    dlg = CreateObject("roSGNode", "Dialog")

    dlg.title = "Track Options"
    dlg.options = ["Play Now", "Play Randomized", "Append to Playlist"]

    m.selectedTrack = trackNode

    dlg.observeField("optionSelected", "onTrackMenuSelected")

    m.top.getScene().dialog = dlg
end sub


sub onTrackMenuSelected()
    dlg = m.top.getScene().dialog
    if dlg = invalid then return

    choice = dlg.optionSelected
    track = m.selectedTrack

    if choice = 0 then
        ?"PLAY NOW"; track.id
        playNow(track.id)

    else if choice = 1 then
        ?"PLAY RANDOM"
        playRandom()

    else if choice = 2 then
        ?"APPEND"
        appendTrack(track.id)
    end if

    m.top.getScene().dialog = invalid
end sub


' actions (stubbed — wire to player later)

sub playNow(id)
    m.status.text = "Play Now: " + id
end sub

sub playRandom()
    m.status.text = "Play Random"
end sub

sub appendTrack(id)
    m.status.text = "Append: " + id
end sub