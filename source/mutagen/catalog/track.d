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

        string[] titles = audio["TITLE"];
        this.name = titles.length > 0 ? titles[0] : null;

        string str = audio["TRACKNUMBER"].length > 0 ? audio["TRACKNUMBER"][0] : null;
        if (str !is null)
        {
            ptrdiff_t slash = str.indexOf('/');
            if (slash > 0)
                str = str[0..slash];
        }

        try
            this.number = str !is null ? str.strip().to!int : 0;
        catch (Exception)
            this.number = 0;
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

        string str;
        if (audio["PLAY_COUNT"].length > 0)
            str = audio["PLAY_COUNT"][0];
        else if (audio["PCNT"].length > 0)
            str = audio["PCNT"][0];
        else
            return 0;

        try
            return str.strip().to!int;
        catch (Exception)
            return 0;
    }

    bool setPlayCount(int count)
    {
        if (!audio.data.hasValue)
            return false;

        string[] pcnt = audio["PCNT"];
        if (pcnt.length > 0)
            audio["PCNT"] = count.to!string;
        else
            audio["PLAY_COUNT"] = count.to!string;
        return true;
    }
}
