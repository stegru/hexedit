library hexedit.grid;

import "dart:html" hide Range, Selection, EventSource;
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../hexedit.dart';
import 'dart:math';

part 'hexrow.dart';
part 'hexcell.dart';
part 'selection.dart';
part 'celledit.dart';
part 'charset.dart';

/**
 * The hex editor table
 */
class HexGrid extends Component<DivElement> {
    HexEdit hexEditor;
    CellEditor cellEditor;

    Range range = new Range(0, 0);

    int get offset => this.range.start;

    int get lastOffset => this.range.end;

    int get cellCount => this.rowCount * this.columnCount;

    bool get hasFocus => this.hexEditor.hasFocus;

    int columnCount = 16;
    int rowCount = 0;

    List<HexRow> rows = new List<HexRow>();
    List<HexCell> cells = new List<HexCell>();
    List<HexCell> hexCells = new List<HexCell>();

    /// Raised when the highlight has been updated. Range is null when there is no highlight.
    EventSource<Range> onHighlight = new EventSource<Range>();

    HexHeaderRow header;

    Selection selection;
    HexCell cursorCell;
    SpanElement cursor = new SpanElement();

    Charset charset;
    CssStyleSheet charsetStyles;

    /// Height of the grid.
    int height = 0;
    /// The panel container below the grid.
    DivElement bottomPanels = null;


    HexGrid(HexEdit hexEditor) {
        this.hexEditor = hexEditor;
        this.header = new HexHeaderRow(this);
        this.selection = new Selection(this);
        this.cellEditor = new CellEditor(this);
    }

    bool setOffset(int newOffset) {
        newOffset = newOffset.clamp(0, this.hexEditor.data.length - (this.hexEditor.data.length % this.columnCount)).toInt();
        newOffset -= newOffset % this.columnCount;

        bool moved = (newOffset != this.range.start);

        this.range.start = newOffset;
        this.range.end = (this.range.start + this.cellCount).clamp(0, this.hexEditor.data.length);

        if (moved) {
            this.hexEditor.onOffsetChanged.raise(this.hexEditor);
        }

        return moved;
    }

    void set line(int newLine) {
        newLine = newLine.clamp(0, this.hexEditor.data.length / this.columnCount);
        this.setOffset(newLine * this.columnCount);
    }

    int get line {
        return (this.range.start / this.columnCount).floor();
    }

    int get lineCount {
        return this.hexEditor.data.length == 0 ? 0 : this.hexEditor.data.length / this.columnCount;
    }


    /** Add a new row to the grid. */
    HexRow addRow() {
        HexRow row = new HexRow(this);
        row.index = this.rowCount++;
        this.rows.add(row);

        row.next = null;
        if (row.index == 0) {
            row.prev = null;
        } else {
            row.prev = this.rows[row.index - 1];
            row.prev.next = row;
        }

        return row;
    }

    /** Remove the last row. */
    void removeRow() {
        if (!this.rows.isEmpty) {
            HexRow row = this.rows.removeLast();
            row.prev.next = row.prev;
            row.destroy();
            this.rowCount--;
        }
    }

    /** Called when a cell is added to the grid. */
    void addCell(HexCell cell) {
        cell.id = this.cells.length;
        String c = cell.isAscii ? 'a' : 'h';
        cell.element.id = "cell${c}${cell.id}";

        this.cells.add(cell);

        if (!cell.isAscii) {
            this.hexCells.add(cell);
        }
    }

    /** Called when a cell is removed from the grid. */
    void removeCell(HexCell cell) {
        // search in reverse - usually the ones to remove will be at the end.
        int pos = this.cells.lastIndexOf(cell);
        if (pos >= 0) {
            this.cells.removeAt(pos);
        }

        if (!cell.isAscii) {
            pos = this.hexCells.lastIndexOf(cell);
            if (pos >= 0) {
                this.hexCells.removeAt(pos);
            }
        }

    }

    /** Find the cell */
    Cell findCell(String id) {
        if (id.startsWith('cell')) {
            try {
                int index = int.parse(id.substring(5));
                return this.cells[index];
            } catch (FormatException) {
            }
        }

        return null;
    }

    /** Returns the cell that displays the given offset. */
    HexCell cellAt(int offset) {
        offset -= this.range.start;

        if (offset < 0 || offset >= this.hexEditor.hexGrid.hexCells.length) {
            return null;
        }

        return this.hexEditor.hexGrid.hexCells[offset];
    }

    /** Create the grid elements. */
    void create() {
        this.element = new DivElement();
        this.element.id = "grid";

        this.bottomPanels = document.querySelector('#below-grid-panels');

        this.header.create();

        super.create();
        this.addRow().create();

        if (this.cursorCell == null) {
            this.setCursor(this.rows.first.hexCells.first);
        }
    }

    void created() {
        Charset.init(this);
        Charset._all.first.load(this);

        StyleElement style = new StyleElement();
        this.element.parent.append(style);
        CssStyleSheet sheet = style.sheet as CssStyleSheet;

        for (int n = 0; n <= 0xFF; n++) {
            sheet.insertRule(".hex.value[data-value='${n}']::before { content: '${(n < 16 ? "0" : "")}${n.toRadixString(16)}' }", sheet.cssRules.length);
        }
    }

    double total = 0.0;
    int cnt = 0;
    void update([bool full = false]) {
//        Stopwatch s = new Stopwatch();
//        s.start();

//        Element e = this.element;
//        Node parent = e.parent;
//        this.element.remove();

        this.rows.forEach((HexRow row) => row.update(full));
        this.updateHighlight();

//        parent.insertBefore(e, parent.firstChild);

//        s.stop();
//        total += s.elapsedMilliseconds;
//        cnt++;
//        print("${s.elapsedMilliseconds}, avg: ${total / cnt}");
    }

    /** Called when the size has changed, and the number of rows might need to change. */
    void adjustSize({int clientHeight: 0, bool noEvent: false}) {
        if (clientHeight == 0) {
            clientHeight = this.element.parent.clientHeight;
        }

        this.height = clientHeight - this.bottomPanels.offset.height;

        int rowHeight = this.rows.first.element.offsetHeight;
        if (rowHeight == 0) {
            rowHeight = 20;
        }

        int diff = this.height - (rowHeight * (this.rowCount + 0));

        if (diff.abs() > this.rows.first.element.offsetHeight) {
            bool grow = diff > 0;

            if (grow) {
                HexRow row = this.addRow();
                row.create();
                row.update();
                this.adjustSize(clientHeight: clientHeight);
                return;
            }
            else if (this.rowCount > 2) {
                this.removeRow();
                this.adjustSize(clientHeight: clientHeight);
                return;
            }
        }

        if (!noEvent) {
            this.setOffset(this.offset);
        }

        if (this.charWidth == 0) {
            DivElement d = new DivElement();
            d.innerHtml = "M";
            d.style.position = 'absolute';
            this.element.append(d);
            this.charWidth = d.client.width;
            d.remove();
        }

        if (!noEvent) {
            new Timer(const Duration(milliseconds: 10), () {
                this.element.parent.style.minWidth = "${this.element.offset.width}px";
                this.hexEditor.onResize.raise(this.hexEditor);
            });
        }
    }

    double charWidth = 0.0;

    void addEventHandlers() {

        this.hexEditor.onOffsetChanged.add((HexEdit he) {
            this.update();
            return true;
        });

        this.hexEditor.onDataReset.add((HexEdit he) {
            this.setOffset(1);
            this._cursorOffset = 0;
            this.selection.set(0, -1);
            adjustSize();
            return true;
        });

        window.onResize.listen((e) {
            adjustSize();
        });

        // Instead of having mouse event handlers for every cell, there's just one for the grid
        this.element.onClick.listen((e) => this.HandleCellEvent(e, (HexCell c) => c.click(e)));
        this.element.onMouseDown.listen((e) => this.HandleCellEvent(e, (HexCell c) => c.mousedown(e)));
        this.element.onMouseMove.listen((e) => this.HandleCellEvent(e, (HexCell c) => c.mousemove(e)));
        this.element.onMouseUp.listen((e) => this.HandleCellEvent(e, (HexCell c) => c.mouseup(e)));

        this.selection.addEventHandlers();

        this.hexEditor.onDataModified.add((Range range) {
            this.range.end = (this.range.start + this.cellCount).clamp(0, this.hexEditor.data.length);
            this.updateCells(range);
            return true;
        });

        window.document.onPaste.listen((e) {
            if (this.hexEditor.hasFocus) {
                this.paste(e.clipboardData);
                e.stopPropagation();
                e.preventDefault();
            }
        });

        window.document.onCopy.listen((e) {
            if (this.hexEditor.hasFocus) {
                this.toClipboard(e.clipboardData, false);
                e.stopPropagation();
                e.preventDefault();
            }
        });

        window.document.onCut.listen((e) {
            if (this.hexEditor.hasFocus) {
                this.toClipboard(e.clipboardData, true);
                e.stopPropagation();
                e.preventDefault();
            }
        });


        Element.focusEvent.forElement(document.body, useCapture: true).listen((Event e) {
            focusChange(e.target, true);
        });
        Element.blurEvent.forElement(document.body, useCapture: true).listen((Event e) {
            focusChange(e.target, false);
        });


    }

    Timer focusTimer = null;

    void focusChange(Element element, bool focus) {
        if (focus) {
            if (this.focusTimer != null) {
                this.focusTimer.cancel();
                this.focusTimer = null;
            }

            this.updateFocus();
        } else {
            this.focusTimer = new Timer(new Duration(milliseconds:300), () {
                this.updateFocus();
            });
        }
    }

    void updateFocus() {
        if (this.hasFocus) {
            this.element.classes.add("hasFocus");
        } else {
            this.element.classes.remove("hasFocus");
        }
    }

    bool hasClipboard = false;

    bool toClipboard(DataTransfer data, bool cut) {
        if (this.selection.length == 0) {
            return false;
        }


        data.clearData();
        if (this.selection.length < 0xffff) {
            data.setData("text/base64", CryptoUtils.bytesToBase64(this.selection.getBytes()));
        }
        data.setData("text/plain", CryptoUtils.bytesToHex(this.selection.getBytes()));


        if (cut) {
            this.deleteSelection();
        }

        return true;
    }

    bool paste(DataTransfer data) {
        Iterable<int> bytes = null;
        String text = null;

        for (String type in [ "base64", "text/base64", "application/base64" ]) {
            if (data.types.contains(type)) {
                text = data.getData(type);
                if (text != null) {
                    bytes = CryptoUtils.base64StringToBytes(text);
                    break;
                }
            }
        }

        if (bytes == null) {

            for (String type in [ "text", "text/plain"]) {
                if (data.types.contains(type)) {
                    text = data.getData(type);
                    if (text != null) {
                        break;
                    }
                }
            }

            if ((text == null) || (text.length == 0)) {
                return false;
            }

            if (!this.cursorCell.isAscii) {
                // see if it's a hex string ("1a2b3c" or "1a 2b 3b")
                bool isHex = text.contains(new RegExp(r"^([a-fA-F0-9]{2})+$"));
                if (!isHex) {
                    isHex = text.contains(new RegExp(r"^ *([a-fA-F0-9]{2} )+ *$"));
                    if (isHex) {
                        text = text.replaceAll(" ", "");
                    }
                }

                if (isHex) {
                    bytes = ByteConverter.hexStringToBytes(text).toList(growable: false);
                }
            }

            if (bytes == null) {
                bytes = new Utf8Codec().encode(text);
                // new AsciiCodec().encode(text);
            }
        }
        this.replaceSelection(bytes);

        return true;
    }

    void replaceSelection(Iterable<int> bytes) {
        if (this.selection.length == 0) {
            if (this.hexEditor.data.resizable) {
                this.hexEditor.data.insertBytes(this.selection.offset, bytes);
            } else {
                this.hexEditor.data.setBytes(this.selection.offset, bytes);
            }
        } else if (this.hexEditor.data.resizable) {
            this.hexEditor.data.delete(this.selection.offset, this.selection.length);
            this.hexEditor.data.insertBytes(this.selection.offset, bytes);
        } else {
            this.hexEditor.data.setBytes(this.selection.offset, bytes.take(this.selection.length));
        }
    }

    /** Send a mouse event to the cell where the mouse is */
    void HandleCellEvent(MouseEvent e, void f(Cell cell)) {
        //if (!this.selection.dragging)
        {
            if (e.target is SpanElement) {
                SpanElement elem = e.target as SpanElement;
                if (elem != null) {
                    Cell cell = this.findCell(elem.id);
                    if (cell != null) {
                        f(cell);
                    }
                }
            }
        }
    }

    /** Gets the row that's closest to [pt]. */
    HexRow getNearestRowAt(Point pt) {
        for (HexRow row in this.rows) {
            if (row.rect.bottom == 0) {
                row.rect = row.element.getBoundingClientRect();
            }
            if (pt.y <= row.rect.bottom) {
                return row;
            }
        }

        return this.rows.last;
    }


    bool scrollTo(int offset) {
        if (offset < this.offset) {
            // Go back - make the top line show the offset
            return this.setOffset(offset);
        } else if (offset > this.lastOffset - 33) {
            // Go forward - make the last line show the offset
            return this.setOffset(offset - (this.rowCount - 3) * this.columnCount + 1);
        }

        return false;
    }

    void removeCursor() {
        if (this.cellEditor.editing) {
            this.cellEditor.commit();
            this.cellEditor.stopEdit();
        }

        if (this.cursorCell != null) {
            this.cursorCell.element.classes.remove('hasCursor');
        }

        this.cursor.remove();
    }

    int _cursorOffset = 0;

    void set cursorOffset(int value) {
        bool ascii = (this.cursorCell != null) && this.cursorCell.isAscii;

        this.scrollTo(value);
        HexCell cell = this.cellAt(value);
        if (cell != null) {
            this.setCursor(ascii ? cell.ascii : cell.hex);
        }
    }

    int get cursorOffset {
        return this._cursorOffset;
    }

    /** Put the cursor in [cell]. Set [pos] to the character position (0-2).  */
    void setCursor(HexCell cell, [int pos = 0]) {

        if (cell != null) {
            if (this.cursorCell != null && cell.offset != this.cursorCell.offset
                && this.hexEditor.onCursorMove.raise(cell)) {
                return;
            }
            if (cell.offset > this.hexEditor.data.length) {
                return;
            }
        }

        this.updateFocus();
        this.cursor.classes.clear();
        this.cursor.classes.add('cursor');

        if (this.cursorCell != null && this.cursorCell != cell) {
            this.cursorCell.element.classes.remove('hasCursor');
            this.cursorCell.linked.element.classes.remove('hasCursor');
        }

        if (this.cursorCell == null || (cell != null && (this.cursorCell.isAscii != cell.isAscii))) {
            this.element.classes.add(cell.isAscii ? 'asciiCursor' : 'hexCursor');
            this.element.classes.remove(cell.isAscii ? 'hexCursor' : 'asciiCursor');
        }


        if (cell == null) {
            this.element.classes.removeAll(['hexCursor', 'asciiCursor']);
            this.cursor.remove();
        } else {
            this.cursorCell = cell;
            this._cursorOffset = cell.offset;

            this.cursorCell.element.classes.add('hasCursor');
            this.cursorCell.linked.element.classes.add('hasCursor');

            this.cursorCell.element.append(this.cursor);

            this.selection.ascii = this.cursorCell.isAscii;

            if ((pos == 0) && this.selection.length > 0 && !this.selection.isBackwards) { //(this.selection.length > 0) && (this.selection.isBackwards || (this.selection.cursor > this.selection.anchor)) {
                pos = 2;
            }

            if (pos == 1) {
                this.cursor.classes.add("char2");
            } else if (pos == 2) {
                this.cursor.classes.add("end");
            }
        }
    }

    void editCell(HexCell cell) {
        this.cellEditor.edit(cell);
    }

    void updateCells(Range range) {
        if (this.range.intersects(range)) {
            if (range.end >= this.range.end - 1) {
                this.update();
            } else {

                HexCell cell;
                if (range.start < this.range.start) {
                    cell = this.cellAt(this.range.start);
                } else {
                    cell = this.cellAt(range.start);
                }

                while (cell != null && cell.offset <= range.end) {
                    cell.hex.update();
                    cell = cell.getAdjacent(Direction.RIGHT, wrap: true, sameType: true, noClamp: true);
                }
            }
        }
    }

    /**
     * Deletes the selection.
     */
    void deleteSelection([bool backspace = false]) {
        int offset = this.selection.offset + (backspace ? -1 : 0);

        if (this.lastOffset == 0) {
            return;
        }

        int len = this.selection.length.clamp(1, this.lastOffset);
        if (this.hexEditor.data.resizable) {
            this.hexEditor.data.delete(offset, len);
            this.selection.set(offset, -1, this.selection.ascii);
        } else {
            List<int> bytes = new List<int>.filled(len, 0x00);
            this.hexEditor.data.setBytes(offset, bytes);
        }
    }

    int _highlightOffset = -1;
    int _highlightLength = -1;

    void updateHighlight() {
        if (this._highlightOffset >= 0 && this._highlightLength >= 0) {
            this.highlight(this._highlightOffset, this._highlightLength);
        }
    }

    /// Clears the highlight. [_changing] indicates the highlight is just changing, and will be replaced.
    void clearHighlight([bool _changing = false]) {
        this._highlightOffset = this._highlightLength = -1;
        this.$$('.value.highlight').forEach((Element e) => e.classes.remove('highlight'));

        if (!_changing) {
            this.onHighlight.raise(null);
        }

    }

    void highlight(int offset, int len) {
        HexCell cell = this.cellAt(offset);
        this._highlightCells(cell, len, offset);
    }

    void _highlightCells(HexCell cell, int len, int offset) {
        this.clearHighlight(true);

        if (cell != null) {
            offset = cell.offset;
        }

        this._highlightOffset = offset;
        this._highlightLength = len;

        if (cell != null) {
            for (int n = 0; n < len && cell != null; n++) {
                cell.highlight();
                cell = cell.getAdjacent(Direction.RIGHT, wrap: true, sameType: true, noClamp: true);
            }
        }

        this.onHighlight.raise(new Range(this._highlightOffset, this._highlightOffset + this._highlightLength));
    }
}
