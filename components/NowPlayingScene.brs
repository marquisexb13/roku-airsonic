' NowPlayingScene.brs

sub init()
    m.track = m.top.findNode("track")
    m.player = m.top.findNode("player")
    m.player.observeField("state", "onPlayerState")
    m.top.setFocus(true)
end sub

sub setSong(song as Object, url as String)
    if song = invalid then return
    m.track.text = song.title

    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.streamformat = "mp3" ' adjust based on your server/transcode

    m.player.content = content
    m.player.control = "play"
end sub

sub onPlayerState()
    ' hook for debugging
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and (key = "back" or key = "Back") then
        m.player.control = "stop"
        ' naive: return to home
        m.top.getScene().currentView = "home"
        return true
    end if
    return false
end function
