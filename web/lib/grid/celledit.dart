part of hexedit.grid;

/**
 * Handles the cell editing.
 */
class CellEditor {
    HexEdit get hexEditor => this.grid.hexEditor;

    HexGrid grid;
    HexCell cell = null;

    SpanElement get cursor => grid.cursor;

    bool editing = false;

    /** cursor position (will only be 0 or 1) */
    int cursorPos = 0;

    /** the text of the current edit */
    String text = "";


    CellEditor(HexGrid grid) {
        this.grid = grid;
    }

    void edit(HexCell cell) {
        if (this.cell != null) {
            this.stopEdit();
        }

        this.editing = true;

        this.cell = cell;
        this.cell.element.classes.add("editing");

        this.text = this.cell.textValue;
        this.cursorPos = 0;

        // get the keys
        this.hexEditor.onKeyDown.add(this.keydown);
        this.hexEditor.onKeyPress.add(this.keypress);

        this.hexEditor.onCursorMove.add(this.cursorMove);

        this.update();
    }

    bool cursorMove(HexCell cell) {
        if (cell != this.cell) {
            this.commit(leaveCursor: true);
        }

        return false;
    }

    bool keypress(KeyEvent e) {
        bool handled = true;
        String ch = new String.fromCharCode(e.charCode);

        if (ch.length == 1 && (this.cell.isAscii || "0123456789abcdefABCDEF".contains(ch))) {
            if (this.cell.isAscii) {
                this.text = ch;
            } else if (this.cursorPos == 0) {
                this.text = ch + this.text.substring(1, 2);
            } else {
                this.text = this.text.substring(0, 1) + ch;
            }

            this.cursorPos++;

            if (this.cell.isAscii || (this.cursorPos > 1 && this.text.length > 1)) {
                this.commit();
                return true;
            }

            this.update();
            handled = true;
        } else {
            switch (e.keyCode) {
                case KeyCode.BACKSPACE:
                    if (this.cursorPos > 0) {
                        this.text = this.text.substring(0, this.cursorPos - 1) + this.text.substring(this.cursorPos + 1);
                    }
                    handled = true;
            }
        }

        if (handled) {
            this.update();
        }

        return handled;
    }

    bool keydown(KeyEvent e) {
        bool handled = false;
        switch (e.keyCode) {
            case KeyCode.LEFT:
                if (this.cursorPos > 0) {
                    this.cursorPos--;
                    handled = true;
                }

                break;

            case KeyCode.RIGHT:
                if (this.cursorPos < this.text.length - 1) {
                    this.cursorPos++;
                    handled = true;
                }

                break;
        }

        if (handled) {
            this.update();
        }

        return handled;
    }

    void update() {
        this.cursor.remove();
        if (this.cell.isAscii) {
            this.cell.update();
        } else {
            this.cell.setText(this.text);
        }

        this.grid.setCursor(this.cell, this.cursorPos);
    }

    void stopEdit({bool leaveCursor: false}) {
        this.hexEditor.onKeyPress.remove(this.keypress);
        this.hexEditor.onKeyDown.remove(this.keydown);
        this.hexEditor.onCursorMove.remove(this.cursorMove);

        this.cell.element.classes.remove('editing');
        //this.cell.setText('');

        this.editing = false;

        if (!leaveCursor) {
            this.grid.setCursor(this.cell, 0);
        }

        this.cell.hex.update();
    }

    void commit({bool leaveCursor: false}) {
        if (this.editing) {
            int byte = 0;

            this.text = this.text.substring(0, this.cell.isAscii ? 1 : 2);

            if (this.cell.isAscii) {
                byte = this.text.codeUnitAt(0) & 0xff;
            } else {
                byte = int.parse(this.text, radix: 16);
            }

            if (this.grid.selection.length > 0) {
                List<int> bytes = new List<int>.filled(this.grid.selection.length, byte);
                this.hexEditor.data.setBytes(this.grid.selection.offset, bytes);
            } else {
                this.hexEditor.data.setByte(this.cell.offset, byte);
            }
        }

        this.stopEdit(leaveCursor: true);

        if (!leaveCursor && this.grid.selection.length == 0) {
            if (this.cell.index >= this.hexEditor.data.length) {
                this.grid.cursorOffset = this.hexEditor.data.length;
            } else {
                this.grid.cursorOffset = this.cell.offset + 1;
            }
        }
    }
}
