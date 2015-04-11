part of hexedit.grid;

/**
 * A row in a [HexGrid].
 */
class HexRow extends Component<DivElement> {
    HexGrid grid;
    HexEdit hexEditor;
    int get columnCount => this.grid.columnCount;
    int index = 0;
    bool isHeader = false;

    bool hasHighlight = false;

    HexRow prev;
    HexRow next;

    String id;

    SpanElement hexHighlight = new SpanElement();
    SpanElement asciiHighlight = new SpanElement();
    GutterCell gutter = null;
    SpacerCell spacer = null;
    Rectangle rect;
    List<HexCell> hexCells = new List<HexCell>();
    List<AsciiCell> asciiCells = new List<AsciiCell>();

    HexRow(HexGrid grid) {
        this.grid = grid;
        this.hexEditor = this.grid.hexEditor;

        this.gutter = new GutterCell(this);
        this.spacer = new SpacerCell(this);

        HexCell lastHex = null;
        AsciiCell lastAscii = null;

        for (int n = 0; n < columnCount; n++) {
            HexCell hexCell = this.isHeader ? new HeaderCell(this, false) : new HexCell(this);
            AsciiCell asciiCell = this.isHeader ? new HeaderCell(this, true) : new AsciiCell(this);

            hexCell.index = asciiCell.index = n;
            hexCell.linked = asciiCell;
            asciiCell.linked = hexCell;

            hexCell.hex = asciiCell.hex = hexCell;
            hexCell.ascii = asciiCell.ascii = asciiCell;

            hexCell.master = true;
            asciiCell.master = false;

            this.hexCells.add(hexCell);
            this.asciiCells.add(asciiCell);
        }
    }

    void create() {
        this.element = new DivElement();
        this.element.id = "row" + this.index.toRadixString(16);
        this.id = "row" + this.index.toRadixString(16);
        this.element.classes.addAll(["hexrow", this.index.isEven ? "even" : "odd"]);

        this.hexHighlight.classes.addAll(['selectionHighlight', 'hex']);
        this.asciiHighlight.classes.addAll(['selectionHighlight', 'ascii']);
        this.element.append(this.hexHighlight);
        this.element.append(this.asciiHighlight);

        this.gutter.create();
        this.hexCells.forEach((cell) => cell.create());
        this.spacer.create();
        this.asciiCells.forEach((cell) => cell.create());

        this.grid.element.append(this.element);

        super.create();
    }

    void addEventHandlers() {
        this.element.onMouseDown.listen((MouseEvent e) {
            if (e.button == 0) {
                if (e.target == this.gutter.element) {
                    this.grid.selection.startLine(this);
                }
                else {
                    HexCell cell = this.getNearestCellAt(e.client);
                    if (cell.offset >= this.hexEditor.data.length) {
                        cell = this.grid.cellAt(this.hexEditor.data.length);
                    }
                    if (cell != null) {
                        this.grid.selection.start(cell.offset, cell.isAscii);
                    }
                }
            }
        });
        this.hexEditor.onResize.add((HexEdit he) {
            _leftsHex.fillRange(0, 0x10, -1);
            _leftsAscii.fillRange(0, 0x10, -1);
            _rightsHex.fillRange(0, 0x10, -1);
            _rightsAscii.fillRange(0, 0x10, -1);
        });
    }

    void destroy() {
        super.destroy();
        this.hexCells.forEach((cell) => cell.destroy());
        this.hexCells.clear();
        this.asciiCells.clear();
    }

    void update([bool full = false]) {
        for (HexCell cell in this.hexCells) {
            cell.update(full);
        }

        if (this.gutter != null) {
            this.gutter.update();
        }

        this.rect = this.element.getBoundingClientRect();

        this.element.hidden = this.offset > this.hexEditor.data.length;
    }

    // element.offset.* is slow, so cache them (the cells don't move)
    static List<int> _leftsHex = new List.filled(0x10, -1);
    static List<int> _leftsAscii = new List.filled(0x10, -1);
    static List<int> _rightsHex = new List.filled(0x10, -1);
    static List<int> _rightsAscii = new List.filled(0x10, -1);

    /** Updates the highlight for the row. Starting at [start], to [end] */
    void updateHighlight(HexCell start, HexCell end) {
        if (start == null) {
            if (this.hasHighlight) {
                this.element.classes.remove('hasSelection');
            }
            this.hasHighlight = false;
        }
        else {

            start = start.hex;
            end = end.hex;

            String left = "0px";
            String width = "100%";

            bool ascii = false;
            for (SpanElement highlight in [this.hexHighlight, this.asciiHighlight]) {
                if (start.index > 0 || start.index < 15) {
                    List<int> lefts = ascii ? _leftsAscii : _leftsHex;
                    List<int> rights = ascii ? _rightsAscii : _rightsHex;

                    int x = lefts[start.index];
                    if (x == -1) {
                        x = start.element.offset.left;
                        if (!ascii) {
                            x += this.grid.charWidth / 2;
                        }
                        lefts[start.index] = x;
                    }

                    int x2 = rights[end.index];
                    if (x2 == -1) {
                        x2 = end.element.offset.right;
                        if (!ascii) {
                            x2 -= this.grid.charWidth * 1.5;
                        }
                        rights[end.index] = x2;
                    }

                    left = "${x}px";
                    width = "${x2 - x}px";
                }

                highlight.style.left = left;
                highlight.style.width = width;
                start = start.ascii;
                end = end.ascii;
                ascii = true;
            }

            if (!this.hasHighlight) {
                this.element.classes.add('hasSelection');
            }

            this.hasHighlight = true;
        }
    }

    int get offset {
        return this.grid.range.start + (this.index * this.columnCount);
    }

    /** Gets the cell that's nearest to [pt] */
    HexCell getNearestCellAt(Point pt) {
        if (this.rect.right == 0) {
            this.rect = this.element.getBoundingClientRect();
        }

        pt = new Point(pt.x - this.rect.left, pt.y - this.rect.top);

        List<HexCell> cells = pt.x < this.asciiCells.first.element.offset.left - (this.spacer.element.client.width / 2)
                              ? this.hexCells : this.asciiCells;

        HexCell prev = cells.first;
        for (HexCell cell in cells) {
            if (pt.x <= cell.element.offset.right) {
                return cell;
            }
        }

        if (pt.x > this.rect.width) {
            return this.asciiCells.last;
        }
        else if (pt.x <= 0) {
            return this.hexCells.first;
        }
        else {
            return this.hexCells.last;
        }
    }
}

/**
 * The header row.
 */
class HexHeaderRow extends HexRow {
    bool isHeader = true;

    HexHeaderRow(HexGrid grid) : super(grid) {
        this.index = 0;
    }

    @override
    void create() {
        super.create();
        this.element.id = this.grid.element.id + "_header";
        this.element.classes.add('header');
        this.element;
    }

    void addEventHandlers() {
        //this.hexEditor.ready.add((hexEditor) => this.update());
    }
}