part of hexedit.grid;

typedef void MouseEventHandler(MouseEvent e);

/**
 * A cell.
 */
abstract class Cell extends Component<SpanElement> {
    HexRow row;
    HexGrid grid;
    HexEdit hexEditor;

    bool isValue = false;

    int index = 0;
    int id = -1;

    int numberValue = -1;

    Cell(HexRow this.row) {
        this.row = row;
        this.grid = this.row.grid;
        this.hexEditor = this.row.hexEditor;
    }

    /** Gets the offset this cell displays */
    int get offset {
        return this.row.offset + this.index;
    }

    /** The text value the cell has */
    String get textValue {
        return this.getText();
    }

    void update() {
        this.element.innerHtml = this.getText();
    }

    String getText() {
        if (this.numberValue == null) {
            return "00";
        } else if (this.numberValue <= 0xf) {
            return "0" + this.numberValue.toRadixString(16);
        } else {
            return this.numberValue.toRadixString(16);
        }
    }

    void create() {
        this.element = new SpanElement();
        this.row.element.append(this.element);
    }
}

/**
 * A [Cell] that displays hex.
 */
class HexCell extends Cell {
    HexCell linked;
    HexCell hex;
    AsciiCell ascii;

    Text textNode = new Text("");

    bool master = false;
    bool isAscii = false;
    bool isValue = true;
    bool isSelected = false;

    int editPos = 0;
    String editValue = "";

    HexCell(HexRow row) : super(row) {
    }

    void create() {
        super.create();
        this.element.classes.addAll(["col${this.index}", this.index.isEven ? "even" : "odd", this.isAscii ? "ascii"
                                                                                             : "hex" ]);
        if (this.isValue) {
            this.element.classes.add("value");
            this.grid.addCell(this);
        }

        this.element.append(this.textNode);
    }

    void setText(String text) {
        this.element.children.clear();
        this.textNode.text = text;
        this.element.append(this.textNode);
    }


    void destroy() {
        super.destroy();
        if (!this.isAscii) {
            this.ascii.destroy();
        }

        if (this.isValue) {
            this.grid.removeCell(this);
        }
    }

    void update([bool full = false]) {
        int newValue = this.hexEditor.data.get(this.offset);

        if (newValue == this.numberValue && !full) {
            return;
        }

        int oldValue = this.numberValue;
        this.numberValue = newValue;

        if (oldValue != newValue || full) {
            bool hide = (this.numberValue == null);

            if (this.isAscii) {
                this.textNode.text = hide ? "" : this.hexEditor.hexGrid.charset.chars[this.numberValue];
            } else {
                this.textNode.text = hide ? "" : this.getText();
            }
        }

        if (this.master && this.linked != null) {
            this.linked.update(full);
        }
    }


    HexCell get next {
        HexCell _next = null;
        if (_next == null) {
            _next = this.index < 15 ? this.row.hexCells[this.index + 1] : (this.row.next == null ? null
                                                                                : this.row.next.hexCells.first);
        }

        return this.isAscii ? _next.ascii : _next;
    }

    void click(MouseEvent e) {
        this.grid.setCursor(this);
    }

    void mousedown(MouseEvent e) {
    }

    void mousemove(MouseEvent e) {
    }

    void mouseup(MouseEvent e) {
    }

    void select() {
        this.isSelected = true;
        this.element.classes.add('selected');
    }

    void deselect() {
        this.isSelected = false;
        this.element.classes.remove('selected');
    }

    void edit() {
        this.grid.editCell(this);
    }


    /**
     * Gets the adjacent cell in the given [dir].
     * Set [wrap] to true to return the first/last cell on the previous/next column when on the start/end of the grid,
     * otherwise return [null] when there is no adjacent cell. Set [sameType] to true to return adjacent cell of the
     * same type (hex/ascii).
     */
    HexCell getAdjacent(Direction dir, {bool wrap: false, bool sameType: false, bool noClamp : false}) {
        int column = this.index + dir.x;
        int row = this.row.index + dir.y;
        int maxColumn = (sameType ? this.grid.columnCount : 32) - 1;

        if (!sameType && this.isAscii) {
            column += this.grid.columnCount;
        }

        if (column < 0) {
            if (!wrap) {
                return null;
            }

            row--;
            column = maxColumn;
        }
        else if (column > maxColumn) {
            if (!wrap) {
                return null;
            }

            row++;
            column = 0;
        }

        if (wrap && !noClamp) {
            if (row < 0) {
                column = 0;
            }
            else if (row >= this.grid.rowCount) {
                column = maxColumn;
            }

            row = row.clamp(0, this.grid.rowCount - 1);
        }
        else {
            if (row < 0 || row >= this.grid.rowCount) {
                return null;
            }
        }

        if (column >= this.grid.columnCount || (this.isAscii && sameType)) {
            return this.grid.rows[row].asciiCells[column % this.grid.columnCount];
        }
        else {
            return this.grid.rows[row].hexCells[column];
        }
    }

    void highlight({bool start: true, bool end: true}) {
        this.element.classes.add('highlight');
        this.linked.element.classes.add('highlight');
    }
}

/**
 * A [Cell] that displays ascii.
 */
class AsciiCell extends HexCell {
    AsciiCell(HexRow row) : super(row) {
        this.isAscii = true;
    }


    void create() {
        super.create();
        this.element.classes.add("ascii");
    }

    /** The text value the cell has */
    String get textValue {
        return new String.fromCharCode(this.numberValue);
    }

    @override
    String getText() {
        // no longer called - CSS is used to display the values.

        if (this.numberValue < 0x20) {
            // control character
            return ".";
        }
        else if (this.numberValue == 0x20) {
            // space
            return "&nbsp;";
        }
        else {
            return new String.fromCharCode(this.numberValue);
        }
    }
}

/**
 * A cell that separating hex and ascii cells.
 */
class SpacerCell extends Cell {
    bool isValue = false;

    SpacerCell(HexRow row) : super(row) {
    }

    void create() {
        super.create();
        this.element.classes.add('spacer');
    }
}

/**
 * A cell displayed above the content cells, showing the column offset,
 */
class HeaderCell extends HexCell {
    bool isValue = false;

    HeaderCell(HexRow row, bool isAscii) : super(row) {
        this.isAscii = isAscii;
    }

    void create() {
        super.create();
        this.element.innerHtml = this.getText();
    }

    void update([bool full = false]) {
    }

    String getText() {
        return this.index.toRadixString(16);
    }

    void edit() {
    }

}

/**
 * A cell on the left, showing the row offset.
 */
class GutterCell extends HexCell {
    bool isValue = false;

    GutterCell(HexRow row) :super(row) {
    }

    @override
    void update([bool full = false]) {
        this.element.innerHtml = this.getText();
    }

    @override
    String getText() {
        if (this.row is HexHeaderRow) {
            return "";
        }
        else {
            return this.offset.toRadixString(16).padLeft(5, "0");
        }
    }

    @override
    void create() {
        super.create();
        this.element.classes.add("gutter");
    }

    void addEventHandlers() {
        //this.hexEditor.onOffsetChanged.add((HexEdit he) => this.update());
    }

    void edit() {
    }
}
