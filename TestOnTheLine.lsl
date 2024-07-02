key pt1Key = "46b98532-067e-1d4c-e0ba-be89a28ba824";
key pt2Key = "0ca03760-5011-bb98-8af5-da4552c2fc92";

ComputeDistance(vector p1, vector p2)
{
    vector myPos = llGetPos();
    float dist;
    list debug;

    if (p2.x == p1.x)
    {
        dist = llFabs(myPos.x - p2.x);
        debug += [ "Dist(2):" + (string)dist + " meters"];
    }
    else if (p2.y == p1.y)
    {
        dist = llFabs(myPos.y - p2.y);
        debug += [ "Dist(3):" + (string)dist + " meters"];
    }
    else
    {
        float m = (p2.y - p1.y) / (p2.x - p1.x);
        float b = p1.y - m * p1.x;
        float y2 = m * p2.x + b;

        dist = llFabs((-m) * myPos.x + 1 * myPos.y - b) / llSqrt(llPow(m, 2) + 1.0);
        debug += [ "p1=" + (string)p1, "p2=" + (string)p2 ] + debug + [ "Dist(1): " + (string)dist + " meters" ];
    }
    llSetText(llDumpList2String(debug, "\n"), <1, 1, 0>, 1.0);
}

default
{
    state_entry()
    {
        llSetTimerEvent(1.0);
    }
    timer()
    {
        list info = llGetObjectDetails(pt1Key, [ OBJECT_POS ]);
        vector p1 = llList2Vector(info, 0);
        info = llGetObjectDetails(pt2Key, [ OBJECT_POS ]);
        vector p2 = llList2Vector(info, 0);

        ComputeDistance(p1, p2);
    }
}