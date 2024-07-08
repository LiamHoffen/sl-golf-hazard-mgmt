#define TEST_BALL_DATA 45001
#define BALL_DATA_RESULTS 45002

#define HAZARD_PROCESSING_COMM_CHANNEL 123

key getUrlKey;
string myURL;
list httpRequests = [];

default
{
    state_entry()
    {
        llListen(HAZARD_PROCESSING_COMM_CHANNEL, "", NULL_KEY, "");
        getUrlKey = llRequestURL();
    }
    on_rez(integer param)
    {
        llResetScript();
    }
    changed(integer change)
    {
        if (change & (CHANGED_OWNER | CHANGED_REGION | CHANGED_REGION_START))
            llResetScript();
    }
    http_request(key id, string method, string body)
    {
        if (id == getUrlKey)
        {
            if (method == URL_REQUEST_GRANTED)
                myURL = body;
            else
            {
                llSleep(5.0);
                getUrlKey = llRequestURL();
            }
        }
        else if (method == "POST")
        {
            httpRequests += [ id ];
            llOwnerSay(body);
            llMessageLinked(LINK_THIS, TEST_BALL_DATA, body, id);
        }
    }
    listen(integer channel, string name, key id, string msg)
    {
        if (msg == "REPORT_HAZARD_URL")
            llRegionSayTo(id, channel, llList2Json(JSON_OBJECT, [ "myURL", myURL ]));
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == BALL_DATA_RESULTS)
        {
            llSay(0, msg);
            integer pos = llListFindList(httpRequests, [ id ]);
            if (pos > -1)
                httpRequests = llDeleteSubList(httpRequests, pos, pos);
            llHTTPResponse(id, 200, msg);
        }
    }
}
