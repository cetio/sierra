module mutagen.format.flac.picture;

import std.stdio : File;
import std.bitmanip : bigEndianToNative;

struct Picture
{
    uint pictureType;
    string mime;
    string description;
    uint width;
    uint height;
    uint depth;
    uint colors;
    ubyte[] data;

    this(File file)
    {
        ubyte[4] bytes = file.rawRead(new ubyte[4]);
        pictureType = bigEndianToNative!uint(bytes);

        bytes = file.rawRead(new ubyte[4]);
        uint mimeLen = bigEndianToNative!uint(bytes);
        if (mimeLen > 0)
            mime = cast(string)file.rawRead(new char[](mimeLen));

        bytes = file.rawRead(new ubyte[4]);
        uint descLen = bigEndianToNative!uint(bytes);
        if (descLen > 0)
            description = cast(string)file.rawRead(new char[](descLen));

        bytes = file.rawRead(new ubyte[4]);
        width = bigEndianToNative!uint(bytes);

        bytes = file.rawRead(new ubyte[4]);
        height = bigEndianToNative!uint(bytes);

        bytes = file.rawRead(new ubyte[4]);
        depth = bigEndianToNative!uint(bytes);

        bytes = file.rawRead(new ubyte[4]);
        colors = bigEndianToNative!uint(bytes);

        bytes = file.rawRead(new ubyte[4]);
        uint imageLen = bigEndianToNative!uint(bytes);
        if (imageLen > 0)
            data = file.rawRead(new ubyte[](imageLen));
    }
}
