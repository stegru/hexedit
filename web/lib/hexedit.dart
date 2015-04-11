library hexedit;
import "dart:html" hide Range, Selection, EventSource;

import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:fixnum/fixnum.dart';

import 'panels/panel.dart';
import 'grid/grid.dart';
import 'file_io/file_io.dart';

part 'component.dart';
part 'events.dart';
part 'ui/scrollbar.dart';
part 'enums.dart';
part 'keyhandler.dart';
part 'hexdata.dart';
part 'byteconverter.dart';
part 'storage.dart';
part 'ui/dialog.dart';
part 'ui/progress.dart';

/**
 * Hex editor.
 */
class HexEdit extends Component<DivElement> {
    HexGrid hexGrid;
    DivElement hexContainer;

    CssStyleSheet style;

    HexData data;
    Scrollbar scroll;

    int get cursorPos => this.hexGrid.cursorOffset;

    void set cursorPos(int pos) {
        this.hexGrid.cursorOffset = pos;
    }

    Map<String, ToolItem> toolItems = new Map<String, ToolItem>();


    HexEditEvent onReady = new HexEditEvent();
    HexEditEvent onOffsetChanged = new HexEditEvent();
    HexEditEvent onDataReset = new HexEditEvent();
    HexEditEvent onResize = new HexEditEvent();

    EventSource<Range> onDataModified = new EventSource<Range>();

    EventSource<HexCell> onCursorMove = new EventSource<HexCell>();
    EventSource<Selection> onSelectionChanged = new EventSource<Selection>();

    EventSource<KeyEvent> get onKeyPress => this.keyHandler.onKeyPress;
    EventSource<KeyEvent> get onKeyDown => this.keyHandler.onKeyDown;
    EventSource<KeyEvent> get onKeyUp => this.keyHandler.onKeyUp;

    bool get hasFocus {
        return document.activeElement == null || document.activeElement == document.body;
    }

    void focus() {
        document.body.focus();
    }

    KeyHandler keyHandler;

    static HexEdit _instance = null;

    factory HexEdit(){
        if (_instance == null) {
            _instance = new HexEdit._();
        }
        return _instance;
    }

    HexEdit._(){
        this.keyHandler = new KeyHandler(this);
    }

    void start(String containerSelector, String hexContainerSelector) {
        this.element = querySelector(containerSelector);
        this.hexContainer = this.element.querySelector(hexContainerSelector);

        this.hexGrid = new HexGrid(this);

        this.data = new HexData(this, new Uint8List.fromList(new List<int>()));
        this.data.onDataModified = this.onDataModified;

        this.create();

        new Timer(const Duration(milliseconds: 10), () {
            document.querySelector('#all').style.removeProperty("visibility");
            Panel.createAll(this);
            this.hexGrid.adjustSize();
            this.onReady.raise(this);
            this.hexGrid.selection.set(0, -1);

            new Timer(const Duration(milliseconds: 150), () {
                Element splash = document.querySelector('#splashWrapper');
                splash.onTransitionEnd.listen((TransitionEvent e) {
                    splash.remove();
                });
                splash.classes.add("hide");
            });
        });
    }

    void setData(HexData buffer) {
        this.data = buffer;
        this.hexGrid.range = new Range(-1, 0);
        this.hexGrid.cursorOffset = 0;
        this.onDataReset.raise(this);
        this.data.onDataModified = this.onDataModified;
    }

    void create() {
        this.hexGrid.create();
        this.hexContainer.append(this.hexGrid.element);
        this.hexGrid.created();

        this.scroll = new Scrollbar();
        this.scroll.create();
        this.hexContainer.append(this.scroll.element);

        super.create();
    }

    void addEventHandlers() {
        this.hexGrid.element.onMouseWheel.listen((WheelEvent e) {
            this.hexGrid.line += e.deltaY.ceil().clamp(-1, 1) * 3;
        });

        this.scroll.element.onMouseWheel.listen((WheelEvent e) {
            this.hexGrid.line += e.deltaY.ceil().clamp(-1, 1) * (this.hexGrid.rowCount ~/ 3);
        });

        this.onOffsetChanged.add((he) {
            this.scroll.setPos(this.scroll.pos = this.hexGrid.line.toDouble());
        });

        this.scroll.onScroll.add((scroll) {
            this.hexGrid.line = scroll.pos.round();
        });

        EventHandler updateScroll = (he) {
            int pos = this.hexGrid.element.offsetLeft + this.hexGrid.element.offsetWidth;
            this.scroll.element.style.left = "${pos}px";

            int top = this.hexGrid.rows.first.element.offsetTop;
            this.scroll.element.style.marginTop = "${top}px";
            this.scroll.element.style.paddingBottom = "${top}px";

            int bottom = this.hexGrid.bottomPanels.offset.height;
            this.scroll.element.style.height = "calc(100% - ${(bottom + top)}px)";

            this.scroll.ignoreScroll = true;
            this.scroll.heightAdjustment = top;
            this.scroll.setRange(0, this.hexGrid.lineCount - 1, this.hexGrid.rowCount);
            this.scroll.ignoreScroll = false;

            this.hexGrid.setOffset(this.hexGrid.offset);

            this.hexGrid.element.parent.style.width = "${this.scroll.element.offset.right}px";
        };

        this.onDataModified.add(updateScroll);
        this.onResize.add(updateScroll);
    }

    /**
     * Load a new buffer.
     */
    void newBuffer([Uint8List buffer]) {
        this.data.reset(this, buffer);
    }

    /**
     * Prompt the user to select a file to open, if [buffer] is null. Otherwise, load [buffer].
     */
    void openFile([Uint8List buffer]) {

        if (buffer == null) {

            FileIO.init(document.querySelector("#openDialog"), document.querySelector("#openDialog #openLocations"));
            FileIO.open().then((FileInfo fi) {
                File file = fi.file;
                FileReader reader = new FileReader();

                this.showProgress("Loading file...");
                reader.onProgress.listen((ProgressEvent e) {
                    this.progressDialog.progress.value = e.loaded / e.total;
                });

                reader.onLoad.listen((ProgressEvent e) {
                    this.progressDialog.progress.value = 1.0;
                    new Timer(new Duration(milliseconds: 200), () {
                        this.openFile(new Uint8List.fromList(reader.result));
                        this.progressDialog.dismiss();
                    });
                });

                reader.readAsArrayBuffer(file);

            });

            return;
        }

        this.newBuffer(buffer);
    }

    ProgressDialog progressDialog = null;

    ProgressDialog showProgress(String text, [DivElement progressDialogElement = null]) {
        if (this.progressDialog == null) {
            if (progressDialogElement == null) {
                progressDialogElement = document.querySelector("#progressDialog");
            }

            this.progressDialog = new ProgressDialog(progressDialogElement);
        }

        this.progressDialog.canDismiss = false;

        this.progressDialog.show().then((String s) {
            this.progressDialog = null;
        });

        return this.progressDialog;
    }

    void newFile() {

        Dialog.confirm("Create a new one?").then((bool reply) {
            if (reply) {
                this.newBuffer();
            }
        });
    }
}

class HexEditEvent extends EventSource<HexEdit> {
    HexEditEvent();
}
