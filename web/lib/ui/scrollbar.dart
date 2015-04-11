part of hexedit;

/**
 * THe scroll bar for the [HexGrid]
 */
class Scrollbar extends Component<DivElement> {
    SpanElement thumb;
    EventSource<Scrollbar> onScroll = new EventSource<Scrollbar>();
    Timer repeat = null;

    bool thumbDrag = false;
    int thumbMouseOffset = 0;

    double pos = 0.0;
    int min = 0;
    int max = 100;
    int pageSize = 5;

    bool ignoreScroll = false;

    void create() {
        this.element = new DivElement();
        this.element.classes.add('scroll');
        this.thumb = new SpanElement();
        this.thumb.classes.add('scroll-thumb');
        this.element.append(this.thumb);
        super.create();
    }


    void addEventHandlers() {
        this.element.onMouseDown.listen((MouseEvent e) {
            this.setPos(this.screenToPos(e.offset.y - this.thumb.offsetHeight / 2));
            e.stopPropagation();
        });
        this.thumb.onMouseDown.listen((MouseEvent e) {
            if (e.button == 0) {
                this.captureDrag(e);
                e.stopPropagation();
            }
        });

        this.thumb.onMouseUp.listen(this.cancelDrag);
        this.element.onMouseUp.listen(this.cancelDrag);
    }

    void captureDrag(MouseEvent e) {
        this.thumbDrag = true;
        this.thumbMouseOffset = e.offset.y;
        this.captureMouse(this.drag, this.cancelDrag);
    }

    void drag(MouseEvent e) {
        if (this.thumbDrag) {
            this.setPos(this.screenToPos((e.client.y - this.thumbMouseOffset) - this.element.documentOffset.y));
        }
    }

    void cancelDrag(MouseEvent e) {
        if (e.button == 0) {
            this.thumbDrag = false;
        }
    }

    // clientHeight and offsetHeight are cached because they're slow.
    int _clientHeight = 0;
    int _thumbHeight = 0;

    /** Converts a scroll thumb position to the screen location. */
    double posToScreen(double pos) {
        return (pos / (this.max - this.min)) * (this._clientHeight - this._thumbHeight);
    }

    /** Converts a screen position to a scroll thumb position. */
    double screenToPos(double y) {
        return (y / (this._clientHeight - this._thumbHeight)) * (this.max - this.min) + this.min;
    }

    int heightAdjustment = 0;

    /** Set the range of the scollbar. */
    void setRange(int min, int max, int pageSize) {
        if (min < 0 || max <= 0 || (max - min) <= 0 ) {
            this.min = 0;
            this.max = 1;
            this.pageSize = 1;
        } else {
            this.min = min;
            this.max = max;
            this.pageSize = pageSize.clamp(this.min, this.max - this.min);
        }

        double p = this.pageSize / (this.max - this.min) * 90;

        this.thumb.style.height = "${p}%";

        this._thumbHeight = this.thumb.offsetHeight;
        int pad = int.parse(this.element.style.paddingBottom.replaceAll("px", ""), onError: (s) => 0);
        this._clientHeight = this.element.client.height - pad + this.heightAdjustment;

        this.setPos(this.pos);
    }

    /** Set the position */
    void setPos(double pos) {

        double oldPos = this.pos;

        this.pos = pos.clamp(this.min, this.max);

        double top = posToScreen(this.pos);

        //this.thumb.style.top = "${top}px";
        this.thumb.style.transform = "translateY(${top}px)";

        if (this.pos != oldPos) {
            this.ignoreScroll = true;
            this.onScroll.raise(this);
            this.ignoreScroll = false;
        }
    }
}