' Router.brs
' Scene-level navigation helper.

sub Router_goToHome(scene as Object)
    scene.currentView = "home"
end sub

sub Router_goToLogin(scene as Object)
    scene.currentView = "login"
end sub

sub Router_goToNowPlaying(scene as Object)
    scene.currentView = "nowplaying"
end sub
