module mutagen.catalog.artist;

import std.file : SpanMode, dirEntries, exists, isDir;
import std.path : baseName;

import mutagen.catalog.album;
import mutagen.catalog.image;

class Artist
{
public:
    string name;
    string dir;
    Album[] albums;

    Image image()
        => albums.length > 0 ? albums[0].image : Image.init;

    int getPlayCount()
    {
        int ret;
        foreach (album; albums)
            ret += album.getPlayCount();
        return ret;
    }

    static Artist fromDirectory(string path)
    {
        Artist ret = new Artist();
        ret.dir = path;
        ret.name = baseName(path);

        if (!exists(path) || !isDir(path))
            return ret;

        try
        {
            foreach (entry; dirEntries(path, SpanMode.shallow))
            {
                if (!entry.isDir)
                    continue;
                Album album = Album.fromDirectory(entry.name, ret);
                if (album.tracks.length > 0)
                    ret.albums ~= album;
            }
        }
        catch (Exception) { }
        return ret;
    }
}
