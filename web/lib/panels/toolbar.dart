part of hexedit.panels;
/*

 */

/**
 * Toolbar, buttons displayed at the top of the screen.
 */
class ToolBar extends Panel {
    List<ToolItem> items;

    ToolBar() : super("#toolBar") {

        items = [
                new ToolItem("file-o", "New", KeyCode.N, () {
                    this.hexEdit.newFile();
                }),
                new ToolItem("folder-open-o", "Open", KeyCode.O, () {
                    this.hexEdit.openFile();
                }),
                new ToolItem("save", "Save", KeyCode.S, () {
                    print("TODO: save");
                }),
                null,
                new ToolItem("cut", "Cut", 0, () {
                    print("TODO: cut");

                }),
                new ToolItem("copy", "Copy", 0, () {

                }),
                new ToolItem("paste", "Paste", 0, () {

                }),
                null,
                new ToolItem("eraser", "Delete", 0, () {
                    this.grid.deleteSelection();
                }),

                null,

                new ToolItem("undo", "Undo", KeyCode.Z, () {
                    this.hexEdit.data.undo.performUndo();
                }, (ToolItem t) {
                    t.enabled = this.hexEdit.data.undo.canUndo;
                }),

                new ToolItem("repeat", "Redo", KeyCode.Y, () {
                    this.hexEdit.data.undo.performRedo();
                }, (ToolItem t) {
                    t.enabled = this.hexEdit.data.undo.canRedo;
                }),

                null,
                new ToolItem("location-arrow", "Go to", KeyCode.G, () {
                    Panel.gotoPanel.focus();
                }),
                new ToolItem("search", "Find", KeyCode.F, () {
                    Panel.findPanel.expand();
                }),
        ];

    }

    void create() {

        super.create();

        DivElement groupElement = null;


        if (!this.hexEdit.hexGrid.hasClipboard) {
            ToolItem cut = this.items.firstWhere((item) => item != null && item.id == "cut", orElse: () => null);
            if (cut != null) {
                int pos = this.items.indexOf(cut);
                if (pos >= 0) {
                    this.items.removeRange(pos, pos + 4);
                }
            }
        }


        bool newGroup = true;
        for (ToolItem item in this.items) {
            if (item == null) {
                newGroup = true;
                continue;
            }

            this.hexEdit.toolItems[item.id] = item;

            if (newGroup) {
                groupElement = new DivElement();
                groupElement.classes.add("button-group");
                this.element.append(groupElement);
            }

            item.container = groupElement;

            //item.gap = gap;
            item.toolBar = this;
            item.create();

            newGroup = false;
        }

        SelectElement select = new SelectElement();
        Charset.fillSelectElement(select);
        select.onChange.listen((Event e) {
            SelectElement select = e.target;
            Charset.get(select.value).load(this.grid);

        });

        this.element.append(select);

        this.hexEdit.onDataModified.add((r) {
            this.update();
        });

        this.hexEdit.onKeyDown.add(this.keyDown);
    }

    void update() {
        for (ToolItem item in this.items) {
            if (item != null) {
                item.update();
            }
        }
    }

    bool keyDown(KeyEvent e) {
        if (e.ctrlKey || e.altKey) {
            for (ToolItem item in this.items) {
                if (item != null && item.keyCode != 0) {
                    if (e.keyCode == item.keyCode) {
                        if (e.type == "keydown") {
                            item.click();
                        }
                        return true;
                    }
                }
            }
        }

        return false;
    }
}

typedef void UpdateToolItem(ToolItem t);

class ToolItem extends Component<DivElement> {
    static final SPACE = new ToolItem("", "", 0, null);
    ToolBar toolBar;
    DivElement container;
    final Function action;
    final UpdateToolItem _update;
    final String text;
    final String id;
    final int keyCode;
    bool gap = false;

    bool _enabled = true;

    set enabled(bool newValue) {
        this._enabled = newValue;
        if (newValue) {
            this.element.classes.remove('disabled');
        }
        else {
            this.element.classes.add('disabled');
        }
    }

    bool get enabled => this._enabled;

    ToolItem(String this.id, String this.text, int this.keyCode, Function this.action, [Function this._update = null]) {
        this.element = new DivElement();

        this.element.classes.addAll([ "toolItem", "fa-${this.id}"]);

//        SpanElement icon = new SpanElement();
//        icon.classes.addAll(["fa", "fa-${this.id}"]);
//
//        this.element.append(icon);
        this.element.appendHtml("<span>${this.text}</span>");

        this.element.onClick.listen((Event e) {
            this.click();
        });
    }

    void click() {
        if (this.enabled) {
            this.action();
        }
    }

    void create() {
        if (this.container == null) {
            this.container = this.toolBar.element;
        }

        this.container.append(this.element);
    }

    void update() {
        if (this._update != null) {
            this._update(this);
        }
    }
}

