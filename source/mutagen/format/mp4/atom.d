module mutagen.format.mp4.atom;

import std.bitmanip : bigEndianToNative;
import std.string : toUpper;

struct Atom
{
    string type;
    uint size;
    long dataStart;
    ubyte[] data;

    this(ubyte[] headerData, long startPos)
    {
        size = bigEndianToNative!uint(headerData[0..4]);
        type = cast(string)headerData[4..8];
        dataStart = startPos + 8;
        if (size > 8)
            data = headerData[8..$];
    }
}

void parseFreeform(ref Atom atom, out string name, out string value)
{
    size_t pos = 0;
    name = "";
    value = "";

    while (pos + 8 <= atom.data.length)
    {
        ubyte[4] sizeBytes = atom.data[pos..pos + 4];
        uint subSize = bigEndianToNative!uint(sizeBytes);
        if (subSize < 8 || pos + subSize > atom.data.length)
            break;

        string subType = cast(string)atom.data[pos + 4..pos + 8];
        ubyte[] payload = atom.data[pos + 8..pos + subSize];

        if (subType == "name" && payload.length > 4)
            name = cast(string)payload[4..$];
        else if (subType == "data" && payload.length > 8)
            value = cast(string)payload[8..$];

        pos += subSize;
    }
}

ubyte[] parseCover(ref Atom atom)
{
    ubyte[] ret;
    size_t pos = 0;
    while (pos + 8 <= atom.data.length)
    {
        ubyte[4] sizeBytes = atom.data[pos..pos + 4];
        uint subSize = bigEndianToNative!uint(sizeBytes);
        if (subSize < 8 || pos + subSize > atom.data.length)
            break;

        string subType = cast(string)atom.data[pos + 4..pos + 8];
        if (subType == "data" && subSize > 16)
        {
            ret = atom.data[pos + 16..pos + subSize].dup;
            break;
        }
        pos += subSize;
    }
    return ret;
}
