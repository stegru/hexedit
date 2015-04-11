part of hexedit.panels;


typedef String DataType_GetString(DataType dt, ByteConverter bc);

typedef bool DataType_SetString(DataType dt, ByteConverter bc, String value);

class DataCategory {
    static const INTEGERS = const DataCategory._("Integers");
    static const FLOATS = const DataCategory._("Floats");
    static const TEXT = const DataCategory._("Text");

    final String name;

    const DataCategory._(this.name);
}

class DataType {
    static const LARGEST_ITEM = 0x100;

    final String name;
    final int byteCount;
    final DataCategory category;
    final bool isNumeric;

    Endianness endian = null;
    bool variableSize = false;
    bool signed;

    DataType_GetString getString;
    DataType_SetString setString;

    static List<DataType> all = init();

    static List<DataType> init() {
        List<DataType> items = new List<DataType>();
        DataType dt;

        DataCategory category = DataCategory.INTEGERS;

        for (int size in [1, 2, 4, 8]) {
            for (bool signed in [true, false]) {
                dt = new DataType(
                        name: "${signed ? "Signed" : "Unsigned" } ${size * 8}-bit",
                        byteCount: size,
                        signed: signed,
                        category: category,
                        isNumeric: true,
                        getString: (DataType dt, ByteConverter bc) => bc.toIntegerString(dt.byteCount, dt.signed),
                        setString: (DataType dt, ByteConverter bc, String value) => bc.parseIntegerString(value,
                                                                                                          dt.byteCount,
                                                                                                          dt.signed)
                        );

                items.add(dt);
            }
        }

        category = DataCategory.FLOATS;

        for (int size in [4, 8]) {
            dt = new DataType(
                    name: "Float ${size * 8}-bit",
                    byteCount: size,
                    category: category,
                    isNumeric: true,
                    getString: (DataType dt, ByteConverter bc) {
                        return bc.toFloatString(dt.byteCount, false);
                    },
                    setString: (DataType dt, ByteConverter bc, String value) {
                        return bc.parseFloatString(value, dt.byteCount);
                    }
                    );
            items.add(dt);
        }

        category = DataCategory.TEXT;
        dt = new DataType(
                name: "ASCII",
                byteCount: 0,
                category: category,
                isNumeric: false,
                variableSize: true,
                getString: (DataType dt, ByteConverter bc) {
                    return bc.toAsciiString();
                },
                setString: (DataType dt, ByteConverter bc, String value) {
                    return bc.parseAsciiString(value);
                }
                );

        items.add(dt);

        dt = new DataType(
                name: "UTF-8",
                byteCount: 0,
                category: category,
                isNumeric: false,
                variableSize: true,
                getString: (DataType dt, ByteConverter bc) {
                    return bc.toUtf8String();
                },
                setString: (DataType dt, ByteConverter bc, String value) {
                    return bc.parseUtf8String(value);
                }
                );

        items.add(dt);

        dt = new DataType(
                name: "UTF-16",
                byteCount: 0,
                category: category,
                isNumeric: false,
                variableSize: true,
                getString: (DataType dt, ByteConverter bc) {
                    return bc.toUtf16String();
                },
                setString: (DataType dt, ByteConverter bc, String value) {
                    return bc.parseUtf16String(value);
                }
                );

        items.add(dt);

        dt = new DataType(
                name: "C String",
                byteCount: 0,
                category: category,
                isNumeric: false,
                variableSize: true,
                getString: (DataType dt, ByteConverter bc) {
                    return bc.toCStringString();
                },
                setString: (DataType dt, ByteConverter bc, String value) {
                    return bc.parseCStringString(value);
                }
                );

        items.add(dt);

        dt = new DataType(
                name: "Pascal String",
                byteCount: 0,
                category: category,
                isNumeric: false,
                variableSize: true,
                getString: (DataType dt, ByteConverter bc) {
                    return bc.toPascalStringString();
                },
                setString: (DataType dt, ByteConverter bc, String value) {
                    return bc.parsePascalStringString(value);
                }
                );

        items.add(dt);


        return items;
    }

    DataType({String this.name, int this.byteCount, DataCategory this.category, this.getString, this.setString, this.signed, this.isNumeric, this.variableSize }) {
    }
}
