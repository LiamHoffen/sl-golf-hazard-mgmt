integer golfListen;
key lastDetectedBallKey = NULL_KEY;
vector lastBallPos = ZERO_VECTOR;
vector ballPos;
float myballdistance;

vector GetFootPos()
{
    vector size = llGetAgentSize(llGetOwner());
    vector pos = llGetPos() - <0, 0, size.z / 2.0>;
    return pos;
}

string right(string src, string divider) {
    integer index = llSubStringIndex( src, divider );
    if(~index)
        return llDeleteSubString( src, 0, index + llStringLength(divider) - 1);
    return src;
}
string left(string src, string divider) {
    integer index = llSubStringIndex( src, divider );
    if(~index)
        return llDeleteSubString( src, index, -1);
    return src;
}

integer posPoints;
ClearPosPoints()
{
    list result;
    posPoints = 0;
    do
    {
        result = llLinksetDataFindKeys("^BP_", 0, 1);
        if (llGetListLength(result))
            llLinksetDataDelete(llList2String(result, 0));
    } while (llGetListLength(result) > 0);
}

ReportPosData()
{
    list points;
    integer i;

    for (i = 0; i < posPoints; ++i)
        points += [ llLinksetDataRead("BP_" + (string)i) ];

    integer strLen = llStringLength(llDumpList2String(points, "\n"));
    llSay(0, "sending " + (string)strLen + " bytes");
    llSay(123, llDumpList2String(points, "\n"));
}

string Reduce(float val)
{
    val = (float)(llRound(val * 10) / 10.0);
    string output = (string)val;
    integer pos = llSubStringIndex(output, ".");
    if (pos > -1)
        output = llGetSubString(output, 0, pos + 1);
    return output;
}

string GetVecLimited(vector ballPos)
{
    return "<" +  Reduce(ballPos.x) +  ", " +  Reduce(ballPos.y) +  ", " +  Reduce(ballPos.z) + ">";

}

default
{
    state_entry()
    {
        golfListen = llListen(1112223334,"", NULL_KEY, "");
    }
    timer()
    {
        if (lastDetectedBallKey != NULL_KEY)
        {
            if (lastBallPos == ZERO_VECTOR)
            {
                list details = llGetObjectDetails(lastDetectedBallKey, [ OBJECT_POS, OBJECT_PHYSICS ]);
                if (llGetListLength(details) == 2)
                {
                    ballPos = llList2Vector(details, 0);
                    llLinksetDataWrite("BP_" + (string)(posPoints++), GetVecLimited(ballPos));
                    integer physics = llList2Integer(details, 1);
                    if (!physics)
                    {
                        lastBallPos = ballPos;
                        llSetTimerEvent(0.0);
                        llSay(0, "Saw ball end at " + (string)ballPos);
                        ReportPosData();
                    }
                    myballdistance = llVecDist(ballPos, GetFootPos());
                }
                else
                {
                    llSay(0, "can't see the ball data");
                }
            }
            else
            {
                myballdistance = llVecDist( GetFootPos() , lastBallPos);
            }
        }
    }
    listen(integer channel, string name, key id, string message)  
    {
        llSay(0, message);
        string left = left(message,"|");
        string right = right(message,"|");
        string farleft = left(right,"|");
        string farright = right(right,"|");

        if(left==llGetOwner())
        {
            if(farleft=="SWING")
            {
                ClearPosPoints();
                llResetTime();
                lastDetectedBallKey = NULL_KEY;
                lastBallPos = ZERO_VECTOR;
                llSetTimerEvent(0.25);
                llSleep(0.1);
                llSensorRepeat("","",SCRIPTED,96,PI,0.01);
            }
        }
    }
    sensor(integer detected)
    {
        while(detected--)
        {
            string checkname = llDetectedName(detected);
            if(checkname == "Golf Ball" && llGetOwner() == llDetectedOwner(detected) && (lastDetectedBallKey == NULL_KEY))
            {
                llSay(0, "found ball");
                lastDetectedBallKey = llDetectedKey(detected);
                lastBallPos = ZERO_VECTOR;
                llSensorRemove();
            }
        }
    }
}