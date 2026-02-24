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
        if (data is null || data.length < 2)
            return Image(ImageType.Unknown, data);

        if (data[0] == 0xFF && data[1] == 0xD8)
            return Image(ImageType.JPEG, data);
        if (data.length >= 4 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47)
            return Image(ImageType.PNG, data);
        if (data[0] == 0x42 && data[1] == 0x4D)
            return Image(ImageType.BMP, data);
        if (data.length >= 3 && data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46)
            return Image(ImageType.GIF, data);
        if (data.length >= 8 && data[4] == 0x57 && data[5] == 0x45 && data[6] == 0x42 && data[7] == 0x50)
            return Image(ImageType.WebP, data);

        return Image(ImageType.Unknown, data);
    }

    static Image fromMime(ubyte[] data, string mime)
    {
        Image ret = fromData(data);
        if (ret.type != ImageType.Unknown || mime is null)
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