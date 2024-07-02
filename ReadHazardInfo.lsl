
#define BUFFER_FORCE_SAVE TRUE
#define BUFFER_PRESERVE FALSE

key ncKey;
integer ncLineNum = 0;
string ncName = "HazardInfo";
key notecardKey = NULL_KEY;

string currentHazardName;
string bufferedJsonData;
list bufferedPolyPoints;


ConfigInit()
{
    if (llGetInventoryType(ncName) == INVENTORY_NONE)
    {
        llOwnerSay("Missing the note card named " + ncName);
        return;
    }

    key currentNotecardKey = llGetInventoryKey(ncName);
    if (currentNotecardKey == notecardKey)
        return;

    ClearHazardKeys();
    notecardKey = currentNotecardKey;
    ncLineNum = 0;
    ncKey = llGetNotecardLine(ncName, ncLineNum);
}

ClearHazardKeys()
{
    list keys = llLinksetDataFindKeys("^HAZARD_", 0, 0);
    integer i;
    for (i = 0; i < llGetListLength(keys); ++i)
    {
        llLinksetDataDelete(llList2String(keys, i));
    }
}

ProcessConfigLine(string line, integer forceSavingBuffer)
{
    if (line != EOF)
    {
        line = llStringTrim(line, STRING_TRIM);
        if (line == "")
            return;

        string sectionName = TestContainedWithin(line, "[", "]");
        if (sectionName != "")
        {
            if (currentHazardName != "")
                SaveBuffer();
            currentHazardName = sectionName;
            bufferedJsonData = "";
            bufferedPolyPoints = [];
        }
        else
        {
            list parts = llParseString2List(line, [ "=" ], []);
            if (llGetListLength(parts) == 2)
            {
                string parmName = llToLower(llStringTrim(llList2String(parts, 0), STRING_TRIM));
                string parmValue = llStringTrim(llList2String(parts, 1), STRING_TRIM);
                if (parmName != "dropzone")
                    bufferedJsonData = llJsonSetValue(bufferedJsonData, [ parmName ], parmValue);
                else
                {
                    string jsonArray = llJsonGetValue(bufferedJsonData, [ "dropzones" ]);
                    list dzInfo = [];
                    if (jsonArray != JSON_INVALID)
                        dzInfo = llJson2List(jsonArray);

                    dzInfo += [ parmValue ];
                    bufferedJsonData = llJsonSetValue(bufferedJsonData, [ "dropzones" ], llList2Json(JSON_ARRAY, dzInfo));
                }
            }
            else if (TestContainedWithin(line, "<", ">"))
            {
                bufferedPolyPoints += [ (vector)line ];
            }
        }
    }
    if (forceSavingBuffer)
    {
        SaveBuffer();
        ReportLSD("HAZARD_");
    }
}

string TestContainedWithin(string line, string firstChar, string lastChar)
{
    if ((llGetSubString(line, 0, 0) == firstChar) && (llGetSubString(line, -1, -1) == lastChar))
        return llGetSubString(line, 1, -2);
    return "";
}

SaveBuffer()
{
    if (currentHazardName != "")
    {
        if (bufferedJsonData != "")
        {
            if (llGetListLength(bufferedPolyPoints) > 0)
                bufferedJsonData = llJsonSetValue(bufferedJsonData, [ "points" ], llList2Json(JSON_ARRAY, bufferedPolyPoints));
            bufferedJsonData = llJsonSetValue(bufferedJsonData, [ "name" ], currentHazardName );
            llLinksetDataWrite("HAZARD_" + currentHazardName, bufferedJsonData);
        }
    }
}

ReportLSD(string regex)
{
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
        ConfigInit();
    }
    changed(integer change)
    {
        if (change && (CHANGED_INVENTORY || CHANGED_ALLOWED_DROP))
            ConfigInit();
    }
    dataserver(key id, string data) 
    {
        if (id == ncKey) 
        {
            while (data != EOF && data != NAK) 
            {
                ProcessConfigLine(data, BUFFER_PRESERVE);
                data = llGetNotecardLineSync(ncName, ++ncLineNum);
            }
            if (data == NAK)
            ncKey = llGetNotecardLine(ncName, ncLineNum);
            if (data == EOF)
            {
                ProcessConfigLine(EOF, BUFFER_FORCE_SAVE);
                llOwnerSay("End of file.");
            }
        }
    }    
}