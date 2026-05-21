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

    ' FORCE FOCUS TO ACTIVE VIEW
    if view = "login" then
        m.login.setFocus(true)
    else if view = "home" then
        m.home.setFocus(true)
    else if view = "nowplaying" then
        m.nowplaying.setFocus(true)
    end if
end sub

sub onLoginSuccess()
    ?"Login successful - switching to home"

    home = m.top.findNode("home")

    if home <> invalid then
		home.loginData = m.login.loginData
    end if

    m.currentView = "home"

	m.login.visible = false
	m.home.visible = true

end sub


sub onLoginDataChanged()
    m.loginData = m.top.loginData
end sub


sub onPlaySong()
    song = m.home.playSong
    if song <> invalid and m.top.api <> invalid
        url = m.top.api.streamUrl(song.id)
        m.nowplaying.setSong(song, url)
        Router_goToNowPlaying(m.top)
    end if
end sub
