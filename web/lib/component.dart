part of hexedit;

/** Wrapper for an element */
abstract class Component<TElem extends Element> {
    TElem element;

    bool get hasFocus => document.activeElement == this.element;

    Component() {
    }

    /**
     * Create the element.
     */
    void create() {
        this.addEventHandlers();
    }

    /** Remove the element. */
    void destroy() {
        this.element.remove();
    }

    /** Add the event handlers. */
    void addEventHandlers() {
    }

    Element $(String selectors) {
        return this.element.querySelector(selectors);
    }

    ElementList $$(String selectors) {
        return this.element.querySelectorAll(selectors);
    }

    StreamSubscription<MouseEvent> _windowMouseMoveSubscription = null;
    StreamSubscription<MouseEvent> _windowMouseUpSubscription = null;
    bool _mousemoved = false;

    /// Receive mouse events, even when the mouse is out of the browser.
    void captureMouse(void onMouseMove(MouseEvent event), void onMouseUp(MouseEvent event)) {
        this.releaseMouse();

        this._windowMouseMoveSubscription = window.onMouseMove.listen((e) {
            if (this._mousemoved) {
                new Timer(const Duration(seconds: 0), () {
                    onMouseMove(e);
                });
            } else {
                // ignore the first move
                this._mousemoved = true;
            }
        });
        this._windowMouseUpSubscription = window.onMouseUp.listen((e) {
            onMouseUp(e);
            this.releaseMouse();
        });
    }

    /// Stop receiving mouse events caused by a call to [captureMouse()]
    void releaseMouse() {
        this._mousemoved = false;
        if (this._windowMouseMoveSubscription != null) {
            this._windowMouseMoveSubscription.cancel();
            this._windowMouseMoveSubscription = null;
        }
        if (this._windowMouseUpSubscription != null) {
            this._windowMouseUpSubscription.cancel();
            this._windowMouseUpSubscription = null;
        }
    }
}

