part of hexedit.grid;


/**
 * The selected bytes of the [HexGrid].
 */
class Selection {
    /// Where the drag started
    int anchor = -1;

    /// Where the cursor should be (the end that isn't the [anchor]).
    int cursor = -1;
    int offset = -1;
    int length = 0;
    bool lineSelection = false;
    HexEdit hexEditor;
    HexGrid grid;

    /// Was the selection made on the ascii grid?
    bool ascii = false;
    bool dragging = false;

    List<HexCell> cells = new List<HexCell>();

    Selection(HexGrid grid) {
        this.grid = grid;
        this.hexEditor = grid.hexEditor;
    }

    int _lastCursor = -1;

    bool _backwards = false;
    bool get isBackwards => (this.length == 1 && this._backwards) || this.cursor < this.anchor;

    void update() {

        if (this.cursor != this._lastCursor) {
            // Cursor has moved, so make sure it's visible.
            this._lastCursor = this.cursor;
            if (this.grid.scrollTo(this.cursor)) {
                return;
            }
        }

        bool cursorSet = false;
        int lastStart = 0;
        int lastEnd = 0;

        if (this.cells.isNotEmpty) {
            lastStart = this.cells.first.offset;
            lastEnd = this.cells.last.offset;
        }

        if (this.offset >= 0) {
            HexRow row = null;

            HexCell firstCell = null;
            HexCell lastCell = null;

            if (this.length == 0) {
                firstCell = this.grid.cellAt(this.offset);
                if (firstCell != null) {
                    if (this.ascii) {
                        firstCell = firstCell.ascii;
                    }
                    lastCell = firstCell;
                    firstCell.select();
                    this.grid.setCursor(firstCell, 0);
                    cursorSet = true;
                }
            } else if (this.offset + this.length < this.grid.offset || this.offset > this.grid.lastOffset) {
                // Not in view.
            } else {
                int start = this.offset.clamp(this.grid.offset, this.grid.lastOffset);
                int end = (this.offset + this.length).clamp(this.grid.offset, this.grid.lastOffset);
                firstCell = lastCell = this.grid.cellAt(start);

                for (HexCell cell = firstCell; cell != null && cell.offset < end; cell = cell.next) {

                    if (this.ascii) {
                        cell = cell.ascii;
                    }

                    if (cell.offset < lastStart || cell.offset > lastEnd) {
                        //cell.select();
                        //cell.linked.select();
                    }

                    this.cells.add(cell);

                    if (cell.offset == this.cursor) {
                        this.grid.setCursor(cell, this.cursor <= this.anchor ? 0 : 2);
                        cursorSet = true;
                    }

                    lastCell = cell;
                }

            }

            // show the highlight in each row the selection covers
            if (firstCell == null || this.length == 0) {
                this.grid.rows.forEach((row) => row.updateHighlight(null, null));
            } else {
                this.grid.rows.forEach((HexRow row) {
                    if ((row == firstCell.row) || (row == lastCell.row)) {
                        row.updateHighlight(row == firstCell.row ? firstCell : row.hexCells.first, row == lastCell.row ? lastCell : row.hexCells.last);
                    } else if ((row.index > firstCell.row.index) && (row.index < lastCell.row.index)) {
                        row.updateHighlight(row.hexCells.first, row.hexCells.last);
                    } else {
                        row.updateHighlight(null, null);
                    }
                });
            }

            if (!cursorSet) {
                this.grid.setCursor(null);
            }

        }
    }

    /** Return [true] if the offset is in the selection */
    bool isSelected(int offset) {
        return (this.length > 0) && (offset >= this.offset && offset <= this.offset + this.length);
    }

    /** Clear the selection */
    void clear() {
        this.anchor = this.cursor = this.offset = -1;
        this.length = 0;
        this.update();
    }


    void setCells(HexCell start, [HexCell end = null]) {
        this.set(start.offset, end == null ? -1 : end.offset, start.isAscii);
    }

    /** Sets the selected offset range */
    void set(int start, [int end = -1, bool ascii = false, bool backwards = null]) {
        this.ascii = ascii;
        if (start < 0) {
            this.clear();
        } else {
            bool noEnd = end == -1;
            if (noEnd) {
                end = start;
            }

            if (end > this.hexEditor.data.length) {
                end = this.hexEditor.data.length;
            }

            this.offset = start < end ? start : end;
            this.length = noEnd ? 0 : ((end - start).abs() + 1);

            this.anchor = start;
            this.cursor = noEnd ? start : end;

            if (backwards == null) {
                backwards = this.cursor < this.anchor;
            }

            this._backwards = backwards;

            if (this.lineSelection && end != this.hexEditor.data.length) {
                this.length -= this.length % this.grid.columnCount ;
            }
        }

        this.update();
        this.hexEditor.onSelectionChanged.raise(this);
    }

    /** Starts the mouse selection of rows */
    void startLine(HexRow row) {
        this.start(row.offset);
        this.lineSelection = true;
        this.set(row.offset, row.offset + 15);
        this.dragging = true;
    }

    /** Starts the mouse selection of cells */
    void start(int offset, [bool ascii = false]) {
        this.lineSelection = false;
        this.set(offset, -1, ascii);
        this.dragging = true;

        this.grid.captureMouse(this.drag, this.cancelDrag);
    }

    void drag(MouseEvent e) {
        if (this.dragging) {
            // e.toElement might contain the row/cell element, but the rows/cells will need to be enumerated
            // anyway, in order to get the HexCell instance.
            HexRow row = this.grid.getNearestRowAt(e.client);

            if (this.lineSelection) {
                this.add(row.offset);
            } else {
                HexCell cell = row.getNearestCellAt(e.client);

                int offset = cell.offset;

                // don't select the end cell unless the cursor is on or beyond it
                if (e.target != cell) {
                    if (this.anchor < offset) {
                        if (e.client.x < cell.element.offset.left + row.rect.left) {
                            offset--;
                        }
                    } else if (e.client.x > cell.element.offset.right + row.rect.left) {
                        offset++;
                    }
                }

                this.ascii = cell.isAscii;
                this.add(offset);
            }
        }
    }

    void cancelDrag(MouseEvent e) {
        this.end();
    }

    /** Add the offset to the selection. */
    void add(int offset) {
        if (offset > this.hexEditor.data.length) {
            offset = this.hexEditor.data.length;
        }

        if (this.anchor < 0) {
            this.anchor = offset;
        }
        if (this.cursor < 0) {
            this.cursor = offset;
        }

        this.length = (this.anchor - offset).abs() + 1;

        if (offset < this.anchor) {
            this.cursor = this.offset = offset;
        } else {
            this.cursor = offset;
            this.offset = anchor;
        }

        if (this.lineSelection) {
            if (this.length % this.grid.columnCount != 0) {
                this.length -= this.length % this.grid.columnCount;
            }
        }

        this.update();

        this.hexEditor.onSelectionChanged.raise(this);
        //this.set(this.anchor, offset, this.ascii);
    }

    void end() {
        this.lineSelection = false;
        this.dragging = false;
        this.update();
    }

    void addEventHandlers() {
        this.hexEditor.onOffsetChanged.add((HexEdit he) {
            this.update();
        });
        this.hexEditor.onResize.add((HexEdit he) {
            this.update();
        });
    }

    /**
     * Get the bytes that are selected. [limit] is the maximum number of bytes returned (0 for no limit).
     * If there is no selection, an empty list is returned.
     */
    List<int> getBytes([int limit = 0]) {

        if (this.length == 0) {
            return new List<int>(0);
        }

        if (limit <= 0) {
            limit = this.length;
        }
        int end = this.offset + this.length.clamp(0, limit);

        return this.hexEditor.data.getBytes(this.offset, end).toList(growable: false);
    }
}
