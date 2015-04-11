part of hexedit;

class KeyHandler {
    final HexEdit hexEditor;

    HexGrid get grid => this.hexEditor.hexGrid;

    EventSource<KeyEvent> onKeyPress = new EventSource<KeyEvent>();
    EventSource<KeyEvent> onKeyDown = new EventSource<KeyEvent>();
    EventSource<KeyEvent> onKeyUp = new EventSource<KeyEvent>();

    static KeyHandler instance = null;

    factory KeyHandler(HexEdit hexEditor) {
        if (instance == null) {
            instance = new KeyHandler._(hexEditor);
        }
        return instance;
    }

    KeyHandler._(this.hexEditor) {
        // Key events are taken from the window, as though the hex grid always has focus. The events will always be
        // sent to the grid, unless an event handler returns true.
        this.windowKeyDown = window.onKeyDown.listen((KeyboardEvent e) => this.handleKeyEvent(e,
                                                                                              this.onKeyDown,
                                                                                              this.keydown));

        this.windowKeyPress = window.onKeyPress.listen((KeyboardEvent e) => this.handleKeyEvent(e,
                                                                                                this.onKeyPress,
                                                                                                this.keypress));
        this.windowKeyUp = window.onKeyUp.listen((KeyboardEvent e) => this.handleKeyEvent(e, this.onKeyUp,
                                                                                          this.keyup));

    }

    StreamSubscription<KeyboardEvent> windowKeyDown = null;
    StreamSubscription<KeyboardEvent> windowKeyPress = null;
    StreamSubscription<KeyboardEvent> windowKeyUp = null;

    void handleKeyEvent(KeyboardEvent kbe, EventSource<KeyEvent> event, EventHandler<KeyEvent> defaultHandler) {
        KeyEvent e = new KeyEvent.wrap(kbe);

        if (Dialog.active != null) {
            if (e.keyCode == KeyCode.ESC) {
                Dialog.active.dismiss(null);
            }
            return;
        }

        bool handled = event.raise(e, true);
        if (!handled && this.hexEditor.hasFocus) {
            handled = defaultHandler(e);
        }

        if (handled) {
            e.stopPropagation();
            e.preventDefault();
            return;
        }
    }

    bool keypress(KeyEvent e) {
        if (!e.altKey && !e.ctrlKey && !e.metaKey) {
            String char = new String.fromCharCode(e.charCode);
            if ((char.length == 1) && (this.grid.cursorCell.isAscii || "0123456789abcdefABCDEF".contains(char))) {
                if (this.hexEditor.data.resizable) {
                    if (this.grid.selection != 1) {
                        if (this.grid.selection.length > 0) {
                            this.grid.deleteSelection();
                        }
                        this.hexEditor.data.insertByte(this.grid.cursorOffset, 0x00);
                    }
                }

                this.grid.cursorCell.edit();
                return this.hexEditor.onKeyPress.raise(e);
            }
        }


        return false;
    }

    bool keydown(KeyEvent e) {
        int offset = this.grid.cursorOffset;
        bool changeGrid = false;
        bool handled = false;

        HexCell nextCell = null;
        Direction dir = null;

        if (e.ctrlKey) {
            switch (e.keyCode) {
                case KeyCode.A: // select all
                    this.grid.selection.set(0, this.grid.hexEditor.data.length);
                    return true;
            }
        }

        switch (e.keyCode) {
        // cursor movement
            case KeyCode.LEFT:
                dir = Direction.LEFT;
                break;
            case KeyCode.RIGHT:
                dir = Direction.RIGHT;
                break;
            case KeyCode.UP:
                dir = Direction.UP;
                break;
            case KeyCode.DOWN:
                dir = Direction.DOWN;
                break;

        // move to the first column
            case KeyCode.HOME:
                if (e.ctrlKey) {
                    offset = 0;
                }
                else {
                    offset -= offset % this.grid.columnCount;
                }

                if (this.grid.cursorCell.isAscii && (offset == this.grid.cursorOffset)) {
                    changeGrid = true;
                }

                handled = true;
                break;

        // move to the last column
            case KeyCode.END:
                if (e.ctrlKey) {
                    offset = this.hexEditor.data.length;
                }
                else {
                    offset = offset - (offset % 16) + 15;
                }

                if (!this.grid.cursorCell.isAscii && (offset == this.grid.cursorOffset)) {
                    changeGrid = true;
                }

                handled = true;
                break;

        // move up a page
            case KeyCode.PAGE_UP:
                offset -= (this.grid.rowCount - 2) * this.grid.columnCount;
                handled = true;
                break;
        // move down a page
            case KeyCode.PAGE_DOWN:
                offset += (this.grid.rowCount - 2) * this.grid.columnCount;
                handled = true;
                break;


            case KeyCode.DELETE:
                this.grid.deleteSelection();
                return true;

            case KeyCode.BACKSPACE:
                handled = true;
                if (this.grid.selection.length == 0) {
                    this.grid.deleteSelection(true);
                    offset--;
                    break;
                }
                else {
                    this.grid.deleteSelection();
                }
                return true;

            case KeyCode.INSERT:
                this.hexEditor.data.insertByte(offset, 0x12);
                this.grid.update();
                return true;

            case KeyCode.TAB:
                this.grid.setCursor(this.grid.cursorCell.linked);
                return true;

            default:
                return false;
        }

        if (dir != null) {

            if (!e.shiftKey && dir.horizontal) {
                // left/right can move to the hex/ascii grid
                if (this.grid.cursorCell.isAscii && dir == Direction.LEFT && this.grid.cursorCell.index == 0) {
                    this.grid.selection.setCells(this.grid.cursorCell.row.hexCells.last);
                    return true;
                }
                else if (!this.grid.cursorCell.isAscii && dir == Direction.RIGHT && this.grid.cursorCell.index == 15) {
                    this.grid.selection.setCells(this.grid.cursorCell.row.asciiCells.first);
                    return true;
                }
            }

            offset += dir.x;
            offset += dir.y * this.grid.columnCount;

        }

        offset = offset.clamp(0, this.hexEditor.data.length);

        bool newGrid = this.grid.cursorCell.isAscii != changeGrid;

        if (offset != this.grid.cursorOffset) {
            if (e.shiftKey) {
                if (this.grid.selection.length == 0) {
                    if (dir == Direction.LEFT) {
                        this.grid.selection.set(offset, offset, newGrid, true);
                    }
                    else if (dir == Direction.RIGHT) {
                        this.grid.selection.set(this.grid.cursorOffset, this.grid.cursorOffset, newGrid, false);
                    }
                    else if (offset < this.grid.cursorOffset) {
                            this.grid.selection.set(this.grid.cursorOffset - 1, offset, newGrid);
                        }
                        else {
                            this.grid.selection.set(this.grid.cursorOffset, offset - 1, newGrid);
                        }
                }
                else {
                    this.grid.selection.add(offset);
                }
            }
            else {
                this.grid.selection.set(offset, -1, newGrid);
            }

            return true;
        }
        else if (changeGrid) {
            this.grid.setCursor(newGrid ? this.grid.cursorCell.ascii : this.grid.cursorCell.hex);
            return true;
        }

        return handled;
    }

    bool keyup(KeyEvent e) {
        return false;
    }
}
