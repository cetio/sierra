module mutagen.catalog.track;

import std.conv;
import std.stdio : File;
import std.file;
import std.path : extension, dirName;
import std.string;

import mutagen.audio;
import mutagen.catalog.album;
import mutagen.catalog.image;

class Track
{
public:
    Audio audio;
    Album album;
    string name;
    int number;

    this(Audio audio)
    {
        this.audio = audio;
        string[] title = audio["TITLE"];
        if (title.length > 0)
            this.name = title[0];

        string[] trackNum = audio["TRACKNUMBER"];
        if (trackNum.length > 0)
        {
            string str = trackNum[0];
            ptrdiff_t slash = str.indexOf('/');
            if (slash > 0)
                str = str[0..slash];
            
            str = str.strip();
            if (str.length > 0)
            {
                try
                    this.number = str.to!int;
                catch (Exception) { }
            }
        }
    }

    static Track fromFile(string path, Album album = null)
    {
        File file = File(path, "rb");
        Track ret = new Track(Audio(file));
        ret.album = album;
        return ret;
    }

    Image image()
    {
        Image img = audio.image;
        if (img.hasData())
            return img;

        string dir = dirName(audio.file.name);
        if (!exists(dir) || !isDir(dir))
            return img;

        try
        {
            foreach (entry; dirEntries(dir, SpanMode.shallow))
            {
                if (!entry.isFile)
                    continue;

                string ext = extension(entry.name).toLower();
                if (ext == ".jpg" || ext == ".jpeg" || ext == ".png")
                    return Image.fromData(cast(ubyte[])read(entry.name));
            }
        }
        catch (Exception) { }

        return img;
    }

    int getPlayCount()
    {
        if (!audio.data.hasValue)
            return 0;

        string[] tags = audio["PLAY_COUNT"];
        if (tags is null)
            tags = audio["PCNT"];
        
        if (tags is null || tags.length == 0)
            return 0;

        try
            return tags[0].strip().to!int;
        catch (Exception)
            return 0;
    }

    bool setPlayCount(int count)
    {
        if (!audio.data.hasValue)
            return false;

        string str = count.to!string;
        if (audio["PCNT"] != null)
            audio["PCNT"] = str;
        else
            audio["PLAY_COUNT"] = str;
        return true;
    }
}
