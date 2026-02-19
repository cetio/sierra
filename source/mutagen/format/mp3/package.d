module mutagen.format.mp3;

public import mutagen.format.mp3.frame;

import std.stdio : File;
import std.string : toUpper;
import std.conv : to;
import mutagen.format.mp3.frame : parseApic, parseTxxx, parsePopCount, parseTextFrame;

class MP3
{
    File file;
    Frame[] frames;
    ubyte[] image;

    this(File file)
    {
        this.file = file;

        if (file.size() < 10)
        {
            this.file.close();
            return;
        }

        ubyte[10] header = file.rawRead(new ubyte[10]);
        if (header[0..3] != cast(ubyte[])("ID3"))
        {
            this.file.close();
            return;
        }

        uint tagSize = (cast(uint)header[6] << 21)
            | (cast(uint)header[7] << 14)
            | (cast(uint)header[8] << 7)
            | cast(uint)header[9];
        ubyte ver = header[3];
        long end = 10 + cast(long)tagSize;

        while (file.tell() + 10 <= end && file.tell() + 10 <= file.size())
        {
            bool valid;
            Frame frame = Frame(file, ver, valid);
            if (!valid)
                break;
            frames ~= frame;
        }

        foreach (ref frame; frames)
        {
            if (frame.id == "APIC" && image.length == 0)
                image = parseApic(frame.data);
        }

        this.file.close();
    }

    string opIndex(string str)
    {
        str = str.toUpper();
        foreach (ref frame; frames)
        {
            if (frame.id == "TXXX")
            {
                string desc;
                string value;
                parseTxxx(frame.data, desc, value);
                if (desc.toUpper() == str && value.length > 0)
                    return value;
            }
            else if (frame.id == "PCNT" && str == "PLAY_COUNT")
                return parsePopCount(frame.data).to!string;
            else if (frame.id == "TIT2" && str == "TITLE")
                return parseTextFrame(frame.data);
            else if (frame.id == "TPE1" && str == "ARTIST")
                return parseTextFrame(frame.data);
            else if (frame.id == "TALB" && str == "ALBUM")
                return parseTextFrame(frame.data);
            else if (frame.id == "TRCK" && str == "TRACKNUMBER")
                return parseTextFrame(frame.data);
            else if (frame.id == str)
                return parseTextFrame(frame.data);
        }
        return null;
    }

    // void opIndexAssign(string value, string tagName);

    // void opIndexAssign(Frame frame, string frameId);
}
