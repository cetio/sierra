module mutagen.format.mp3.frame;

import std.stdio : File;
import std.string : toLower, toUpper;

struct Frame
{
    string id;
    uint size;
    ubyte[] data;

    this(File file, ubyte ver, out bool valid)
    {
        valid = false;
        if (file.tell() + 10 > file.size())
            return;

        ubyte[10] frameHeader = file.rawRead(new ubyte[10]);
        if (frameHeader[0] == 0)
            return;

        id = cast(string)frameHeader[0..4];
        if (ver == 4)
            size = (cast(uint)frameHeader[0] << 21)
                | (cast(uint)frameHeader[1] << 14)
                | (cast(uint)frameHeader[2] << 7)
                | cast(uint)frameHeader[3];
        else
            size = (cast(uint)frameHeader[4] << 24)
                | (cast(uint)frameHeader[5] << 16)
                | (cast(uint)frameHeader[6] << 8)
                | cast(uint)frameHeader[7];

        if (size == 0 || file.tell() + size > file.size())
            return;

        data = file.rawRead(new ubyte[](size));
        valid = true;
    }
}

package:

string parseTextFrame(ubyte[] data)
{
    if (data.length < 2)
        return "";

    ubyte encoding = data[0];
    if (encoding == 0 || encoding == 3)
        return cast(string)data[1..$];

    string ret;
    foreach (i; 1..data.length)
    {
        if (data[i] != 0)
            ret ~= cast(char)data[i];
    }
    return ret;
}

ubyte[] parseApic(ubyte[] data)
{
    ubyte[] ret;
    if (data.length < 4)
        return ret;

    size_t p = 1;
    while (p < data.length && data[p] != 0)
        p++;
    if (p >= data.length)
        return ret;
    p++;

    if (p >= data.length)
        return ret;
    p++;

    while (p < data.length && data[p] != 0)
        p++;
    if (p < data.length)
        p++;

    if (p < data.length)
        ret = data[p..$].dup;
    return ret;
}

void parseTxxx(ubyte[] data, out string desc, out string val)
{
    if (data.length < 2)
        return;
    ubyte encoding = data[0];
    size_t p = 1;
    size_t descEnd = p;

    if (encoding == 0 || encoding == 3) // Latin1 or UTF-8
    {
        while (descEnd < data.length && data[descEnd] != 0)
            descEnd++;
        desc = cast(string)data[p..descEnd];
        if (descEnd + 1 < data.length)
            val = cast(string)data[descEnd + 1..$];
    }
    else
    {
        desc = "";
        val = "";
    }
}

int parsePopCount(ubyte[] data)
{
    if (data.length == 0)
        return 0;
    int result = 0;
    foreach (b; data)
        result = (result << 8) | b;
    return result;
}
