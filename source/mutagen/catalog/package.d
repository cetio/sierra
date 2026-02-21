module mutagen.catalog;

import std.file : SpanMode, dirEntries, exists, isDir, isFile, read;
import std.path : baseName, dirName, extension;
import std.string : toLower;

public import mutagen.catalog.album;
public import mutagen.catalog.artist;
public import mutagen.catalog.track;

string findCoverArt(string dir)
{
    if (!exists(dir) || !isDir(dir))
        return null;

    string[] imageExts = [".jpg", ".jpeg", ".png", ".bmp", ".webp"];
    try
    {
        foreach (entry; dirEntries(dir, SpanMode.shallow))
        {
            if (!entry.isFile)
                continue;
            string ext = extension(entry.name).toLower();
            foreach (imgExt; imageExts)
            {
                if (ext == imgExt)
                    return entry.name;
            }
        }
    }
    catch (Exception)
    {
    }
    return null;
}

ubyte[] readCoverArt(string dir)
{
    string path = findCoverArt(dir);
    if (path.length == 0)
        return null;
    try
        return cast(ubyte[])read(path);
    catch (Exception)
        return null;
}