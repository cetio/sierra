module mutagen.catalog.image;

import std.string : toLower;

enum ImageType
{
    Unknown,
    JPEG,
    PNG,
    BMP,
    GIF,
    WebP
}

struct Image
{
    ImageType type;
    ubyte[] data;

    bool hasData() const
        => data != null;

    static Image fromData(ubyte[] data)
    {
        Image ret;
        ret.data = data;
        if (data is null || data.length < 2)
            return ret;

        if (data[0] == 0xFF && data[1] == 0xD8)
            ret.type = ImageType.JPEG;
        else if (data.length >= 4 && data[0] == 0x89 && data[1] == 0x50 &&
                 data[2] == 0x4E && data[3] == 0x47)
            ret.type = ImageType.PNG;
        else if (data[0] == 0x42 && data[1] == 0x4D)
            ret.type = ImageType.BMP;
        else if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46)
            ret.type = ImageType.GIF;
        else if (data.length >= 8 && data[4] == 0x57 && data[5] == 0x45 &&
                 data[6] == 0x42 && data[7] == 0x50)
            ret.type = ImageType.WebP;

        return ret;
    }

    static Image fromMime(ubyte[] data, string mime)
    {
        Image ret = fromData(data);
        if (ret.type != ImageType.Unknown || mime == null)
            return ret;

        switch (mime.toLower())
        {
        case "image/jpeg":
        case "image/jpg":
            ret.type = ImageType.JPEG;
            break;

        case "image/png":
            ret.type = ImageType.PNG;
            break;

        case "image/gif":
            ret.type = ImageType.GIF;
            break;

        case "image/bmp":
            ret.type = ImageType.BMP;
            break;

        case "image/webp":
            ret.type = ImageType.WebP;
            break;

        default:
            ret.type = ImageType.Unknown;
            break;
        }

        return ret;
    }
}