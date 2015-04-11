part of hexedit.panels;


/**
 * Displays textual data based on the selection of the grid.
 */
class BitsPanel extends InspectorPanel {
    BitsPanel(String selector) : super(selector);

    SelectElement sizeDropdown;
    TableElement bitsTable;
    List<TableCellElement> bitCells = [];
    ByteConverter bc;
    List<SpanElement> nibbleSpans = [];

    int get offset => this.grid.selection.offset;
    Range range = new Range(0, 0);

    int get bitCount => this.byteCount * 8;
    int byteCount = 0;
    final int MAX_BYTES = 8;
    int requestedLength = 8;

    List<bool> bits = [];

    void create() {
        super.create();


        this.maxDataLength = this.MAX_BYTES;

        this.sizeDropdown = new SelectElement();

        this.bitsTable = new TableElement();
        this.bitsTable.id = "bits";

        TableRowElement addRow(bool top) {
            TableRowElement row = this.bitsTable.addRow();
            row.classes.add("guide");

            String cls = "";

            cls = top ? "byte8" : "byte4";
            TableCellElement cell = row.addCell();
            cell.colSpan = 4;
            cell.classes.add(cls);
            cell.text = top ? '63' : '31';

            cell = row.addCell();
            cell.colSpan = 4;
            cell.classes.add(cls);

            cls = top ? "byte7" : "byte3";
            cell = row.addCell();
            cell.colSpan = 4;
            cell.classes.add(cls);

            cell = row.addCell();
            cell.colSpan = 4;
            cell.classes.add(cls);
            cell.text = ' ';

            cls = top ? "byte6" : "byte2";
            cell = row.addCell();
            cell.colSpan = 4;
            cell.classes.add(cls);
            cell.text = top ? '47' : '15';

            cell = row.addCell();
            cell.colSpan = 4;
            cell.classes.add(cls);

            cls = top ? "byte5" : "byte1";
            cell = row.addCell();
            cell.colSpan = 4;
            cell.classes.add(cls);

            cell = row.addCell();
            cell.style.textAlign = 'right';
            cell.colSpan = 4;
            cell.classes.add(cls);
            cell.text = top ? '32' : '0';

            for (cell in row.cells) {
                SpanElement span = new SpanElement();
                span.text = "0";
                cell.append(span);
                this.nibbleSpans.add(span);
            }

            row = this.bitsTable.addRow();
            row.classes.add("bits");
            return row;
        }

        TableRowElement row = addRow(true);
        TableCellElement cell;

        for (int n = 63; n >= 0; n--) {
            cell = row.addCell();
            bitCells.add(cell);
            cell.dataset["bit"] = n.toString();

            if (n == 32) {
                row = addRow(false);
            }

            cell.text = "${n%2}";
            cell.title = "${n}";
            cell.classes.add("byte${n ~/ 8 + 1}");

            cell.onClick.listen((MouseEvent e) {
                if (n < this.bitCount) {
                    toggleBit(n);
                }
            });
        }

        this.bitCells = this.bitCells.reversed.toList(growable: false);
        this.nibbleSpans = this.nibbleSpans.reversed.toList(growable: false);

        this.element.append(this.sizeDropdown);
        this.element.append(this.bitsTable);

        ButtonElement addButton(String id, String text, String tooltip, void clicked()) {
            ButtonElement button = new ButtonElement();
            button.text = text;
            button.id = id;
            button.title = tooltip;
            button.onClick.listen((MouseEvent e) => clicked());
            this.element.append(button);
            return button;
        }

        addButton("rotateLeft", "(<<)", "Rotate Left", () => this.shift(true, true));
        addButton("shiftLeft", "<<", "Shift Left", () => this.shift(true, false));
        addButton("shiftRight", ">>", "Shift Right", () => this.shift(false, false));
        addButton("rotateRight", "(>>)", "Rotate Right", () => this.shift(false, true));
    }

    void shift(bool left, bool rotate) {

        if (!left) {
            bool first = this.bits.removeAt(0);
            this.bits.add(rotate ? first : false);
        } else {
            bool last = this.bits.removeLast();
            this.bits.insert(0, rotate ? last : false);
        }

        this.bc.fromBits(this.bits);
        this.hexEdit.data.setBytes(this.offset, this.bc.byteList.toList(growable: false));
    }


    void addEventHandlers() {
        super.addEventHandlers();

        this.element.onMouseOver.listen((MouseEvent e) {
            if (e.target is TableCellElement) {
                TableCellElement cell = e.target as TableCellElement;
                if (cell.dataset["bit"] != null) {
                    int bit = int.parse(cell.dataset["bit"]);
                    int byte = bit ~/ 8;

                    this.grid.highlight(this.offset + byte, 1);
                }
            }
        });

        this.element.onMouseOut.listen((MouseEvent e) {
            if (e.target is TableCellElement) {
                this.grid.clearHighlight();
            }
        });

        this.grid.onHighlight.add((Range range) {

            if (range == null) {
                this.bitsTable.dataset["highlight"] = "";
            } else if (range.intersects(this.range)) {
                String highlight = "";
                for (int byte = 0; byte <= this.MAX_BYTES; byte++) {
                    if (range.contains(this.offset + byte)) {
                        highlight += "${byte+1} ";
                    }
                }
                this.bitsTable.dataset["highlight"] = highlight;
            }
        });
    }

    void toggleBit(int bit) {
        int byte = bit ~/ 8;
        int value = this.hexEdit.data.get(this.offset + byte);
        value ^= 1 << (bit % 8);
        this.hexEdit.data.setByte(this.offset + byte, value);
    }

    void clear() {
    }

    void update() {
        super.update();

        if (this.selection.length == 0) {
            this.clear();
            return;
        }

        if (this.explicitSelection) {
            if (this.grid.selection.length > this.MAX_BYTES) {
                this.byteCount = 0;
            } else {
                this.byteCount = this.selection.length.clamp(1, this.MAX_BYTES);
            }
        } else {
            this.byteCount = this.requestedLength;
        }

        this.range.start = this.offset;
        this.range.length = this.byteCount;
        Uint8List byteList = new Uint8List.fromList(this.selection.take(this.byteCount).toList());
        this.bc = new ByteConverter(byteList);

        this.bits = this.bc.toBits(this.byteCount);

        String bytes = "";
        for (int byte = 1; byte <= this.byteCount; byte++) {
            bytes += "${byte} ";
        }

        this.bitsTable.dataset["bytes"] = bytes;
        this.bitsTable.dataset["size"] = this.byteCount.toString();


        int n = 0;
        for (bool bit in this.bits) {
            this.bitCells[n++].text = bit ? "1" : "0";
        }

        while (n < this.MAX_BYTES * 8) {
            this.bitCells[n++].innerHtml = '';
        }

        int nibble = 0;
        for (int byte = 0; byte < this.MAX_BYTES * 2; byte++) {
            if (byte < this.byteCount) {
                int b = byteList[byte];
                this.nibbleSpans[nibble++].text = (b & 0x0f).toRadixString(16);
                this.nibbleSpans[nibble++].text = ((b >> 4) & 0x0f).toRadixString(16);
            }
        }

    }
}
