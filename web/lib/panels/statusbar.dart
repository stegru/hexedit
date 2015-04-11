part of hexedit.panels;


typedef void UpdateCallback();

/**
 * Status bar, displayed at the bottom of the screen.
 */
class StatusBar extends Panel {

    StatusBar() : super("#statusBar") {
    }

    SpanElement position;
    SpanElement selection;
    SpanElement editMode;
    SpanElement length;

    HashMap<SpanElement, UpdateCallback> items = new HashMap<SpanElement, UpdateCallback>();

    void addEventHandlers() {
        super.addEventHandlers();

        this.element.onClick.listen((MouseEvent) {
            this.hexEdit.hexGrid.update(true);
        });

        this.hexEdit.data.onModeChanged.add((HexData hd) {
            this.update(this.editMode);
            return false;
        });

        this.hexEdit.onCursorMove.add((HexCell cell) {
            this.update(this.position);
            return false;
        });

        this.hexEdit.onSelectionChanged.add((Selection he) {
            this.update(this.position);
            return false;
        });

        this.hexEdit.onDataReset.add((HexEdit he) {
            this.update(this.length);
        });
        this.hexEdit.onDataModified.add((Range range) {
            this.update(this.length);
        });
    }

    void update([SpanElement item = null]) {
        if (item == null) {
            this.items.keys.forEach((item) => this.update(item));
        } else {
            UpdateCallback cb = this.items[item];
            if (cb != null) {
                cb();
            }
        }
    }

    SpanElement addItem(String id, {String tooltip: null, UpdateCallback update: null}) {
        SpanElement span = this.$("#${id}");
        if (span == null) {
            return null;
        }
        if (tooltip != null) {
            span.title = tooltip;
        }

        this.items[span] = update;

        return span;
    }

    void create() {
        super.create();

        this.position = this.addItem(
                "position",
                update: () {
                    int len = this.hexEdit.hexGrid.selection.length;
                    if (len == 0) {
                        this.position.text = this.hexEdit.hexGrid.selection.offset.toRadixString(16);
                        this.selection.text = "";
                        //this.selection.classes.add('hide');
                    } else {
                        this.position.text = "${this.hexEdit.hexGrid.selection.offset.toRadixString(16)}:${(this.hexEdit.hexGrid.selection.offset + len).toRadixString(16)}";
                        this.selection.text = "(${len} bytes selected)";
                        //this.selection.classes.remove('hide');
                    }
                });
        this.editMode = this.addItem(
                "editMode",
                tooltip: "Edit mode",
                update: () {
                    this.editMode.text = (this.hexEdit.data.resizable ? "INS" : "OVR") + (this.hexEdit.data.readOnly
                                                                                          ? " RO" : " RW");
                });
        this.length = this.addItem(
                "length",
                update: () {
                    this.length.text = "${this.hexEdit.data.length} bytes";
                });

        this.selection = this.$('#selection') as SpanElement;


        this.update();
    }


}
