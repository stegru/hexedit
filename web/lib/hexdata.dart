part of hexedit;

/**
 * Data buffer.
 */
class HexData {
    bool _resizable = false;
    bool _readOnly = false;

    bool get resizable => this._resizable && !this.readOnly;

    bool get readOnly => this._readOnly;

    get length => this._dataLength;

    int _dataLength;

    Uint8List buffer;

    Undo undo;

    EventSource<Range> onDataModified = null;
    EventSource<HexData> onModeChanged = new EventSource<HexData>();
    EventSource<HexData> onDataReset = new EventSource<HexData>();


    /** Gets the byte at [offset]. */
    int get(int offset) {
        if (offset < 0 || offset > this.length - 1) {
            return null;
        }

        return this.buffer[offset];
    }

    /** Gets the bytes from [offset] to [end]. */
    Uint8List getBytes(int offset, int end) {
        if (offset < 0) {
            return null;
        }

        end = end.clamp(offset, this.length);

        Uint8List tmp = new Uint8List(end - offset);
        tmp.setRange(0, end - offset, this.buffer, offset);
        return tmp;
    }

    HexData(HexEdit hexEdit, Uint8List buffer) {
        this.reset(hexEdit, buffer);
    }

    /** Sets the buffer to a new one, specified by [buffer]. If [buffer] is null, an empty one is created. */
    void reset(HexEdit hexEdit, [Uint8List buffer = null]) {
        if (this.buffer != null) {
            try {
                this.buffer.clear();
            }
            catch (e) {
            }
        }
        if (buffer == null) {
            this.buffer = new Uint8List(0);
        } else {
            this.buffer = buffer;
        }

        this._dataLength = this.buffer.length;

        this.undo = new Undo(this, hexEdit);

        hexEdit.onDataReset.raise(hexEdit);

        if (this.onDataModified != null) {
            this.onDataModified.raise(new Range(0, this._dataLength));
        }
    }

    void _onModeChanged() {
        this.onModeChanged.raise(this);
    }

    void set resizable(bool newValue) {
        if (this._resizable != newValue) {
            this._resizable = newValue;
            // the getter has more logic, check if the value really has changed
            if (this.resizable == newValue) {
                this._onModeChanged();
            }
        }
    }

    void set readOnly(bool newValue) {
        if (this._readOnly != newValue) {
            this._readOnly = newValue;
            this._onModeChanged();
        }
    }

    /*** Sets the byte at [offset] to [value]. */
    void setByte(int offset, int value) {
        this.setBytes(offset, [value]);
    }

    /*** Copies [bytes] onto the buffer at [offset]. */
    void setBytes(int offset, List<int> bytes) {
        if (this.readOnly || offset < 0) {
            return;
        } else if (offset + bytes.length > this.length) {
            return;
        }

        Range range = new Range(offset, offset + bytes.length);
        this.undo.addSet(range);

        this.buffer.setRange(offset, offset + bytes.length, bytes);
        this.onDataModified.raise(range);
    }

    /*** Inserts [byte] into the butter at [offset]. */
    void insertByte(int offset, int byte) {
        this.insertBytes(offset, [byte]);
    }

    /*** Inserts [bytes] into the butter at [offset]. */
    void insertBytes(int offset, List<int> bytes) {
        if (offset < 0 || offset > this.length || !this.resizable) {
            return;
        }

        int len = bytes.length;
        this.undo.addInsert(new Range(offset, offset + len), bytes);

        if (this.buffer.length < this.length + len) {
            Uint8List newBuffer = new Uint8List(((this.length + len) * 1.5).ceil());
            newBuffer.setRange(0, offset, this.buffer);
            newBuffer.setRange(offset, offset + len, bytes);
            newBuffer.setRange(offset + len, this.length + len, this.buffer, offset);
            this.buffer = newBuffer;
        } else {
            this.buffer.setRange(offset + len, this.length + len, this.buffer, offset);
            this.buffer.setRange(offset, offset + len, bytes);
        }

        this._dataLength += len;
        this.onDataModified.raise(new Range(offset, this.length));
    }

    /*** Deletes [len] bytes from the buffer at [offset]. */
    void delete(int offset, int len) {
        if (offset < 0 || offset > this.length || !this.resizable) {
            return;
        }

        if (offset + len > this.length) {
            len = this.length - offset;
        }

        int end = offset + len;

        this.undo.addDelete(new Range(offset, end));

        // move all data after the deletion to the start of the deletion
        this.buffer.setRange(offset, this.length - len, this.buffer, end);
        this._dataLength -= len;
        this.onDataModified.raise(new Range(offset, this.length));
    }
}

class Range {
    int start = 0;
    int end = 0;

    int get length => this.end - this.start;

    void set length(int len) {
        this.end = this.start + len;
    }

    Range(this.start, this.end);

    bool contains(int value) {
        return value >= this.start && value < this.end;
    }

    bool intersects(Range range) {
        return this.contains(range.start) || this.contains(range.end) || range.contains(this.start)
               || range.contains(this.end);
    }

    Range copy() {
        return new Range(this.start, this.end);
    }


}

class UndoInstruction {
    static const int SET = 1;
    static const int INSERT = 2;
    static const int DELETE = 3;

    final int type;
    final Range range;
    final List<int> bytes;

    UndoInstruction(HexData data, this.type, this.range, this.bytes) {
        //print("${this.type} ${this.range.start}-${this.range.end} ${this.bytes.length}");
    }

    factory UndoInstruction.set(Undo undo, Range range) {
        return new UndoInstruction(undo.hexEdit.data, SET, range.copy(), undo.data.getBytes(range.start, range.end));
    }

    factory UndoInstruction.insert(Undo undo, Range range, List<int> data) {
        return new UndoInstruction(undo.hexEdit.data, INSERT, range.copy(), data.toList(growable:false));
    }

    factory UndoInstruction.delete(Undo undo, Range range) {
        return new UndoInstruction(undo.hexEdit.data, DELETE, range.copy(), undo.data.getBytes(range.start, range.end));
    }

    Range perform(HexData data) {
        Range modified = this.range.copy();

        switch (this.type) {
            case SET:
                data.setBytes(this.range.start, this.bytes);
                modified.length = this.bytes.length - 1;
                break;
            case INSERT:
                data.delete(this.range.start, this.range.length);
                modified.end = -1;
                break;
            case DELETE:
                data.insertBytes(this.range.start, this.bytes);
                modified.length = this.bytes.length - 1;
                break;
        }

        return modified;
    }
}

class Undo {
    bool undoing = false;
    bool redoing = false;
    final HexData data;
    final HexEdit hexEdit;

    static const int LARGEST_SIZE = 0xFFFF;

    List<UndoInstruction> undo = new List<UndoInstruction>();
    List<UndoInstruction> redo = new List<UndoInstruction>();

    bool get canUndo => this.undo.length > 0;

    bool get canRedo => this.redo.length > 0;

    List<UndoInstruction> get current => this.undoing ? this.redo : this.undo;

    List<UndoInstruction> get other => this.undoing ? this.undo : this.redo;

    Undo(HexData this.data, HexEdit this.hexEdit) {
    }

    void undoChanged() {
        if (!this.undoing && !this.redoing) {
            this.redo.clear();
        }
    }

    void addSet(Range range) {
        this.current.add(new UndoInstruction.set(this, range));
        this.undoChanged();
    }

    void addInsert(Range range, List<int> data) {
        this.current.add(new UndoInstruction.insert(this, range, data));
        this.undoChanged();
    }

    void addDelete(Range range) {
        this.current.add(new UndoInstruction.delete(this, range));
        this.undoChanged();
    }

    void performUndo() {
        this.undoing = true;
        this._perform();
        this.undoing = false;
    }

    void performRedo() {
        this.redoing = true;
        this._perform();
        this.redoing = false;
    }

    void _perform() {
        if (this.other.length == 0) {
            return;
        }

        UndoInstruction ins = this.other.removeLast();
        Range r = ins.perform(this.data);
        this.hexEdit.hexGrid.selection.set(r.start, r.end);

        this.undoChanged();
    }
}
