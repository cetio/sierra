module mutagen.audio;

import std.path;
import std.stdio;
import std.string;
import std.conv;
import std.variant;

import mutagen.catalog.image;
import mutagen.format.flac;
import mutagen.format.mp3;
import mutagen.format.mp4;

bool isAudio(string path)
{
    string ext = extension(path);
    return ext == ".flac" || ext == ".mp3" || ext == ".m4a" || ext == ".mp4" || ext == ".aac";
}

struct Audio
{
    File file;
    Variant data;

    this(File file)
    {
        this.file = file;

        switch (extension(file.name).toLower())
        {
            case ".flac":
                data = new FLAC(file);
                break;
            case ".mp3":
                data = new MP3(file);
                break;
            case ".m4a":
            case ".mp4":
            case ".aac":
                data = new MP4(file);
                break;
            default:
                break;
        }

        file.close();
    }

    string[] opIndex(string str) const
    {
        if (data.type == typeid(FLAC))
            return data.get!FLAC[str];
        else if (data.type == typeid(MP3))
            return data.get!MP3[str];
        else if (data.type == typeid(MP4))
            return data.get!MP4[str];

        return null;
    }

    // TODO: Should use `string[]` and update the appropriate format data (ie: size) to ensure proper write.
    // TODO: Add `flush()` to write changes to file.
    string opIndexAssign(string val, string tag)
    {
        if (data.type == typeid(FLAC))
            return data.get!FLAC[tag] = val;
        else if (data.type == typeid(MP3))
            return data.get!MP3[tag] = val;
        else if (data.type == typeid(MP4))
            return data.get!MP4[tag] = val;

        return val;
    }

    Image image() const
    {
        if (data.type == typeid(FLAC))
            return data.get!FLAC.image;
        else if (data.type == typeid(MP3))
            return data.get!MP3.image;
        else if (data.type == typeid(MP4))
            return data.get!MP4.image;

        return Image.init;
    }
}
