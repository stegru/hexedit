part of hexedit.panels;


/**
 * Displays textual data based on the selection of the grid.
 */
class CharacterPanel extends InspectorPanel {
    CharacterPanel(String selector) : super(selector);

    static const int _PIXEL_SIZEY = 3;
    static const int _PIXEL_SIZEX = _PIXEL_SIZEY ;

    TableCellElement display = new TableCellElement();
    TableCellElement info = new TableCellElement();
    CanvasElement charCanvas = new CanvasElement(width: _PIXEL_SIZEX * 8, height: _PIXEL_SIZEY * 16);


    void create() {
        super.create();


        TableElement table = new TableElement();
        TableRowElement row = table.addRow();

        this.display = row.addCell();
        this.info = row.addCell();

        this.display.id = "characterDisplay";
        this.info.id = "characterInfo";

        this.charCanvas.style
            ..width = "${_PIXEL_SIZEX * 8}px"
            ..height = "${_PIXEL_SIZEY * 16}px";

        this.display.append(this.charCanvas);


        this.element.append(table);


        this.hexEdit.onSelectionChanged.add((Selection selection) {
            this.update();
            return true;
        });
        this.hexEdit.onDataModified.add((Range range) {
            this.update();
            return true;
        });
    }

    void clear() {

    }

    void update() {

        super.update();

        if (this.selection.length == 0) {
            this.clear();
            return;
        }

        int byte = this.selection.first;

        //String char = new String.fromCharCode(byte);
        //this.display.text = char;
        this.drawChar(byte);

        List<String> names = this.getAsciiNames(byte);

        StringBuffer html = new StringBuffer();

        if (names.length > 0) {
            html
                ..write("<span class='name'>")
                ..write(names.first)
                ..write("<span class='slang'>")
                ..write(names.skip(1).join(", "))
                ..write("</span>")
                ..write("</span>");
        }

        ;

        this.info.innerHtml = html.toString();
    }

    void drawChar(int char) {
        CanvasRenderingContext2D context = this.charCanvas.context2D;

        context.clearRect(0, 0, 8 * _PIXEL_SIZEX, 16 * _PIXEL_SIZEY);

        context.fillStyle = this.charCanvas.getComputedStyle().color;


        int fontOffset = char * 4;

        int x = 0, y = -1;
        int b = 0, f = 0;

        for (int p = 0; p < 8 * 16; p++) {
            b = p % 32;
            if ((b % 8) == 0) {
                // new row
                y++;
                x = 0;
                if (p % 32 == 0) {
                    f = _font[fontOffset++];
                }
            }

            bool on = f & (1 << (31 - b)) != 0;

            if (on)context.fillRect(x * _PIXEL_SIZEX, y * _PIXEL_SIZEY, _PIXEL_SIZEX, _PIXEL_SIZEY);

            x++;
        }
    }

    List<String> getAsciiNames(int code) {
        if (code < 0 || code >= _ascii.length) {
            return [];
        }

        return _ascii[code].split(", ");
    }

    /*
     * Ordered list of ascii character names.
     * Taken from the ascii utility: http://www.catb.org/~esr/ascii/
     * License: BSD
     */
    static List<String> _ascii = [
            "NUL, Null, \\0",
            "SOH, Start Of Header",
            "STX, Start of Text",
            "ETX, End of Text",
            "EOT, End Of Transmission",
            "ENQ, Enquiry",
            "ACK, Acknowledge",
            "BEL, Bell, \\a, Alert",
            "BS, Backspace, \\b",
            "HT, TAB, Character Tabulation, Horizontal Tab, \\t",
            "LF, NL, Line Feed, Newline, \\n",
            "VT, Line Tabulation, Vertical Tab, \\v",
            "FF, Form Feed, \\f",
            "CR, Carriage Return, \\r",
            "SO, LS1, Shift Out, Locking Shift 1",
            "SI, LS0, Shift In, Locking Shift 0",
            "DLE, Data Link Escape",
            "DC1, Device Control 1",
            "DC2, Device Control 2",
            "DC3, Device Control 3",
            "DC4, Device Control 4",
            "NAK, Negative Acknowledge",
            "SYN, Synchronous Idle",
            "ETB, End of Transmission Block",
            "CAN, Cancel",
            "EM, End of Medium",
            "SUB, Substitute",
            "ESC, Escape",
            "FS, File Separator",
            "GS, Group Separator",
            "RS, Record Separator",
            "US, Unit Separator",
            "Space, Blank",
            "Exclamation Mark, Bang, Excl, Wow, Factorial, Shriek, Pling, Smash, Cuss",
            "Quotation Mark, Double Quote, Quote, String Quote, Dirk, Literal Mark, Double Glitch, &quot;",
            "Number Sign, Pound, Number, Sharp, Crunch, Mesh, Hex, Hash, Flash, Grid, Octothorpe",
            "Currency Sign, Dollar, Buck, Cash, Ding",
            "Percent Sign, Mod, Modulo",
            "Ampersand, Amper, And, &amp;",
            "Apostrophe, Single Quote, Close Quote, Prime, Tick, Pop, Spark, Glitch, &apos;",
            "Left Parenthesis, Open, Open Paren, Left Paren, Wax, Sad",
            "Right Parenthesis, Close, Close Paren, Right Paren, Wane, Happy",
            "Asterisk, Star, Splat, Aster, Times, Gear, Dingle, Bug, Twinkle, Glob",
            "Plus Sign, Add, Cross",
            "Comma, Tail",
            "Hyphen, Dash, Minus, Worm",
            "Full Stop, Dot, Decimal Point, Radix Point, Point, Period, Spot",
            "Solidus, Slash, Stroke, Slant, Diagonal, Virgule, Over, Slat",
            "Digit Zero",
            "Digit One",
            "Digit Two",
            "Digit Three",
            "Digit Four",
            "Digit Five",
            "Digit Six",
            "Digit Seven",
            "Digit Eight",
            "Digit Nine",
            "Colon, Double-Dot",
            "Semicolon, Semi, Go-on",
            "Less-than Sign, Left Angle Bracket, Read From, In, From, Comesfrom, Left Funnel, Left Broket, Crunch, Suck, &lt;",
            "Equals Sign, Quadrathorp, Gets, Becomes, Half-Mesh",
            "Greater-than sign, Right Angle Bracket, Write To, Into, Toward, Out, To, Gozinta, Right Funnel, Right Broket, Zap, Blow, &gt;",
            "Question Mark",
            "Commercial At, At, Each, Vortex, Whorl, Whirlpool, Cyclone, Snail, Rose",
            "Majuscule A, Capital A, Uppercase A",
            "Majuscule B, Capital B, Uppercase B",
            "Majuscule C, Capital C, Uppercase C",
            "Majuscule D, Capital D, Uppercase D",
            "Majuscule E, Capital E, Uppercase E",
            "Majuscule F, Capital F, Uppercase F",
            "Majuscule G, Capital G, Uppercase G",
            "Majuscule H, Capital H, Uppercase H",
            "Majuscule I, Capital I, Uppercase I",
            "Majuscule J, Capital J, Uppercase J",
            "Majuscule K, Capital K, Uppercase K",
            "Majuscule L, Capital L, Uppercase L",
            "Majuscule M, Capital M, Uppercase M",
            "Majuscule N, Capital N, Uppercase N",
            "Majuscule O, Capital O, Uppercase O",
            "Majuscule P, Capital P, Uppercase P",
            "Majuscule Q, Capital Q, Uppercase Q",
            "Majuscule R, Capital R, Uppercase R",
            "Majuscule S, Capital S, Uppercase S",
            "Majuscule T, Capital T, Uppercase T",
            "Majuscule U, Capital U, Uppercase U",
            "Majuscule V, Capital V, Uppercase V",
            "Majuscule W, Capital W, Uppercase W",
            "Majuscule X, Capital X, Uppercase X",
            "Majuscule Y, Capital Y, Uppercase Y",
            "Majuscule Z, Capital Z, Uppercase Z",
            "Left Square Bracket, Bracket, Bra, Square",
            "Reversed Solidus, Backslash, Bash, Backslant, Backwhack, Backslat, Literal, Escape",
            "Right Square Bracket, Unbracket, Ket, Unsquare",
            "Circumflex Accent, Circumflex, Caret, Uparrow, Hat, Control, Boink, Chevron, Hiccup, Sharkfin, Fang",
            "Low Line, Underscore, Underline, Underbar, Under, Score, Backarrow, Flatworm",
            "Grave Accent, Grave, Backquote, Left Quote, Open Quote, Backprime, Unapostrophe, Backspark, Birk, Blugle, Back Tick, Push",
            "Miniscule a, Small a, Lowercase a",
            "Miniscule b, Small b, Lowercase b",
            "Miniscule c, Small c, Lowercase c",
            "Miniscule d, Small d, Lowercase d",
            "Miniscule e, Small e, Lowercase e",
            "Miniscule f, Small f, Lowercase f",
            "Miniscule g, Small g, Lowercase g",
            "Miniscule h, Small h, Lowercase h",
            "Miniscule i, Small i, Lowercase i",
            "Miniscule j, Small j, Lowercase j",
            "Miniscule k, Small k, Lowercase k",
            "Miniscule l, Small l, Lowercase l",
            "Miniscule m, Small m, Lowercase m",
            "Miniscule n, Small n, Lowercase n",
            "Miniscule o, Small o, Lowercase o",
            "Miniscule p, Small p, Lowercase p",
            "Miniscule q, Small q, Lowercase q",
            "Miniscule r, Small r, Lowercase r",
            "Miniscule s, Small s, Lowercase s",
            "Miniscule t, Small t, Lowercase t",
            "Miniscule u, Small u, Lowercase u",
            "Miniscule v, Small v, Lowercase v",
            "Miniscule w, Small w, Lowercase w",
            "Miniscule x, Small x, Lowercase x",
            "Miniscule y, Small y, Lowercase y",
            "Miniscule z, Small z, Lowercase z",
            "Left Curly Bracket, Left Brace, Brace, Open Brace, Curly, Leftit, Embrace",
            "Vertical Line, Pipe, Bar, Or, V-Bar, Spike, Gozinta, Thru",
            "Right Curly Bracket, Right Brace, Unbrace, Close Brace, Uncurly, Rytit, Bracelet",
            "Overline, Tilde, Swung Dash, Squiggle, Approx, Wiggle, Twiddle, Enyay",
            "DEL, Delete",
    ];

    static List<int> _font = [
            0x00000000, 0x00000000, 0x00000000, 0x00000000,
            0x00007e81, 0xa58181bd, 0x9981817e, 0x00000000,
            0x00007eff, 0xdbffffc3, 0xe7ffff7e, 0x00000000,
            0x00000000, 0x6cfefefe, 0xfe7c3810, 0x00000000,
            0x00000000, 0x10387cfe, 0x7c381000, 0x00000000,
            0x00000018, 0x3c3ce7e7, 0xe718183c, 0x00000000,
            0x00000018, 0x3c7effff, 0x7e18183c, 0x00000000,
            0x00000000, 0x0000183c, 0x3c180000, 0x00000000,
            0xffffffff, 0xffffe7c3, 0xc3e7ffff, 0xffffffff,
            0x00000000, 0x003c6642, 0x42663c00, 0x00000000,
            0xffffffff, 0xffc399bd, 0xbd99c3ff, 0xffffffff,
            0x00001e0e, 0x1a3278cc, 0xcccccc78, 0x00000000,
            0x00003c66, 0x6666663c, 0x187e1818, 0x00000000,
            0x00003f33, 0x3f303030, 0x3070f0e0, 0x00000000,
            0x00007f63, 0x7f636363, 0x6367e7e6, 0xc0000000,
            0x00000018, 0x18db3ce7, 0x3cdb1818, 0x00000000,
            0x0080c0e0, 0xf0f8fef8, 0xf0e0c080, 0x00000000,
            0x0002060e, 0x1e3efe3e, 0x1e0e0602, 0x00000000,
            0x0000183c, 0x7e181818, 0x7e3c1800, 0x00000000,
            0x00006666, 0x66666666, 0x66006666, 0x00000000,
            0x00007fdb, 0xdbdb7b1b, 0x1b1b1b1b, 0x00000000,
            0x007cc660, 0x386cc6c6, 0x6c380cc6, 0x7c000000,
            0x00000000, 0x00000000, 0xfefefefe, 0x00000000,
            0x0000183c, 0x7e181818, 0x7e3c187e, 0x00000000,
            0x0000183c, 0x7e181818, 0x18181818, 0x00000000,
            0x00001818, 0x18181818, 0x187e3c18, 0x00000000,
            0x00000000, 0x00180cfe, 0x0c180000, 0x00000000,
            0x00000000, 0x003060fe, 0x60300000, 0x00000000,
            0x00000000, 0x0000c0c0, 0xc0fe0000, 0x00000000,
            0x00000000, 0x00286cfe, 0x6c280000, 0x00000000,
            0x00000000, 0x1038387c, 0x7cfefe00, 0x00000000,
            0x00000000, 0xfefe7c7c, 0x38381000, 0x00000000,
            0x00000000, 0x00000000, 0x00000000, 0x00000000,
            0x0000183c, 0x3c3c1818, 0x18001818, 0x00000000,
            0x00666666, 0x24000000, 0x00000000, 0x00000000,
            0x0000006c, 0x6cfe6c6c, 0x6cfe6c6c, 0x00000000,
            0x18187cc6, 0xc2c07c06, 0x0686c67c, 0x18180000,
            0x00000000, 0xc2c60c18, 0x3060c686, 0x00000000,
            0x0000386c, 0x6c3876dc, 0xcccccc76, 0x00000000,
            0x00303030, 0x60000000, 0x00000000, 0x00000000,
            0x00000c18, 0x30303030, 0x3030180c, 0x00000000,
            0x00003018, 0x0c0c0c0c, 0x0c0c1830, 0x00000000,
            0x00000000, 0x00663cff, 0x3c660000, 0x00000000,
            0x00000000, 0x0018187e, 0x18180000, 0x00000000,
            0x00000000, 0x00000000, 0x00181818, 0x30000000,
            0x00000000, 0x0000007e, 0x00000000, 0x00000000,
            0x00000000, 0x00000000, 0x00001818, 0x00000000,
            0x00000000, 0x02060c18, 0x3060c080, 0x00000000,
            0x00007cc6, 0xc6cedef6, 0xe6c6c67c, 0x00000000,
            0x00001838, 0x78181818, 0x1818187e, 0x00000000,
            0x00007cc6, 0x060c1830, 0x60c0c6fe, 0x00000000,
            0x00007cc6, 0x06063c06, 0x0606c67c, 0x00000000,
            0x00000c1c, 0x3c6cccfe, 0x0c0c0c1e, 0x00000000,
            0x0000fec0, 0xc0c0fc06, 0x0606c67c, 0x00000000,
            0x00003860, 0xc0c0fcc6, 0xc6c6c67c, 0x00000000,
            0x0000fec6, 0x06060c18, 0x30303030, 0x00000000,
            0x00007cc6, 0xc6c67cc6, 0xc6c6c67c, 0x00000000,
            0x00007cc6, 0xc6c67e06, 0x06060c78, 0x00000000,
            0x00000000, 0x18180000, 0x00181800, 0x00000000,
            0x00000000, 0x18180000, 0x00181830, 0x00000000,
            0x00000006, 0x0c183060, 0x30180c06, 0x00000000,
            0x00000000, 0x007e0000, 0x7e000000, 0x00000000,
            0x00000060, 0x30180c06, 0x0c183060, 0x00000000,
            0x00007cc6, 0xc60c1818, 0x18001818, 0x00000000,
            0x00007cc6, 0xc6c6dede, 0xdedcc07c, 0x00000000,
            0x00001038, 0x6cc6c6fe, 0xc6c6c6c6, 0x00000000,
            0x0000fc66, 0x66667c66, 0x666666fc, 0x00000000,
            0x00003c66, 0xc2c0c0c0, 0xc0c2663c, 0x00000000,
            0x0000f86c, 0x66666666, 0x66666cf8, 0x00000000,
            0x0000fe66, 0x62687868, 0x606266fe, 0x00000000,
            0x0000fe66, 0x62687868, 0x606060f0, 0x00000000,
            0x00003c66, 0xc2c0c0de, 0xc6c6663a, 0x00000000,
            0x0000c6c6, 0xc6c6fec6, 0xc6c6c6c6, 0x00000000,
            0x00003c18, 0x18181818, 0x1818183c, 0x00000000,
            0x00001e0c, 0x0c0c0c0c, 0xcccccc78, 0x00000000,
            0x0000e666, 0x666c7878, 0x6c6666e6, 0x00000000,
            0x0000f060, 0x60606060, 0x606266fe, 0x00000000,
            0x0000c6ee, 0xfefed6c6, 0xc6c6c6c6, 0x00000000,
            0x0000c6e6, 0xf6fedece, 0xc6c6c6c6, 0x00000000,
            0x00007cc6, 0xc6c6c6c6, 0xc6c6c67c, 0x00000000,
            0x0000fc66, 0x66667c60, 0x606060f0, 0x00000000,
            0x00007cc6, 0xc6c6c6c6, 0xc6d6de7c, 0x0c0e0000,
            0x0000fc66, 0x66667c6c, 0x666666e6, 0x00000000,
            0x00007cc6, 0xc660380c, 0x06c6c67c, 0x00000000,
            0x00007e7e, 0x5a181818, 0x1818183c, 0x00000000,
            0x0000c6c6, 0xc6c6c6c6, 0xc6c6c67c, 0x00000000,
            0x0000c6c6, 0xc6c6c6c6, 0xc66c3810, 0x00000000,
            0x0000c6c6, 0xc6c6d6d6, 0xd6feee6c, 0x00000000,
            0x0000c6c6, 0x6c7c3838, 0x7c6cc6c6, 0x00000000,
            0x00006666, 0x66663c18, 0x1818183c, 0x00000000,
            0x0000fec6, 0x860c1830, 0x60c2c6fe, 0x00000000,
            0x00003c30, 0x30303030, 0x3030303c, 0x00000000,
            0x00000080, 0xc0e07038, 0x1c0e0602, 0x00000000,
            0x00003c0c, 0x0c0c0c0c, 0x0c0c0c3c, 0x00000000,
            0x10386cc6, 0x00000000, 0x00000000, 0x00000000,
            0x00000000, 0x00000000, 0x00000000, 0x00ff0000,
            0x30301800, 0x00000000, 0x00000000, 0x00000000,
            0x00000000, 0x00780c7c, 0xcccccc76, 0x00000000,
            0x0000e060, 0x60786c66, 0x6666667c, 0x00000000,
            0x00000000, 0x007cc6c0, 0xc0c0c67c, 0x00000000,
            0x00001c0c, 0x0c3c6ccc, 0xcccccc76, 0x00000000,
            0x00000000, 0x007cc6fe, 0xc0c0c67c, 0x00000000,
            0x0000386c, 0x6460f060, 0x606060f0, 0x00000000,
            0x00000000, 0x0076cccc, 0xcccccc7c, 0x0ccc7800,
            0x0000e060, 0x606c7666, 0x666666e6, 0x00000000,
            0x00001818, 0x00381818, 0x1818183c, 0x00000000,
            0x00000606, 0x000e0606, 0x06060606, 0x66663c00,
            0x0000e060, 0x60666c78, 0x786c66e6, 0x00000000,
            0x00003818, 0x18181818, 0x1818183c, 0x00000000,
            0x00000000, 0x00ecfed6, 0xd6d6d6c6, 0x00000000,
            0x00000000, 0x00dc6666, 0x66666666, 0x00000000,
            0x00000000, 0x007cc6c6, 0xc6c6c67c, 0x00000000,
            0x00000000, 0x00dc6666, 0x6666667c, 0x6060f000,
            0x00000000, 0x0076cccc, 0xcccccc7c, 0x0c0c1e00,
            0x00000000, 0x00dc7666, 0x606060f0, 0x00000000,
            0x00000000, 0x007cc660, 0x380cc67c, 0x00000000,
            0x00001030, 0x30fc3030, 0x3030361c, 0x00000000,
            0x00000000, 0x00cccccc, 0xcccccc76, 0x00000000,
            0x00000000, 0x00666666, 0x66663c18, 0x00000000,
            0x00000000, 0x00c6c6d6, 0xd6d6fe6c, 0x00000000,
            0x00000000, 0x00c66c38, 0x38386cc6, 0x00000000,
            0x00000000, 0x00c6c6c6, 0xc6c6c67e, 0x060cf800,
            0x00000000, 0x00fecc18, 0x3060c6fe, 0x00000000,
            0x00000e18, 0x18187018, 0x1818180e, 0x00000000,
            0x00001818, 0x18180018, 0x18181818, 0x00000000,
            0x00007018, 0x18180e18, 0x18181870, 0x00000000,
            0x000076dc, 0x00000000, 0x00000000, 0x00000000,
            0x00000000, 0x10386cc6, 0xc6c6fe00, 0x00000000,
            0x00003c66, 0xc2c0c0c0, 0xc2663c0c, 0x067c0000,
            0x0000cc00, 0x00cccccc, 0xcccccc76, 0x00000000,
            0x000c1830, 0x007cc6fe, 0xc0c0c67c, 0x00000000,
            0x0010386c, 0x00780c7c, 0xcccccc76, 0x00000000,
            0x0000cc00, 0x00780c7c, 0xcccccc76, 0x00000000,
            0x00603018, 0x00780c7c, 0xcccccc76, 0x00000000,
            0x00386c38, 0x00780c7c, 0xcccccc76, 0x00000000,
            0x00000000, 0x3c666060, 0x663c0c06, 0x3c000000,
            0x0010386c, 0x007cc6fe, 0xc0c0c67c, 0x00000000,
            0x0000c600, 0x007cc6fe, 0xc0c0c67c, 0x00000000,
            0x00603018, 0x007cc6fe, 0xc0c0c67c, 0x00000000,
            0x00006600, 0x00381818, 0x1818183c, 0x00000000,
            0x00183c66, 0x00381818, 0x1818183c, 0x00000000,
            0x00603018, 0x00381818, 0x1818183c, 0x00000000,
            0x00c60010, 0x386cc6c6, 0xfec6c6c6, 0x00000000,
            0x386c3800, 0x386cc6c6, 0xfec6c6c6, 0x00000000,
            0x18306000, 0xfe66607c, 0x606066fe, 0x00000000,
            0x00000000, 0x6cfeb232, 0x7ed8d86e, 0x00000000,
            0x00003e6c, 0xccccfecc, 0xccccccce, 0x00000000,
            0x0010386c, 0x007cc6c6, 0xc6c6c67c, 0x00000000,
            0x0000c600, 0x007cc6c6, 0xc6c6c67c, 0x00000000,
            0x00603018, 0x007cc6c6, 0xc6c6c67c, 0x00000000,
            0x003078cc, 0x00cccccc, 0xcccccc76, 0x00000000,
            0x00603018, 0x00cccccc, 0xcccccc76, 0x00000000,
            0x0000c600, 0x00c6c6c6, 0xc6c6c67e, 0x060c7800,
            0x00c6007c, 0xc6c6c6c6, 0xc6c6c67c, 0x00000000,
            0x00c600c6, 0xc6c6c6c6, 0xc6c6c67c, 0x00000000,
            0x0018183c, 0x66606060, 0x663c1818, 0x00000000,
            0x00386c64, 0x60f06060, 0x6060e6fc, 0x00000000,
            0x00006666, 0x3c187e18, 0x7e181818, 0x00000000,
            0x00f8cccc, 0xf8c4ccde, 0xccccccc6, 0x00000000,
            0x000e1b18, 0x18187e18, 0x18181818, 0xd8700000,
            0x00183060, 0x00780c7c, 0xcccccc76, 0x00000000,
            0x000c1830, 0x00381818, 0x1818183c, 0x00000000,
            0x00183060, 0x007cc6c6, 0xc6c6c67c, 0x00000000,
            0x00183060, 0x00cccccc, 0xcccccc76, 0x00000000,
            0x000076dc, 0x00dc6666, 0x66666666, 0x00000000,
            0x76dc00c6, 0xe6f6fede, 0xcec6c6c6, 0x00000000,
            0x003c6c6c, 0x3e007e00, 0x00000000, 0x00000000,
            0x00386c6c, 0x38007c00, 0x00000000, 0x00000000,
            0x00003030, 0x00303060, 0xc0c6c67c, 0x00000000,
            0x00000000, 0x0000fec0, 0xc0c0c000, 0x00000000,
            0x00000000, 0x0000fe06, 0x06060600, 0x00000000,
            0x00c0c0c2, 0xc6cc1830, 0x60dc860c, 0x183e0000,
            0x00c0c0c2, 0xc6cc1830, 0x66ce9e3e, 0x06060000,
            0x00001818, 0x00181818, 0x3c3c3c18, 0x00000000,
            0x00000000, 0x00366cd8, 0x6c360000, 0x00000000,
            0x00000000, 0x00d86c36, 0x6cd80000, 0x00000000,
            0x11441144, 0x11441144, 0x11441144, 0x11441144,
            0x55aa55aa, 0x55aa55aa, 0x55aa55aa, 0x55aa55aa,
            0xdd77dd77, 0xdd77dd77, 0xdd77dd77, 0xdd77dd77,
            0x18181818, 0x18181818, 0x18181818, 0x18181818,
            0x18181818, 0x181818f8, 0x18181818, 0x18181818,
            0x18181818, 0x18f818f8, 0x18181818, 0x18181818,
            0x36363636, 0x363636f6, 0x36363636, 0x36363636,
            0x00000000, 0x000000fe, 0x36363636, 0x36363636,
            0x00000000, 0x00f818f8, 0x18181818, 0x18181818,
            0x36363636, 0x36f606f6, 0x36363636, 0x36363636,
            0x36363636, 0x36363636, 0x36363636, 0x36363636,
            0x00000000, 0x00fe06f6, 0x36363636, 0x36363636,
            0x36363636, 0x36f606fe, 0x00000000, 0x00000000,
            0x36363636, 0x363636fe, 0x00000000, 0x00000000,
            0x18181818, 0x18f818f8, 0x00000000, 0x00000000,
            0x00000000, 0x000000f8, 0x18181818, 0x18181818,
            0x18181818, 0x1818181f, 0x00000000, 0x00000000,
            0x18181818, 0x181818ff, 0x00000000, 0x00000000,
            0x00000000, 0x000000ff, 0x18181818, 0x18181818,
            0x18181818, 0x1818181f, 0x18181818, 0x18181818,
            0x00000000, 0x000000ff, 0x00000000, 0x00000000,
            0x18181818, 0x181818ff, 0x18181818, 0x18181818,
            0x18181818, 0x181f181f, 0x18181818, 0x18181818,
            0x36363636, 0x36363637, 0x36363636, 0x36363636,
            0x36363636, 0x3637303f, 0x00000000, 0x00000000,
            0x00000000, 0x003f3037, 0x36363636, 0x36363636,
            0x36363636, 0x36f700ff, 0x00000000, 0x00000000,
            0x00000000, 0x00ff00f7, 0x36363636, 0x36363636,
            0x36363636, 0x36373037, 0x36363636, 0x36363636,
            0x00000000, 0x00ff00ff, 0x00000000, 0x00000000,
            0x36363636, 0x36f700f7, 0x36363636, 0x36363636,
            0x18181818, 0x18ff00ff, 0x00000000, 0x00000000,
            0x36363636, 0x363636ff, 0x00000000, 0x00000000,
            0x00000000, 0x00ff00ff, 0x18181818, 0x18181818,
            0x00000000, 0x000000ff, 0x36363636, 0x36363636,
            0x36363636, 0x3636363f, 0x00000000, 0x00000000,
            0x18181818, 0x181f181f, 0x00000000, 0x00000000,
            0x00000000, 0x001f181f, 0x18181818, 0x18181818,
            0x00000000, 0x0000003f, 0x36363636, 0x36363636,
            0x36363636, 0x363636ff, 0x36363636, 0x36363636,
            0x18181818, 0x18ff18ff, 0x18181818, 0x18181818,
            0x18181818, 0x181818f8, 0x00000000, 0x00000000,
            0x00000000, 0x0000001f, 0x18181818, 0x18181818,
            0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
            0x00000000, 0x000000ff, 0xffffffff, 0xffffffff,
            0xf0f0f0f0, 0xf0f0f0f0, 0xf0f0f0f0, 0xf0f0f0f0,
            0x0f0f0f0f, 0x0f0f0f0f, 0x0f0f0f0f, 0x0f0f0f0f,
            0xffffffff, 0xffffff00, 0x00000000, 0x00000000,
            0x00000000, 0x0076dcd8, 0xd8d8dc76, 0x00000000,
            0x000078cc, 0xccccd8cc, 0xc6c6c6cc, 0x00000000,
            0x0000fec6, 0xc6c0c0c0, 0xc0c0c0c0, 0x00000000,
            0x00000000, 0xfe6c6c6c, 0x6c6c6c6c, 0x00000000,
            0x000000fe, 0xc6603018, 0x3060c6fe, 0x00000000,
            0x00000000, 0x007ed8d8, 0xd8d8d870, 0x00000000,
            0x00000000, 0x66666666, 0x667c6060, 0xc0000000,
            0x00000000, 0x76dc1818, 0x18181818, 0x00000000,
            0x0000007e, 0x183c6666, 0x663c187e, 0x00000000,
            0x00000038, 0x6cc6c6fe, 0xc6c66c38, 0x00000000,
            0x0000386c, 0xc6c6c66c, 0x6c6c6cee, 0x00000000,
            0x00001e30, 0x180c3e66, 0x6666663c, 0x00000000,
            0x00000000, 0x007edbdb, 0xdb7e0000, 0x00000000,
            0x00000003, 0x067edbdb, 0xf37e60c0, 0x00000000,
            0x00001c30, 0x60607c60, 0x6060301c, 0x00000000,
            0x0000007c, 0xc6c6c6c6, 0xc6c6c6c6, 0x00000000,
            0x00000000, 0xfe0000fe, 0x0000fe00, 0x00000000,
            0x00000000, 0x18187e18, 0x180000ff, 0x00000000,
            0x00000030, 0x180c060c, 0x1830007e, 0x00000000,
            0x0000000c, 0x18306030, 0x180c007e, 0x00000000,
            0x00000e1b, 0x1b1b1818, 0x18181818, 0x18181818,
            0x18181818, 0x18181818, 0xd8d8d870, 0x00000000,
            0x00000000, 0x1818007e, 0x00181800, 0x00000000,
            0x00000000, 0x0076dc00, 0x76dc0000, 0x00000000,
            0x00386c6c, 0x38000000, 0x00000000, 0x00000000,
            0x00000000, 0x00000018, 0x18000000, 0x00000000,
            0x00000000, 0x00000000, 0x18000000, 0x00000000,
            0x000f0c0c, 0x0c0c0cec, 0x6c6c3c1c, 0x00000000,
            0x00d86c6c, 0x6c6c6c00, 0x00000000, 0x00000000,
            0x0070d830, 0x60c8f800, 0x00000000, 0x00000000,
            0x00000000, 0x7c7c7c7c, 0x7c7c7c00, 0x00000000,
            0x00000000, 0x00000000, 0x00000000, 0x00000000,
    ];
}
