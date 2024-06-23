#define TEST_BALL_DATA 45001

list workingPolygon;

// Data lists set up by hand now, with SetUpData pushing the data to LSD.
// This will later move to reading from a course-owner source to define these areas.
list intoWater = [
    <1.0, 0.0, 0.0>,
    <1.0, 255.0, 0.0>,
    <0.0, 255.0, 0.0>,
    <0.0, 0.0, 0.0>
    ];
    
list waterBehind1 = [
    <0.0, 135.0, 0.0>,
    <40.0, 135.0, 0.0>,
    <40.0, 143.0, 0.0>,
    <0.0, 143.0, 0.0>
    ];

list pointsFlown = [
    <2, 2, 0>,
    <10, 4, 0>,
    <25, 15, 0>,
    <0.5, 25, 0>
];


SetUpData()
{
    string json = llList2Json(JSON_OBJECT, [ "name", "West Water", "type", "Water" ]); // , "points", 0 ]);
    json = llJsonSetValue(json, [ "points" ], llList2Json(JSON_ARRAY, intoWater));
    llLinksetDataWrite("HAZARD_001", json);

    json = llList2Json(JSON_OBJECT, [ "name", "Water Behind 1", "type", "Water" ]); // , "points", 0 ]);
    json = llJsonSetValue(json, [ "points"], llList2Json(JSON_ARRAY, waterBehind1));
    llLinksetDataWrite("HAZARD_002", json);
}

float min(float v1, float v2)
{
    if (v1 < v2)
        return v1;
    return v2;
}
float max(float v1, float v2)
{
    if (v1 > v2)
        return v1;
    return v2;
}

string DetectedHazard(vector tp)
{
    list pointList;

    if (tp.x < 0.0)
        return "OffSim-West";
    else if (tp.x > 255.0)
        return "OffSim-East";
    else if (tp.y < 0.0)
        return "OffSim-South";
    else if (tp.y > 255.0)
        return "OffSim-North";

    list keys = llLinksetDataFindKeys("HAZARD_", 0, 0);
    integer i;
    for (i = 0; i < llGetListLength(keys); ++i)
    {
        string name = llList2String(keys, i);
        string jsonInfo = llLinksetDataRead(name);
        pointList = llJson2List(llJsonGetValue(jsonInfo, [ "points" ]));
        integer i;
        integer limit = llGetListLength(pointList);
        for (i = 0; i < limit; ++i)
        {
            vector p = (vector)llList2String(pointList, i);
            pointList = llListReplaceList(pointList, [ p ], i, i);
        }
        if (isPointInPolygon2D(pointList, tp))
        {
            workingPolygon = pointList;
            return name;
        }
    }
    return "";
}

// isPointInPolygon2D source found in LSL examples, but no documentation exists for where it was found.
integer isPointInPolygon2D( list vLstPolygon, vector vPosTesting )
{
    integer vBooInPlygn;
    integer vIntCounter = -llGetListLength(vLstPolygon);
    vector  vPosVertexA = llList2Vector( vLstPolygon, vIntCounter );
    vector  vPosVertexB;
 
    while (vIntCounter)
    {
        vPosVertexB = vPosVertexA;

        vPosVertexA = llList2Vector( vLstPolygon, ++vIntCounter );
        if ((vPosVertexA.y > vPosTesting.y) ^ (vPosVertexB.y > vPosTesting.y))
        {
            if (vPosTesting.x < (vPosVertexB.x - vPosVertexA.x) * (vPosTesting.y - vPosVertexA.y) / (vPosVertexB.y - vPosVertexA.y) +  vPosVertexA.x )
            {
                vBooInPlygn = !vBooInPlygn;
            }
        }
    }
    return vBooInPlygn;
}

list ComputePolygonCrossing(string areaName, list ballPoints)
{
    list results;

    // walk list of ballPoints, starting with the last, and find the first pair that are in and outside the polygon
    integer i;
    integer limit = llGetListLength(ballPoints);
    for (i = limit - 2; i >= 0; --i)
    {
        if (!isPointInPolygon2D(workingPolygon, (vector)llList2String(ballPoints, i)))
        {
            vector lineSegment2PolygonIntersection = FindIntersection((vector)llList2String(ballPoints, i), (vector)llList2String(ballPoints, i + 1));
            results = [ (vector)llList2String(ballPoints, i), (vector)llList2String(ballPoints, i + 1), lineSegment2PolygonIntersection ];
            return results;
        }
    }
    return results;
}

vector FindIntersection(vector p1, vector p2)
{
    float A1 = p2.y - p1.y;
    float B1 = p1.x - p2.x;
    float C1 = (A1 * p1.x) + (B1 * p1.y);

    integer vIntCounter = -llGetListLength(workingPolygon);
    vector  vPosVertexA = llList2Vector( workingPolygon, vIntCounter );
    vector  vPosVertexB;
 
    while (vIntCounter)
    {
        vPosVertexB = vPosVertexA;

        vPosVertexA = llList2Vector( workingPolygon, ++vIntCounter );

        float A2 = vPosVertexB.y - vPosVertexA.y;
        float B2 = vPosVertexA.x - vPosVertexB.x;
        float C2 = (A2 * vPosVertexA.x) + (B2 * vPosVertexA.y);

        float det = A1 * B2 - A2 * B1;
        if (det != 0)
        {
            vector answer;
            answer.x = (B2 * C1 - B1 * C2) / det;
            answer.y = (A1 * C2 - A2 * C1) / det;

            if (pointOnSegment(answer, p1, p2))
                return answer;
        }
    }
    return ZERO_VECTOR;
}

integer pointOnSegment(vector pt, vector seg1, vector seg2)
{
    return (pt.x >= min(seg1.x, seg2.x) && pt.x <= max(seg1.x, seg2.x))
        && (pt.y >= min(seg1.y, seg2.y) && pt.y <= max(seg1.y, seg2.y));
}

ReportLSD(string regex)
{
    return;
    list keys = llLinksetDataFindKeys(regex, 0, 0);
    integer i;
    for (i = 0; i < llGetListLength(keys); ++i)
    {
        string name = llList2String(keys, i);
        llOwnerSay(name + "\n" + llLinksetDataRead(name));
    }
}

default
{
    state_entry()
    {
        SetUpData();
        ReportLSD("^HAZARD_");

        llMessageLinked(LINK_THIS, TEST_BALL_DATA, llList2Json(JSON_ARRAY, pointsFlown), llGetOwner());
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == TEST_BALL_DATA)
        {
            // msg is list of points, json_array.    id is avatar owning ball
            list points = llJson2List(msg);
            vector lastPoint = (vector)llList2String(points, -1);
            string touchArea = DetectedHazard(lastPoint);
            list data = [ "aviId", id, "hazard", touchArea ];

            if (touchArea != "")
            {
                list crossingResults = ComputePolygonCrossing(touchArea, points);
                if (llGetListLength(crossingResults) == 3)
                {
                    data += [ 
                        "crossing", llList2Vector(crossingResults, 2),
                        "ptOutsidePolygon", llList2Vector(crossingResults, 0),
                        "ptInsidePolygon", llList2Vector(crossingResults, 1)
                        ];
                }
            }
            llOwnerSay(llList2Json(JSON_OBJECT, data));
        }
    }
}