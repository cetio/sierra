module turnt.widget.vinyl;

import std.conv : to;
import std.math : abs, cos, fmin, fmod, sin, PI;
import std.variant : Variant;

import cairo.context;
import cairo.global;
import cairo.pattern;
import cairo.surface;
import cairo.types;
import gdk.memory_texture;
import gdkpixbuf.pixbuf : Pixbuf;
import gdkpixbuf.pixbuf_loader : PixbufLoader;
import gdkpixbuf.types : InterpType;
import glib.bytes;
import glib.global : timeoutAdd;
import gtk.drawing_area;
import gtk.event_controller_motion;
import gtk.types : Align, Overflow;
import gtk.widget : Widget;

import mutagen.catalog : Artist, Album, Track, findCoverArt;

private Surface[string] coverCache;

Surface loadCoverSurface(string dir, int size)
{
    if (dir in coverCache)
        return coverCache[dir];

    string path = findCoverArt(dir);
    if (path.length == 0)
    {
        coverCache[dir] = null;
        return null;
    }

    try
    {
        Pixbuf pb = Pixbuf.newFromFileAtScale(path, size, size, true);
        if (pb is null)
        {
            coverCache[dir] = null;
            return null;
        }
        Surface srf = pixbufToSurface(pb);
        coverCache[dir] = srf;
        return srf;
    }
    catch (Exception)
    {
        coverCache[dir] = null;
        return null;
    }
}

Surface pixbufToSurface(Pixbuf pb)
{
    if (pb is null)
        return null;

    int w = pb.getWidth();
    int h = pb.getHeight();
    int channels = pb.getNChannels();
    int srcStride = pb.getRowstride();
    const(ubyte)* src = pb.readPixels();

    if (src is null || w <= 0 || h <= 0)
        return null;

    Surface srf = imageSurfaceCreate(Format.Argb32, w, h);
    if (srf is null)
        return null;

    int dstStride = imageSurfaceGetStride(srf);
    ubyte* dst = imageSurfaceGetData(srf);
    if (dst is null)
        return null;

    srf.flush();

    for (int y = 0; y < h; y++)
    {
        const(ubyte)* sRow = src + y * srcStride;
        ubyte* dRow = dst + y * dstStride;
        for (int x = 0; x < w; x++)
        {
            ubyte r = sRow[x * channels + 0];
            ubyte g = sRow[x * channels + 1];
            ubyte b = sRow[x * channels + 2];
            ubyte a = (channels == 4) ? sRow[x * channels + 3] : 255;
            dRow[x * 4 + 0] = cast(ubyte)(b * a / 255);
            dRow[x * 4 + 1] = cast(ubyte)(g * a / 255);
            dRow[x * 4 + 2] = cast(ubyte)(r * a / 255);
            dRow[x * 4 + 3] = a;
        }
    }

    srf.markDirty();
    return srf;
}

string toRoman(int n)
{
    if (n <= 0 || n > 3999)
        return "";
    string result;
    immutable int[] vals =    [1000, 900, 500, 400, 100,  90,  50,  40,  10,   9,   5,   4,  1];
    immutable string[] syms = ["M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"];
    foreach (i, v; vals)
    {
        while (n >= v)
        {
            result ~= syms[i];
            n -= v;
        }
    }
    return result;
}

void drawVinylDisc(
    Context cr,
    double cx, double cy,
    double radius, double angle,
    Surface labelSurface = null,
    int labelW = 0, int labelH = 0,
    int trackNum = 0
)
{
    cr.save();
    cr.translate(cx, cy);
    cr.rotate(angle);

    cr.setSourceRgb(0.02, 0.02, 0.02);
    cr.arc(0, 0, radius, 0, PI * 2);
    cr.fill();

    cr.setSourceRgba(0.35, 0.35, 0.35, 0.15);
    cr.setLineWidth(1.0);
    cr.arc(0, 0, radius * 0.97, 0, PI * 2);
    cr.stroke();

    for (double r = radius * 0.36; r < radius * 0.95; r += 1.8)
    {
        double alpha = 0.14 + 0.10 * sin(r * 0.7);
        cr.setSourceRgba(0.45, 0.45, 0.45, alpha);
        cr.setLineWidth(0.5);
        cr.arc(0, 0, r, 0, PI * 2);
        cr.stroke();
    }

    cr.setSourceRgba(0.6, 0.6, 0.6, 0.08);
    cr.setLineWidth(radius * 0.5);
    cr.arc(0, 0, radius * 0.65, -0.25, 0.25);
    cr.stroke();

    cr.setSourceRgba(0.5, 0.5, 0.5, 0.04);
    cr.setLineWidth(radius * 0.3);
    cr.arc(0, 0, radius * 0.55, PI - 0.4, PI + 0.15);
    cr.stroke();

    double labelRadius = radius * 0.32;

    cr.save();
    cr.arc(0, 0, labelRadius, 0, PI * 2);
    cr.clip();

    if (labelSurface !is null && labelW > 0 && labelH > 0)
    {
        double scale = (labelRadius * 2.0) / fmin(cast(double)labelW, cast(double)labelH);
        cr.translate(-labelW * scale / 2.0, -labelH * scale / 2.0);
        cr.scale(scale, scale);
        cr.setSourceSurface(labelSurface, 0, 0);
        cr.paint();
    }
    else
    {
        cr.setSourceRgb(0.15, 0.15, 0.15);
        cr.paint();
    }

    cr.restore();

    cr.setSourceRgba(0.7, 0.7, 0.7, 0.55);
    cr.setLineWidth(1.5);
    cr.arc(0, 0, labelRadius, 0, PI * 2);
    cr.stroke();

    cr.setSourceRgb(0.05, 0.05, 0.05);
    cr.arc(0, 0, radius * 0.04, 0, PI * 2);
    cr.fill();

    if (trackNum > 0)
    {
        string roman = toRoman(trackNum);
        if (roman.length > 0)
        {
            double fontSize = radius * 0.20;
            if (fontSize < 5) fontSize = 5;
            cr.selectFontFace("Sans", FontSlant.Normal, FontWeight.Bold);
            cr.setFontSize(fontSize);
            TextExtents ext;
            cr.textExtents(roman, ext);
            double ty = -radius * 0.68;
            double tx = -ext.width / 2 - ext.xBearing;

            cr.save();
            cr.moveTo(tx, ty);
            cr.textPath(roman);
            cr.clip();

            cr.setSourceRgba(0.72, 0.72, 0.72, 0.85);
            cr.paint();

            for (double r = radius * 0.36; r < radius * 0.95; r += 1.8)
            {
                double alpha = 0.25 + 0.15 * sin(r * 0.7);
                cr.setSourceRgba(0.0, 0.0, 0.0, alpha);
                cr.setLineWidth(0.5);
                cr.arc(0, 0, r, 0, PI * 2);
                cr.stroke();
            }

            cr.restore();
        }
    }

    cr.restore();
}

enum VinylKind
{
    Artist,
    Album,
    Track
}

class Vinyl : DrawingArea
{
private:
    uint hoverGen;
    enum pad = 8;

    void onDraw(DrawingArea, Context cr, int w, int h)
    {
        double maxR = fmin(cast(double)(w - 2), cast(double)(h - 2)) * 0.5;
        double cx = w / 2.0;
        double cy = h / 2.0;

        cr.setSourceRgb(0.10, 0.08, 0.07);
        cr.arc(cx, cy, maxR, 0, PI * 2);
        cr.fill();

        drawVinylDisc(cr, cx, cy, maxR * 0.96, 0.0,
            labelSurface, labelW, labelH, trackNum);

        if (outlined)
        {
            cr.setSourceRgba(1.0, 1.0, 1.0, 0.65);
            cr.setLineWidth(1.6);
            cr.newPath();
            cr.arc(cx, cy, maxR * 0.97, 0, PI * 2);
            cr.closePath();
            cr.stroke();
        }
    }

    void onEnter(double x, double y)
    {
        uint gen = ++hoverGen;
        timeoutAdd(0, 200, delegate bool() {
            if (hoverGen == gen)
            {
                hovered = true;
                queueDraw();
            }
            return false;
        });
    }

    void onLeave()
    {
        hoverGen++;
        hovered = false;
        queueDraw();
    }

    void loadLabel(ubyte[] imageData, int size)
    {
        if (imageData is null || imageData.length == 0)
            return;

        try
        {
            PixbufLoader loader = new PixbufLoader();
            loader.write(imageData);
            loader.close();
            Pixbuf pixbuf = loader.getPixbuf();
            if (pixbuf !is null)
            {
                Pixbuf scaled = pixbuf.scaleSimple(size, size, InterpType.Bilinear);
                if (scaled !is null)
                {
                    labelSurface = pixbufToSurface(scaled);
                    labelW = size;
                    labelH = size;
                }
            }
        }
        catch (Exception)
        {
        }
    }

public:
    Variant data;
    VinylKind kind;
    string name;
    bool hovered;
    bool outlined;
    int trackNum;
    Surface labelSurface;
    int labelW, labelH;

    Artist artist()
    {
        return data.get!Artist;
    }

    Album album()
    {
        return data.get!Album;
    }

    Track track()
    {
        return data.get!Track;
    }

    this(T)(T value, int size = defaultSize!T)
    {
        data = Variant(value);
        name = getName(value);
        trackNum = getTrackNum(value);

        static if (is(T == Artist))
            kind = VinylKind.Artist;
        else static if (is(T == Album))
            kind = VinylKind.Album;
        else static if (is(T == Track))
            kind = VinylKind.Track;

        int totalSize = size + pad * 2;
        contentWidth = totalSize;
        contentHeight = totalSize;
        halign = Align.Center;
        valign = Align.Center;
        overflow = Overflow.Visible;
        setDrawFunc(&onDraw);

        loadLabel(value.image(), size);

        EventControllerMotion motion = new EventControllerMotion();
        motion.connectEnter(&onEnter);
        motion.connectLeave(&onLeave);
        addController(motion);
    }

    void detach()
    {
        if (getParent() !is null)
            unparent();
    }

private:
    static string getName(Artist a) => a.name;
    static string getName(Album a) => a.title;
    static string getName(Track t) => t.title;

    static int getTrackNum(Artist a) => cast(int)a.albums.length;
    static int getTrackNum(Album a) => cast(int)a.tracks.length;
    static int getTrackNum(Track t) => t.number;

    template defaultSize(T)
    {
        static if (is(T == Artist))
            enum defaultSize = 58;
        else static if (is(T == Album))
            enum defaultSize = 50;
        else static if (is(T == Track))
            enum defaultSize = 32;
    }
}