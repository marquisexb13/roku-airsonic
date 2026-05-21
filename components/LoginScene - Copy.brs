' LoginScene.brs

sub init()
	?"LoginScene init"

    m.status = m.top.findNode("status")
    m.top.setFocus(true)

end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
	?"Key Pressed: "; key
    
	if press = false then return false

	if key = "OK" then
		?"OK PRESSED ✅"
        baseUrl = prompt("Server URL", "http://demo.subsonic.org/index.view")
		?"baseURL "; baseUrl
		if baseUrl = invalid then return true

        username = prompt("Username", "guest5")
        if username = invalid then return true

        password = prompt("Password", "guest")
        if password = invalid then return true

        m.status.text = "Testing connection..."
		?"Testing Connection..."
        api = ApiClient_new(baseUrl, username, password)
        rsp = api.ping()

        if rsp = invalid
            m.status.text = "Ping failed. Check server URL / credentials."
        else
            m.status.text = "Connected."
			?"Connected to server"; baseUrl
            m.top.loginData = { baseUrl: baseUrl, username: username, password: password }
            m.top.loginSuccess = true
        end if
        return true
    end if

    return false
end function


function prompt(title as String, initial as String) as Void
    dlg = CreateObject("roSGNode", "KeyboardDialog")
    dlg.title = title
    dlg.text = initial
    dlg.buttons = ["OK", "Cancel"]

    dlg.observeField("buttonSelected", "onDlgButton")

    m.top.getScene().dialog = dlg
end function



sub onDlgButton()
    dlg = m.top.getScene().dialog
    if dlg = invalid then return

    if dlg.buttonSelected = 0 then
        ?"User entered: "; dlg.text
    else
        ?"User cancelled"
    end if

    m.top.getScene().dialog = invalid
end sub

