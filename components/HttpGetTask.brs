sub init()
    m.top.functionName = "run"   ' THIS IS CRITICAL
end sub


sub run()
    url = m.top.requestUrl

    xfer = CreateObject("roUrlTransfer")
    xfer.SetUrl(url)

    rsp = xfer.GetToString()

    if rsp = invalid then
        m.top.error = "Request failed"
    else
        m.top.response = rsp
    end if
end sub
