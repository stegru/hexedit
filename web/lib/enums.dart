part of hexedit;
// Enumerations

class Direction {
    static const LEFT = const Direction._(-1, 0, "left");
    static const RIGHT = const Direction._(1, 0, "right");
    static const UP = const Direction._(0, -1, "up");
    static const DOWN = const Direction._(0, 1, "down");

    static get values => [LEFT, RIGHT, UP, DOWN];

    final int x;
    final int y;
    final String text;

    /** Left or right. */
    bool get horizontal => this.y == 0;

    /** Up or down. */
    bool get vertical => !this.horizontal;

    /** Right or bottom. */
    bool get forward => this.x > 0 || this.y > 0;

    const Direction._(this.x, this.y, this.text);

    String toString() {
        return this.text;
    }
}

