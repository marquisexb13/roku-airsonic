' Auth.brs
' Subsonic token auth:
'   s = random salt
'   t = md5(password + s)
'

' Auth.brs

function Auth_buildToken(password as String) as Object
    salt = Auth_randomSalt(8)
    digest = CreateObject("roMessageDigest")
    digest.Setup("md5")
    digest.Update(password + salt)
    token = digest.Final()
	?"Auth salt="; salt; " token="; token
    return { s: salt, t: token }
end function

function Auth_randomSalt(n as Integer) as String
    chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    out = ""

    for i = 1 to n
        ' Rnd(range) returns 1..range (inclusive) 【2-1f8959】
        idx = Rnd(chars.Len()) - 1  ' convert to 0-based
        out = out + Mid(chars, idx + 1, 1)
    end for

    return out
end function
