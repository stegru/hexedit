part of hexedit;

/** Callback when an event it raised. */
typedef bool EventHandler<TEventArgs>(TEventArgs e);

/** Callback when an event it raised. */
typedef bool EventListener<TEventArgs>(TEventArgs e);


/** Lightweight event handling. Events are like  chained callbacks. */
class EventSource<TEventArgs> {
    /** The call-backs that handle this event */
    List<EventHandler<TEventArgs>> _handlers = new List<EventHandler<TEventArgs>>();

    /** The handlers to remove (if a removal was made during a raise) */
    List<EventHandler<TEventArgs>> _removeLater = new List<EventHandler<TEventArgs>>();

    /** is the event currently being raised? */
    bool _raising = false;

    /** Add an event handler. */
    void add(EventHandler<TEventArgs> handler, {bool insert: false}) {
        if (insert) {
            this._handlers.insert(0, handler);
        } else {
            this._handlers.add(handler);
        }
    }

    /**
     * Raise the event. Calls each handler, last added first.
     * Returns true if any of the handlers return true. If [cancelable] is true, then a handler returning true will prevent
     * the other handlers from being called.
     */
    bool raise(TEventArgs e, [bool cancalable = false]) {
        this._raising = true;

        try {
            bool ret = false;
            if (cancalable) {
                for (EventHandler<TEventArgs> handler in this._handlers) {
                    if (handler(e)) {
                        return true;
                    }
                }
            } else {
                this._handlers.forEach((handler) => ret = handler(e) || ret);
            }

            return ret;
        }
        finally {
            this._raising = false;
            if (this._removeLater.isNotEmpty) {
                this._removeLater.forEach((handler) => this.remove(handler));
                this._removeLater.clear();
            }
        }
    }

    /** Remove the handler. */
    void remove(EventHandler<TEventArgs> handler) {
        if (this._raising) {
            // remove it when the forEach iteration is complete
            this._removeLater.add(handler);
        } else {
            this._handlers.remove(handler);
        }
    }
}

