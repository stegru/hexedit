library hexedit.panels;


import '../hexedit.dart';
import '../grid/grid.dart';

import "dart:html" hide Range, Selection, EventSource;
import 'dart:typed_data';
import 'dart:collection';
import 'dart:async';
import 'dart:isolate';

part 'datatype.dart';
part 'statusbar.dart';
part 'toolbar.dart';
part 'data-panel.dart';
part 'numeric-data.dart';
part 'text-data.dart';
part 'character.dart';
part 'bits.dart';
part 'goto.dart';
part 'search.dart';

abstract class Panel extends Component<DivElement> {

    static ToolBar toolBar = new ToolBar();
    static StatusBar statusBar = new StatusBar();
    static NumericDataPanel numericDataPanel = new NumericDataPanel("#numberInspector");
    static TextDataPanel textDataPanel = new TextDataPanel("#textDataPanel");
    static CharacterPanel characterPanel = new CharacterPanel("#characterPanel");
    static BitsPanel bitsPanel = new BitsPanel("#bitsPanel");
    static GotoPanel gotoPanel = new GotoPanel("#gotoPanel");
    static FindPanel findPanel = new FindPanel("#searchPanel");

    static List<Panel> _panels = [
            toolBar,
            statusBar,
            numericDataPanel,
            textDataPanel,
            characterPanel,
            bitsPanel,
            gotoPanel,
            findPanel,
    ];

    static List<Panel> get all => _panels;

    String selector;
    String title;
    HexEdit hexEdit;

    /// [true] if the panel is intended for below the grid
    bool isBottomPanel = false;

    HexGrid get grid => this.hexEdit.hexGrid;

    /// Raised when the panel is about to be expanded.
    EventSource<Panel> onExpand = new EventSource<Panel>();

    /// Raised when the panel is about to be collapsed.
    EventSource<Panel> onCollapse = new EventSource<Panel>();

    /// Raised when the panel is has been expanded or collapsed (and the animation is complete).
    EventSource<Panel> onToggle = new EventSource<Panel>();

    Panel(String this.selector) {
    }

    /**
     * Creates all the panels.
     */
    static void createAll(HexEdit hexEdit) {
        for (Panel panel in Panel._panels) {
            panel.hexEdit = hexEdit;
            panel.create();
        }
    }

    /// The panel's header.
    SpanElement headerElement;

    /// The close button for the panels below the grid.
    SpanElement closeButton;

    /// [true] if the panel is expanded, or [false] if collapsed.
    bool expanded = true;

    /// [true] if the panel is currently expanding or collapsing (the animation isn't complete).
    bool inExpandAnim = false;

    /// The full height of the panel when expanded.
    int expandedHeight = 0;

    void create() {
        this.element = document.querySelector(this.selector);

        if (this.element.dataset.containsKey("title")) {
            this.title = this.element.dataset["title"];
        }

        this.headerElement = new SpanElement();
        this.headerElement.classes.add("panel-header");
        SpanElement text = new SpanElement();
        text.text = this.title;
        this.headerElement.append(text);

        if (this.isBottomPanel) {
            this.closeButton = new SpanElement();
            this.closeButton.classes.add("close-button");
            this.headerElement.append(this.closeButton);

        }

        this.element.insertBefore(this.headerElement, this.element.firstChild);

        this.expand(this.expanded);
        super.create();
    }

    /**
     * Expands the panel if [newValue] is [true], collapses the panel if [false]. [null] will toggle.
     */
    bool expand([bool newValue = null]) {
        if (newValue == null) {
            newValue = !this.expanded;
        }

        if (this.expanded != newValue) {
            if (this.expanded) {
                if (this.onExpand.raise(this)) {
                    return this.expanded;
                }
            }
            else {
                if (this.onCollapse.raise(this)) {
                    return this.expanded;
                }
            }
        }

        bool wasExpanded = this.expanded;
        this.expanded = newValue;
        this.element.classes.add(this.expanded ? "expanded" : "collapsed");
        this.element.classes.remove(this.expanded ? "collapsed" : "expanded");

        if (!this.expanded) {
            if (wasExpanded || this.expandedHeight == 0) {
                this.expandedHeight = this.element.client.height;
            }
            this.element.style.height = "${this.expandedHeight}px";
            if (this.isBottomPanel) {
                // If "0px" is used, animation is not performed - even though this is the same string(??)
                this.element.style.height = "${this.headerElement.offset.height*0}px";
            } else {
                this.element.style.height = "${this.headerElement.offset.height}px";
            }
        } else if (!wasExpanded) {
            this.element.style.height = "${this.expandedHeight}px";
        }
        this.inExpandAnim = true;

        this.update();

        if (this.isBottomPanel) {
            if (!this.expanded) {
                // Draw the grid before it is revealed
                int height = this.grid.element.parent.clientHeight;
                height += this.element.offset.height;
                this.hexEdit.hexGrid.adjustSize(clientHeight: height, noEvent: true);
            }
        }

        return this.expanded;
    }

    void update();

    void submit() {

    }

    void addEventHandlers() {
        FormElement form = this.$('form');
        if (form != null) {
            form.onSubmit.listen((Event e) {
                e.preventDefault();
                this.submit();
            });
        }

        this.element.onTransitionEnd.listen((TransitionEvent e) {
            if (e.propertyName == "height") {
                if (this.expanded) {
                    this.element.style.height = "auto";
                }

                this.hexEdit.hexGrid.adjustSize();

                if (this.inExpandAnim) {
                    this.onToggle.raise(this);
                    this.inExpandAnim = false;
                }
            }
        });

        if (!this.isBottomPanel) {
            this.headerElement.onClick.listen((e) => this.expand(!this.expanded));
        } else {
            this.element.onKeyDown.listen((KeyboardEvent e) {
                if (e.keyCode == KeyCode.ESC) {
                    this.expand(false);
                    e.preventDefault();
                    e.stopPropagation();
                }
            });
            this.closeButton.onClick.listen((e) => this.expand(false));
        }
    }
}
