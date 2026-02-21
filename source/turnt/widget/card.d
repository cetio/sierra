module turnt.widget.card;

import std.conv : to;

import gtk.box;
import gtk.label;
import gtk.overlay;
import gtk.types : Align, Orientation, Overflow;
import gtk.widget : Widget;
import pango.types : EllipsizeMode;

import turnt.widget.vinyl : Vinyl;

class CardWidget : Box
{
public:
    Overlay overlay;
    Box row;
    Box infoBox;
    Vinyl vinyl;
    Label titleLabel;
    Label subLabel;
    Label playCountLabel;

    this(Vinyl v, string title, string detail, int plays = 0,
        int mTop = 2, int mBot = 2, string extraTitleCss = "")
    {
        super(Orientation.Horizontal, 0);
        addCssClass("card");
        marginStart = 4;
        marginEnd = 4;
        marginTop = mTop;
        marginBottom = mBot;

        this.vinyl = v;
        v.outlined = false;

        row = new Box(Orientation.Horizontal, 8);
        v.detach();
        row.append(v);

        infoBox = new Box(Orientation.Vertical, 1);
        infoBox.valign = Align.Center;
        infoBox.hexpand = true;

        titleLabel = new Label(title);
        titleLabel.addCssClass("card-name");
        if (extraTitleCss.length > 0)
            titleLabel.addCssClass(extraTitleCss);
        titleLabel.halign = Align.Start;
        titleLabel.hexpand = true;
        titleLabel.xalign = 0;
        titleLabel.ellipsize = EllipsizeMode.End;
        infoBox.append(titleLabel);

        if (detail.length > 0)
        {
            subLabel = new Label(detail);
            subLabel.addCssClass("count-label");
            subLabel.halign = Align.Start;
            subLabel.xalign = 0;
            subLabel.ellipsize = EllipsizeMode.End;
            infoBox.append(subLabel);
        }

        row.append(infoBox);

        overlay = new Overlay();
        overlay.setChild(row);

        if (plays > 0)
        {
            playCountLabel = new Label(plays.to!string);
            playCountLabel.addCssClass("play-count-label");
            playCountLabel.halign = Align.End;
            playCountLabel.valign = Align.End;
            playCountLabel.marginEnd = 8;
            playCountLabel.marginBottom = 4;
            overlay.addOverlay(playCountLabel);
        }

        append(overlay);
    }
}