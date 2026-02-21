module mutagen.catalog.album;

import std.algorithm : sort;
import std.conv;
import std.file : SpanMode, dirEntries, exists, isDir, isFile;
import std.path : baseName, extension;
import std.stdio : File;
import std.string : indexOf, strip, toLower;

import mutagen.audio;
import mutagen.catalog.artist;
import mutagen.catalog.image;
import mutagen.catalog.track;

class Album
{
public:
    string name;
    string dir;
    Track[] tracks;
    Artist artist;

    Image image()
        => tracks.length > 0 ? tracks[0].image : Image.init;

    int getPlayCount()
    {
        int ret;
        foreach (track; tracks)
            ret += track.getPlayCount();
        return ret;
    }

    static Album fromDirectory(string path, Artist artist = null)
    {
        Album ret = new Album();
        ret.dir = path;
        ret.name = baseName(path);
        ret.artist = artist;

        if (!exists(path) || !isDir(path))
            return ret;

        try
        {
            foreach (entry; dirEntries(path, SpanMode.shallow))
            {
                if (!entry.isFile)
                    continue;

                string ext = extension(entry.name).toLower();
                if (!isAudioExt(ext))
                    continue;

                Track track = Track.fromFile(entry.name, ret);
                if (track.audio.data.hasValue)
                {
                    ret.tracks ~= track;
                    
                    if (ret.name == baseName(path))
                    {
                        string[] albumTags = track.audio["ALBUM"];
                        if (albumTags.length > 0)
                            ret.name = albumTags[0];
                    }
                }
            }
        }
        catch (Exception) { }

        ret.tracks.sort!((a, b) => a.number < b.number ||
            (a.number == b.number && a.audio.file.name < b.audio.file.name));
        return ret;
    }

private:
    static bool isAudioExt(string ext)
    {
        switch (ext)
        {
        case ".flac", ".mp3", ".m4a", ".mp4", ".m4b", ".m4p", ".opus", ".ogg":
            return true;
        default:
            return false;
        }
    }
}
