module turnt.view.player;

import gtk.box;
import gtk.types : Orientation, Overflow;

class PlayerView : Box
{
public:
    this()
    {
        super(Orientation.Vertical, 0);
        addCssClass("player-panel");
        hexpand = true;
        vexpand = true;
        overflow = Overflow.Hidden;
    }
}