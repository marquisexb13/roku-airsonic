' MainScene.brs

sub init()
	?"MainScene init() called"
    m.login = m.top.findNode("login")
    m.home = m.top.findNode("home")
    m.nowplaying = m.top.findNode("nowplaying")

    m.top.observeField("currentView", "onViewChanged")

    m.settings = Storage_loadSettings()
    if m.settings = invalid then
        Router_goToLogin(m.top)
		onViewChanged() ' FORCE IT
    else
        m.top.api = ApiClient_new(m.settings.baseUrl, m.settings.username, m.settings.password)
        Router_goToHome(m.top)
    end if

    m.login.observeField("loginSuccess", "onLoginSuccess")
    m.home.observeField("playSong", "onPlaySong")
end sub


sub onViewChanged()
    view = m.top.currentView
    ?"View changed to: "; view

    m.login.visible = (view = "login")
    m.home.visible = (view = "home")
    m.nowplaying.visible = (view = "nowplaying")

    ' ✅ FORCE FOCUS TO ACTIVE VIEW
    if view = "login" then
        m.login.setFocus(true)
    else if view = "home" then
        m.home.setFocus(true)
    else if view = "nowplaying" then
        m.nowplaying.setFocus(true)
    end if
end sub

sub onLoginSuccess()
    data = m.login.loginData
    if data <> invalid
        Storage_saveSettings(data.baseUrl, data.username, data.password)
        m.top.api = ApiClient_new(data.baseUrl, data.username, data.password)
        Router_goToHome(m.top)
    end if
end sub

sub onPlaySong()
    song = m.home.playSong
    if song <> invalid and m.top.api <> invalid
        url = m.top.api.streamUrl(song.id)
        m.nowplaying.setSong(song, url)
        Router_goToNowPlaying(m.top)
    end if
end sub
