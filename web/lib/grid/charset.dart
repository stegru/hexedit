part of hexedit.grid;

class Charset {

    static List<Charset> _all = new List<Charset>();

    static List<int> _controlChars = [
            0x0000, 0x263A, 0x263B, 0x2665, 0x2666, 0x2663, 0x2660, 0x2022, 0x25D8, 0x25CB, 0x25D9, 0x2642, 0x2640,
            0x266A, 0x266B, 0x263C, 0x25BA, 0x25C4, 0x2195, 0x203C, 0x00B6, 0x00A7, 0x25AC, 0x21A8, 0x2191, 0x2193,
            0x2192, 0x2190, 0x221F, 0x2194, 0x25B2, 0x25BC,
    ];


    static bool _gotData = false;
    static Charset defaultCharset = null;

    final String id;
    final String name;
    final String region;

    bool isBuiltIn = false;

    String _data = null;
    List<int> charmap = new List<int>();
    String chars = "";

    bool loaded = false;

    Charset(String this.id, String this.region, String this.name) {

    }

    factory Charset.builtIn(String id, String region, String name)
    {
        Charset cs = new Charset(id, region, name);
        cs.isBuiltIn = true;
        cs._data = "c7,fc,e9,e2,e4,e0,e5,e7,ea,eb,e8,ef,ee,ec,c4,c5,c9,e6,c6,f4,f6,f2,fb,f9,ff,d6,dc,a2,a3,a5,20a7,192,e1,ed,f3,fa,f1,d1,aa,ba,bf,2310,ac,bd,bc,a1,ab,bb,2591,2592,2593,2502,2524,2561,2562,2556,2555,2563,2551,2557,255d,255c,255b,2510,2514,2534,252c,251c,2500,253c,255e,255f,255a,2554,2569,2566,2560,2550,256c,2567,2568,2564,2565,2559,2558,2552,2553,256b,256a,2518,250c,2588,2584,258c,2590,2580,3b1,df,393,3c0,3a3,3c3,b5,3c4,3a6,398,3a9,3b4,221e,3c6,3b5,2229,2261,b1,2265,2264,2320,2321,f7,2248,b0,2219,b7,221a,207f,b2,25a0,a0";


        return cs;
    }

    static void init(HexGrid grid) {

        String region;

        region = "Western European";
        _all.addAll([
                            new Charset.builtIn("cp437", region, "CP437 MS-DOS Latin US / OEM"),
                            new Charset("cp850", region, "CP850 MS-DOS Latin 1"),
                            new Charset("cp860", region, "CP860 MS-DOS Portuguese"),
                            new Charset("cp863", region, "CP863 MS-DOS French Canada"),
                            new Charset("cp1252", region, "CP1252 Windows Latin 1 (ANSI)"),
                            new Charset("cp10000", region, "CP10000 Macintosh Roman"),
                            new Charset("iso8859-1", region, "ISO 8859-1 Latin1 (West European)"),
                    ]);

        region = "Arabic";
        _all.addAll([
                            new Charset("cp1256", region, "CP1256 Windows Arabic"),
                            new Charset("iso8859-6", region, "ISO 8859-6 Arabic"),
                    ]);

        region = "Baltic";
        _all.addAll([
                            new Charset("cp775", region, "CP775 MS-DOS Baltic Rim"),
                            new Charset("cp1257", region, "CP1257 Windows Baltic Rim"),
                            new Charset("iso8859-4", region, "ISO 8859-4 Latin4 (North European)"),
                    ]);

        region = "Cyrillic";
        _all.addAll([
                            new Charset("cp855", region, "CP855 MS-DOS Cyrillic"),
                            new Charset("cp866", region, "CP866 MS-DOS Cyrillic CIS 1"),
                            new Charset("cp1251", region, "CP1251 Windows Cyrillic (Slavic)"),
                            new Charset("cp10007", region, "CP10007 Macintosh Cyrillic"),
                            new Charset("iso8859-5", region, "ISO 8859-5 Cyrillic"),
                    ]);

        region = "Central European";
        _all.addAll([
                            new Charset("cp852", region, "CP852 MS-DOS Latin 2"),
                            new Charset("cp1250", region, "CP1250 Windows Latin 2 (Central Europe)"),
                            new Charset("cp10029", region, "CP10029 Macintosh Central Europe"),
                    ]);

        region = "Eastern European";
        _all.addAll([
                            new Charset("iso8859-2", region, "ISO 8859-2 Latin2 (East European)"),
                    ]);

        region = "Greek";
        _all.addAll([
                            new Charset("cp737", region, "CP737 MS-DOS Greek"),
                            new Charset("cp869", region, "CP869 MS-DOS Greek 2"),
                            new Charset("cp1253", region, "CP1253 Windows Greek"),
                            new Charset("cp10006", region, "CP10006 Macintosh Greek"),
                            new Charset("iso8859-7", region, "ISO 8859-7 Greek"),
                    ]);

        region = "Hebrew";
        _all.addAll([
                            new Charset("cp862", region, "CP862 MS-DOS Hebrew"),
                            new Charset("cp1255", region, "CP1255 Windows Hebrew"),
                            new Charset("iso8859-8", region, "ISO 8859-8 Hebrew"),
                    ]);

        region = "North European";
        _all.addAll([
                            new Charset("cp861", region, "CP861 MS-DOS Icelandic"),
                            new Charset("cp865", region, "CP865 MS-DOS Nordic"),
                            new Charset("cp10079", region, "CP10079 Macintosh Icelandic"),
                            new Charset("iso8859-10", region, "ISO 8859-10 Latin6 (Nordic)"),
                    ]);

        region = "Turkish";
        _all.addAll([
                            new Charset("cp857", region, "CP857 MS-DOS Turkish"),
                            new Charset("cp1254", region, "CP1254 Windows Latin 5 (Turkish)"),
                            new Charset("cp10081", region, "CP10081 Macintosh Turkish"),
                            new Charset("iso8859-3", region, "ISO 8859-3 Latin3 (South European)"),
                            new Charset("iso8859-9", region, "ISO 8859-9 Latin5 (Turkish)"),
                    ]);
    }

    static Future<String> loadData() {
        String url = "data/charsets.txt";

        return HttpRequest.getString(url).then((String content) {
            List<String> lines = content.split(new RegExp(r"[\r\n]+"));
            for (String line in lines) {
                List<String> pair = line.split(":");
                if (pair.length > 1) {
                    Charset cs = get(pair[0]);
                    if (cs != null) {
                        cs._data = pair[1];
                    }
                }
            }
        });
    }

    static Charset get(String id) {
        return _all.firstWhere((cs) => cs.id == id, orElse: () => null);
    }

    static void fillSelectElement(SelectElement list) {
        List<String> items;
        Map<String, OptGroupElement> groups = new Map<String, OptGroupElement>();

        _all.forEach((Charset cs) {
            OptGroupElement group = groups[cs.region];
            if (group == null) {
                group = new OptGroupElement();
                group.title = cs.region;
                groups[cs.region] = group;
            }
            group.append(new OptionElement(data: cs.name, value: cs.id));
        });

        list.children.addAll(groups.values);
    }

    void load(HexGrid grid) {
        if (!this.isBuiltIn && !_gotData) {
            loadData().then((String content) {
                _gotData = true;
                this.load(grid);
            });

            return;
        }


        if (!this.loaded) {

            this.charmap = new List<int>.generate(0x80, (int n) {
                if (n < _controlChars.length) {
                    return _controlChars[n];
                }
                else {
                    return n;
                }
            }, growable: true);


            for (String ch in this._data.split(",")) {
                this.charmap.add(int.parse(ch, radix: 16, onError: (String s) => 0));
            }

            this.loaded = true;

            StringBuffer all = new StringBuffer();
            for (int n = 0; n <= 0xFF; n++) {
                all.writeCharCode(this.charmap[n]);
            }
            this.chars = all.toString();
        }

        if (grid != null) {
            this.apply(grid);
        }
    }

    void apply(HexGrid grid) {
        if (grid.charsetStyles != null) {
            grid.charsetStyles.ownerNode.remove();
        }

        grid.charset = this;

        StyleElement style = new StyleElement();
        grid.element.parent.append(style);
        grid.charsetStyles = style.sheet;

        for (int n = 0; n <= 0xFF; n++) {
            grid.charsetStyles.insertRule(".ascii.value[data-value='${n}']::before { content: '\\${this.charmap[n]}' }", grid.charsetStyles.cssRules.length);
        }
    }
}
