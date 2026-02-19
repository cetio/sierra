module mutagen.format.flac.vorbis;

import std.stdio;
import std.string;

struct Vorbis
{
    string vendor;
    string[string[]] tags;

    this(File file)
    {
        vendor = cast(string)file.rawRead(
            new char[](file.rawRead(new uint[1])[0])
        );

        foreach (i; 0..(file.rawRead(new uint[1])[0]))
        {
            uint len = file.rawRead(new uint[1])[0];
            string str = cast(string)file.rawRead(new char[](len));

            string[] parts = str.split('=');
            if (parts.length > 1)
                tags[parts[0].toUpper] ~= parts[1];
        }
    }
}
