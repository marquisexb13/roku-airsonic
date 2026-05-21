' LoginScene.brs - event-driven 3-step login wizard + async ping via Task

sub init()
    ?"LoginScene init"
    m.top.setFocus(true)

    m.status = m.top.findNode("status")

    ' wizard state: idle | baseUrl | username | password | pinging
    m.step = "idle"
    m.login = {}

    m.api = invalid
    m.pingUrl = ""
    m.httpTask = invalid

    if m.status <> invalid then m.status.text = "Press OK to enter server settings"
end sub


function onKeyEvent(key as String, press as Boolean) as Boolean
    if press = false then return false

    ?"Key Pressed: "; key

    if key = "OK" then
        if m.step = "idle" then
            startLoginWizard()
        end if
        return true
    end if

    return false
end function


sub startLoginWizard()
    m.login = {}
    m.step = "baseUrl"
    if m.status <> invalid then m.status.text = "Enter server URL"
    showDialog("Server URL", "http://demo.subsonic.org", false)
end sub


sub showDialog(title as String, initial as String, secure as Boolean)
    dlg = CreateObject("roSGNode", "KeyboardDialog")
    dlg.title = title
    dlg.text = initial
    dlg.buttons = ["OK", "Cancel"]

    ' Hide text for password entry (optional)
    if secure then
        if dlg.keyboard <> invalid and dlg.keyboard.textEditBox <> invalid then
            dlg.keyboard.textEditBox.secureMode = true
        end if
    end if

    dlg.observeField("buttonSelected", "onDlgButton")
    m.top.getScene().dialog = dlg
end sub


sub onDlgButton()
    dlg = m.top.getScene().dialog
    if dlg = invalid then return

    ' 0 = OK, 1 = Cancel (based on buttons array order) 【3-47f091】
    if dlg.buttonSelected <> 0 then
        ?"Login wizard cancelled"
        m.top.getScene().dialog = invalid
        m.step = "idle"
        if m.status <> invalid then m.status.text = "Cancelled. Press OK to try again."
        return
    end if

    entered = dlg.text
    ?"Dialog step="; m.step; " value="; entered

    ' close dialog before moving on
    m.top.getScene().dialog = invalid

    if entered = invalid or entered = "" then
        m.step = "idle"
        if m.status <> invalid then m.status.text = "Nothing entered. Press OK to try again."
        return
    end if

    if m.step = "baseUrl" then
        m.login.baseUrl = entered
        m.step = "username"
        if m.status <> invalid then m.status.text = "Enter username"
        showDialog("Username", "guest5", false)
        return
    end if

    if m.step = "username" then
        m.login.username = entered
        m.step = "password"
        if m.status <> invalid then m.status.text = "Enter password"
        showDialog("Password", "guest", true)
        return
    end if

    if m.step = "password" then
        m.login.password = entered

        ' We now have all three values, start async ping (no synchronous rsp!)
        m.step = "pinging"
        if m.status <> invalid then m.status.text = "Testing connection..."

        ?"baseURL "; m.login.baseUrl
        ?"username "; m.login.username
        ?"password len="; Len(m.login.password)

        beginPing()
        return
    end if
end sub


sub beginPing()
    ' Build ApiClient and ping URL on render thread (safe)
    m.api = ApiClient_new(m.login.baseUrl, m.login.username, m.login.password)
    m.pingUrl = m.api._buildUrl("ping.view", invalid, {})

    ?"Ping URL: "; m.pingUrl

    startPingTask(m.pingUrl)
end sub


sub startPingTask(url as String)
    if m.httpTask = invalid then
        m.httpTask = CreateObject("roSGNode", "HttpGetTask")
        m.httpTask.observeField("response", "onPingResponse")
        m.httpTask.observeField("error", "onPingError")
    end if

    ' Clear previous
    m.httpTask.response = ""
    m.httpTask.error = ""

    ' Fire
    m.httpTask.requestUrl = url
    m.httpTask.control = "run"
end sub


sub onPingError()
    err = m.httpTask.error
    if err <> invalid and err <> "" then
        ?"Ping error: "; err
        m.step = "idle"
        if m.status <> invalid then m.status.text = "Ping failed: " + err + " (Press OK to retry)"
    end if
end sub


sub onPingResponse()
    body = m.httpTask.response
    ?"Ping response raw: "; Left(body, 200)

    if body = invalid or body = "" then
        m.step = "idle"
        if m.status <> invalid then m.status.text = "Ping returned empty response (Press OK to retry)"
        return
    end if

    json = ParseJson(body)
    if json = invalid then
        ' Some servers may return XML or HTML on redirects; report it
        m.step = "idle"
        if m.status <> invalid then m.status.text = "Ping returned non-JSON (Press OK to retry)"
        return
    end if

    ' Subsonic JSON typically has a "subsonic-response" root; be tolerant
    ok = true
    if json["subsonic-response"] <> invalid and json["subsonic-response"]["status"] <> invalid then
        ok = (LCase(json["subsonic-response"]["status"]) = "ok")
    end if

    if ok then
        if m.status <> invalid then m.status.text = "Connected."
        m.step = "idle"
        m.top.loginData = m.login
        m.top.loginSuccess = true
    else
        m.step = "idle"
        if m.status <> invalid then m.status.text = "Ping returned error status (Press OK to retry)"
    end if
end sub
