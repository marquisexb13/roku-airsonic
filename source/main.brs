' pkg:/source/main.brs
sub Main()
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("PlaylistScene")
    if scene = invalid then
        print "[Main] Failed to create PlaylistScene"
        return
    end if

    ' IMPORTANT: There is no SetRoot() on roSGScreen.
    ' CreateScene() already sets the root scene.
    screen.Show()

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
            exit while
        end if
    end while
end sub
