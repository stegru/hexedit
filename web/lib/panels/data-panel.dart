part of hexedit.panels;

/**
 * A panel that gets updated when the selection changes.
 */
abstract class InspectorPanel extends Panel {
    /// The largest selection (the size of the sample taken from the grid).
    static const int LARGEST_ITEM = DataType.LARGEST_ITEM;

    /// The largest selection.
    int maxDataLength = LARGEST_ITEM;

    /// The selection.
    List<int> selection;

    /// true if the selection was explicitly selected (highlighted).
    bool explicitSelection = false;


    InspectorPanel(String selector) : super(selector) {
    }

    void create() {
        super.create();
    }

    void addEventHandlers() {
        super.addEventHandlers();
        this.hexEdit.onSelectionChanged.add((Selection selection) {
            this.update();
            return true;
        });
        this.hexEdit.onDataModified.add((Range range) {
            this.update();
            return true;
        });
    }

    void update() {
        if (!this.expanded) {
            return;
        }

        this.explicitSelection = (this.grid.selection.length > 0);
        if (!this.explicitSelection) {
            this.selection = this.hexEdit.data.getBytes(this.grid.cursorOffset,
                                                        this.grid.cursorOffset
                                                        + this.maxDataLength).toList(growable:false);
        }
        else {
            this.selection = this.grid.selection.getBytes(this.maxDataLength);
        }
    }
}

/**
 * Panel showing several numbers that the selected bytes represent.
 */
abstract class DataPanel extends InspectorPanel {
    ByteConverter byteConverter;

    TableElement table = new TableElement();

    bool hex = true;
    int get radix => this.hex ? 16 : 10;

    List<DataItem> items = new List<DataItem>();
    List<DataItem> getItems();

    DataPanel(String selector) : super(selector) {
        this.title = "";
    }

    void create() {
        super.create();

        this.items = this.getItems();
        this.items.forEach((item) => item.createItem(this));

        this.element.append(this.table);
    }

    void update() {
        super.update();
        Uint8List bytes = new Uint8List.fromList(this.selection);
        this.byteConverter = new ByteConverter(bytes);

        for (DataItem item in this.items) {
            item.update(this.byteConverter, exactSize: this.explicitSelection);
        }
    }
}

class DataItem extends Component<InputElement> {
    DataType dataType;

    bool canChange = true;
    bool ignoreUpdate = false;

    String value;
    String originalValue;
    Uint8List originalBytes;
    int bytesUsed;

    TableRowElement row;
    LabelElement label;

    DataPanel panel;
    static int lastId = 0;

    DataItem({DataType this.dataType, bool this.canChange: true}) {

    }

    void update(ByteConverter bc, {bool exactSize: false}) {
        if (this.ignoreUpdate) {
            return;
        }

        String value = null;
        bool failed = false;

        if (!this.dataType.variableSize && ((bc.byteCount < this.dataType.byteCount) || (exactSize
                                                                                         && bc.byteCount != this.dataType.byteCount))) {
            failed = true;
            value = null;
        } else {
            if (this.dataType.endian == null) {
                bc.endian = Endianness.HOST_ENDIAN;
            } else {
                bc.endian = this.dataType.endian;
            }

            try {
                value = this.dataType.getString(this.dataType, bc);
            }
            on ByteConverterException catch (e) {
                failed = true;
                value = e.toString();
            }

            this.bytesUsed = this.dataType.variableSize ? bc.bytesUsed : this.dataType.byteCount ;
        }

        if (value == null || failed) {
            this.element.value = "";
            this.element.placeholder = value == null ? "" : value;
            this.element.disabled = true;
            this.bytesUsed = this.dataType.variableSize ? 0 : this.dataType.byteCount;
        } else {
            this.element.value = value.toString();
            this.element.placeholder = "";
            this.element.disabled = false;
            this.element.readOnly = (!exactSize && this.dataType.variableSize) || !this.canChange;
        }
    }

    void createItem(DataPanel panel) {
        this.panel = panel;
        this.row = this.panel.table.addRow();
        TableCellElement textCell = this.row.addCell();
        TableCellElement valueCell = this.row.addCell();

        if (this.dataType.isNumeric && this.dataType.byteCount <= 4) {
            this.element = new NumberInputElement();
        } else {
            this.element = new TextInputElement();
        }

        this.element.classes.add("inspectorValue");

        this.label = new LabelElement();
        this.label.htmlFor = this.element.id = "_inspector_value${++lastId}";
        this.label.text = this.dataType.name;


        textCell.append(this.label);
        valueCell.append(this.element);

        // add the hover/highlight events
        this.row.onMouseOver.listen((Event e) {
            this.hoverHighlight(true);
        });

        this.element.onFocus.listen((Event e) {
            this.hoverHighlight(true);
            this.value = this.originalValue = this.element.value;
        });


        this.row.onMouseOut.listen((MouseEvent e) {
            this.hoverHighlight(false);
        });

        this.element.onBlur.listen((Event e) {
            this.hoverHighlight(false);
        });

        // text change events
        this.element.onInput.listen((Event e) {
            this.valueChanged();
        });

        this.label.onClick.listen((Event e) {
            if (this.element.disabled || this.element.readOnly) {
                this.selectCells();
            }
        });

        this.label.onDoubleClick.listen((Event e) {
            this.selectCells();
        });
    }

    void selectCells() {
        if (this.bytesUsed > 0) {
            this.panel.grid.selection.set(this.panel.grid.selection.offset,
                                          this.panel.grid.selection.offset + this.bytesUsed - 1);
        }
    }

    void valueChanged() {
        if (this.element.value == this.value) {
            return;
        }

        this.value = this.element.value;

        int len;

        if (this.dataType.variableSize) {
            len = this.panel.grid.selection.length;
        } else {
            len = this.dataType.byteCount;
        }

        Uint8List bytes = new Uint8List(len);
        ByteConverter bc = new ByteConverter(bytes);

        if (!this.dataType.setString(this.dataType, bc, this.value)) {
            return;
        }

        try {
            this.ignoreUpdate = true;
            this.panel.hexEdit.data.setBytes(this.panel.grid.selection.offset, bytes.toList(growable: false));
        }
        finally {
            this.ignoreUpdate = false;
        }
    }

    void hoverHighlight(bool hoverIn) {
        if (hoverIn) {
            if (document.activeElement.classes.contains("inspectorValue")) {
                // if there's another inspector textbox focused, don't highlight a different one.
                if (document.activeElement != this.element) {
                    return;
                }
            }

            panel.grid.highlight(panel.grid.selection.offset, this.bytesUsed);
        } else {
            // clear the highlight only if there isn't an inspector field focused.
            if (this.panel.hexEdit.hasFocus || document.activeElement == null
                || !document.activeElement.classes.contains("inspectorValue")) {
                panel.grid.clearHighlight();
            }
        }
    }
}
