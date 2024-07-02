#define TEST_BALL_DATA 45001
#define BALL_DATA_RESULTS 45002

list workingPolygon;

list adjRegionTest = [];
string adjacentRegionsJson = "";

GetRegionName(string varName, integer x, integer y)
{
    string url = "https://cap.secondlife.com/cap/0/b713fe80-283b-4585-af4d-a3b7d9a32492"
        + "?var=" + llEscapeURL(varName)
        + "&grid_x=" + llEscapeURL((string)x)
        + "&grid_y=" + llEscapeURL((string)y);
        
    key httpKey = llHTTPRequest(url, [], "");
    adjRegionTest += [ httpKey ];
}

FindAdjacentRegions()
{
    vector pos = llGetRegionCorner();
    pos /= 256.0;

    GetRegionName("North", ((integer)pos.x) + 0, ((integer)pos.y) + 1);
    llSleep(0.1);
    GetRegionName("South", ((integer)pos.x) + 0, ((integer)pos.y) - 1);
    llSleep(0.1);
    GetRegionName("East", ((integer)pos.x) + 1, ((integer)pos.y) + 0);
    llSleep(0.1);
    GetRegionName("West", ((integer)pos.x) - 1, ((integer)pos.y) + 0);
    llSleep(0.1);
}

string DetectedHazard(vector tp)
{
    list pointList;

    if ((tp.x < 0.0) && (llJsonGetValue(adjacentRegionsJson, [ "West" ]) == JSON_INVALID))
        return "OffSim-West";
    else if ((tp.x > 255.0) && (llJsonGetValue(adjacentRegionsJson, [ "East" ]) == JSON_INVALID))
        return "OffSim-East";
    else if ((tp.y < 0.0) && (llJsonGetValue(adjacentRegionsJson, [ "Soutn" ]) == JSON_INVALID))
        return "OffSim-South";
    else if ((tp.y > 255.0) && (llJsonGetValue(adjacentRegionsJson, [ "North" ]) == JSON_INVALID))
        return "OffSim-North";

    list keys = llLinksetDataFindKeys("HAZARD_", 0, 0);
    integer i;
    for (i = 0; i < llGetListLength(keys); ++i)
    {
        string name = llList2String(keys, i);
        string jsonInfo = llLinksetDataRead(name);
        string sectionType = llJsonGetValue(jsonInfo, [ "type" ]);
        if (llToLower(sectionType) != "drop zone")
        {
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
    }
    return "";
}

/*
The following copyright for isPointInPolygon2D is for code found at https://wiki.secondlife.com/wiki/IsPointInPolygon2D
*/
/*//-- LSL Port 2009 Void Singer --//*/
/*//-- Copyright (c) 1970-2003, Wm. Randolph Franklin	--//*/
/*
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimers.
2. Redistributions in binary form must reproduce the above copyright notice
   in the documentation and/or other materials provided with the distribution.
3. The name of W. Randolph Franklin may not be used to endorse or promote
   products derived from this Software without specific prior written permission

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 
*/
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
        else if (A2 == 0.0)
        {

        }
        else if (B2 == 0.0)
        {
            
        }
    }
    return ZERO_VECTOR;
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
integer pointOnSegment(vector pt, vector seg1, vector seg2)
{
    return (pt.x >= min(seg1.x, seg2.x) && pt.x <= max(seg1.x, seg2.x))
        && (pt.y >= min(seg1.y, seg2.y) && pt.y <= max(seg1.y, seg2.y));
}

default
{
    state_entry()
    {
        FindAdjacentRegions();
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if (num == TEST_BALL_DATA)
        {
            // msg is list of points, json_array.    id is avatar owning ball
            list points = llJson2List(llJsonGetValue(msg, [ "points" ]));
            msg = llJsonSetValue(msg, [ "points" ], JSON_DELETE);
            vector lastPoint = (vector)llList2String(points, -1);
            string touchArea = DetectedHazard(lastPoint);
            integer currentHole = (integer)llJsonGetValue(msg, [ "currentHole" ]);

            list data = [ 
                "ballStop", lastPoint,
                "hazard", llGetSubString(touchArea, llStringLength("HAZARD_"), -1) ];

            if (touchArea != "")
            {
                string hazardJson = llLinksetDataRead(touchArea);

                string hazardType = llJsonGetValue(hazardJson, [ "type" ]);
                list holes = llParseString2List(llJsonGetValue(hazardJson, [ "holes"]), [ ", ", ",", " " ], []);
                string dzInfo = llJsonGetValue(hazardJson, [ "dropzones"]);

                if (dzInfo != JSON_INVALID)
                {
                    list dzData = llJson2List(dzInfo);
                    integer i;
                    integer limit = llGetListLength(dzData);
                    for (i = 0; i < limit; ++i)
                    {
                        list parts = llParseString2List(llList2String(dzData, i), [ ", ", ","], []);
                        if ((integer)llList2String(parts, 0) == currentHole)
                        {
                            string dz = llLinksetDataRead("HAZARD_" + llStringTrim(llList2String(parts, 1), STRING_TRIM));
                            data += [ "dropZone", dz];
                        }
                    }
                }


                list crossingResults = ComputePolygonCrossing(touchArea, points);
                vector crossingPoint;

                if (llGetListLength(crossingResults) == 3)
                {
                    crossingPoint = llList2Vector(crossingResults, 2);
                    data += [ "crossing", crossingPoint ];
                    
                    string pinPosStr = llJsonGetValue(msg, [ "pinPos" ]);
                    if (pinPosStr != JSON_INVALID)
                    {
                        vector pinPos = (vector)pinPosStr;
                        float slope = 0.0;
                        if (pinPos.x - crossingPoint.x != 0.0)
                            slope = (pinPos.y - crossingPoint.y) / (pinPos.x - crossingPoint.x);

                        float yIntercept = crossingPoint.y - (slope * crossingPoint.x);

                        float A1 = pinPos.y - crossingPoint.y;
                        float B1 = crossingPoint.x - pinPos.x;
                        float C1 = (A1 * crossingPoint.x) + (B1 * crossingPoint.y);

                        list output = [
                            "slope", slope,
                            "yIntercept", yIntercept,
                            "stdForm", llList2Json(JSON_OBJECT, [ "A", A1, "B", B1, "C", C1 ])
                            ];
                        data += [ "behindTheLineFormula", llList2Json(JSON_OBJECT, output)];
                    }
                }
            }
            msg = llJsonSetValue(msg, [ "results" ], llList2Json(JSON_OBJECT, data));
            llMessageLinked(sender, BALL_DATA_RESULTS, msg, id);
        }
    }
    http_response(key id, integer status, list meta, string body)
    {
        integer pos = llListFindList(adjRegionTest, [ id ]);
        if ((pos > -1) && (status == 200))
        {
            if (llSubStringIndex(body, "{'error'") == -1)
            {
                list parts = llParseStringKeepNulls(body, [ "=" ], []);
                string section = llGetSubString(llList2String(parts, 0), 4, -1);
                string regName = llDumpList2String(llList2List(parts, 1, -1), "=");
                regName = llGetSubString(regName, 1, -3);
                adjacentRegionsJson = llJsonSetValue(adjacentRegionsJson, [ section ], regName);
            }
            adjRegionTest = llDeleteSubList(adjRegionTest, pos, pos);
        }
    }
}