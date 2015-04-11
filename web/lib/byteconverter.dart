part of hexedit;

class ByteConverter {
    ByteData bytes;
    Uint8List byteList;

    /// Number of available bytes
    int get byteCount => this.bytes.lengthInBytes;

    /// Number of bytes used by variable length data types (like strings)
    int bytesUsed = 0;

    bool littleEndian = Endianness.HOST_ENDIAN == Endianness.LITTLE_ENDIAN;

    Endianness get endian => this.littleEndian ? Endianness.LITTLE_ENDIAN : Endianness.BIG_ENDIAN;

    set endian(Endianness e) => this.littleEndian = e == Endianness.LITTLE_ENDIAN;

    bool get _dart2js => identical(1, 1.0);

    ByteConverter(Uint8List this.byteList) {
        this.bytes = new ByteData.view(this.byteList.buffer);
        this.bytesUsed = this.byteCount;
    }

    factory ByteConverter.fromHexString(String hexString){
        return new ByteConverter(hexStringToBytes(hexString));
    }

    factory ByteConverter.fromIntegerString(String text, int size, bool signed){
        ByteConverter bc = new ByteConverter(new Uint8List.fromList(new List<int>.generate(size, (i) => 0,
                                                                                           growable: false)));

        if (bc.parseIntegerString(text, size, signed)) {
            return bc;
        }

        return null;
    }

    /** Returns the list of bytes represented by [hexString] */
    static Uint8List hexStringToBytes(String hexString) {
        Uint8List bytes = new Uint8List(hexString.length ~/ 2);
        int n = 0;

        bool even = false;
        int value = 0;
        for (int ch in hexString.codeUnits) {
            int nibble = (((ch & 0x30) == 0x30 ? 0 : 9) + ch) % 16;

            if (!even) {
                value = nibble << 4;
            } else {
                bytes[n++] = value | nibble;
            }

            even = !even;
        }

        return bytes;
    }

    /// Gets the integer value of the buffer, using the first [size] bytes.
    IntX getInteger(int size, [bool signed = false]) {
        if (size > this.byteCount) {
            return null;
        }

        this.bytesUsed = size;

        int value = null;
        switch (size * 8) {
            case 8:
                return new Int32(signed ? this.bytes.getInt8(0) : this.bytes.getUint8(0));

            case 16:
                return new Int32(signed ? this.bytes.getInt16(0, this.endian) : this.bytes.getUint16(0, this.endian));

            case 32:
            // 32bit numbers will be stored as 64 to fit unsigned values.
                value = this.bytes.getUint32(0, this.endian);
                return new Int64(signed ? value.toSigned(32) : value.toUnsigned(32));

            case 64:
            // there isn't an unsigned 64bit in dart.
                List<int> list = new Int8List.view(this.bytes.buffer).toList(growable:false);
                return this.littleEndian ? new Int64.fromBytes(list) : new Int64.fromBytesBigEndian(list);
        }

        return null;
    }

    /// Gets the float value of the buffer. [size] is either 4 or 8 bytes.
    double getFloat(int size) {
        if (size == 4) {
            return this.bytes.getFloat32(0, this.endian);
        } else if (size == 8) {
            return this.bytes.getFloat64(0, this.endian);
        }

        return null;
    }

    /// Gets the [size] byte integer value of the buffer as a string.
    String toIntegerString(int size, bool signed) {
        if (size > this.byteCount) {
            return "";
        }

        IntX value = this.getInteger(size, signed);

        return value.toString();
    }

    /// Parses [text] as a [size] byte integer, returning [true] on success.
    bool parseIntegerString(String text, int size, bool signed, [Endianness endian = null]) {
        if (endian == null) {
            endian = this.endian;
        }

        if (size > this.byteCount) {
            return false;
        }

        int value;
        try {
            value = int.parse(text);
        }
        catch (FormatException) {
            return false;
        }

        this.clear(size);


        if (signed) {
            switch (size * 8) {
                case 8:
                    this.bytes.setInt8(0, value);
                    return true;

                case 16:
                    this.bytes.setInt16(0, value, endian);
                    return true;

                case 32:
                    this.bytes.setInt32(0, value, endian);
                    return true;

                case 64:
                    this.bytes.setInt64(0, value, endian);
                    return true;
            }
        } else {
            switch (size * 8) {
                case 8:
                    this.bytes.setUint8(0, value);
                    return true;

                case 16:
                    this.bytes.setUint16(0, value, endian);
                    return true;

                case 32:
                    this.bytes.setUint32(0, value, endian);
                    return true;

                case 64:
                    this.bytes.setUint64(0, value, endian);
                    return true;
            }
        }

        return false;
    }

    /// Returns the string representaion of the float value. [size] of the float is either 4 or 8 bytes.
    String toFloatString(int size, bool exponential) {
        if (size > this.byteCount) {
            return "";
        }

        double d = this.getFloat(size);
        return exponential ? d.toStringAsExponential() : d.toString();
    }

    /// Parses [text] into a float. [size] of the float is either 4 or 8 bytes. Returns [true] on success.
    bool parseFloatString(String text, int size) {
        if (size > this.byteCount) {
            return false;
        }

        double value;
        try {
            value = double.parse(text);
        }
        catch (FormatException) {
            return false;
        }

        this.clear(size);

        if (size == 4) {
            this.bytes.setFloat32(0, value, this.endian);
            return true;
        } else if (size == 8) {
            this.bytes.setFloat64(0, value, this.endian);
            return true;
        }

        return false;
    }

    /// Calls [int.toRadixString] on the integer value of the buffer.
    String toRadixString(int size, int radix) {
        if (size > this.byteCount) {
            return "";
        }

        return this.getInteger(size).toRadixString(radix);
    }

    /// Returns a hex string of the first [size] bytes of the buffer.
    String toHexString(int size) {
        return this.toRadixString(size, 16);
    }

    /// Returns a binary string of the first [size] bytes of the buffer.
    String toBinaryString(int size) {
        return this.toRadixString(size, 2);
    }

    /// Returns an array of bits of the first [size] bytes of the buffer.
    List<bool> toBits(int size) {
        List<bool> bits = [];
        for (int byte = 0; byte < size; byte++) {
            for (int bit = 0; bit < 8; bit++) {
                bits.add((this.bytes.getUint8(byte) & (1 << bit)) != 0);
            }
        }

        return bits;
    }

    /// Sets the bits of the buffer.
    void fromBits(List<bool> bits) {
        int byte = 0;
        int value = 0;
        int bitNumber = 0;
        for (bool bit in bits) {
            if (bit) {
                value = value | (1 << bitNumber);
            }

            if (++bitNumber == 8) {
                this.bytes.setUint8(byte++, value);
                value = 0;
                bitNumber = 0;
            }
        }
    }

    String fromTimeT() {
        return "todo";
        //Int64 n = new Int64.fromBytes();
    }

    /// Returns a string as if the buffer is a null-terminated ASCII string.
    String toCStringString() {
        bool gotNull = false;
        List<int> list = this.byteList.takeWhile((b) => !(gotNull = b == 0x00)).toList(growable: false);
        if (!gotNull) {
            throw new ByteConverterException("No terminator");
        }

        this.bytesUsed = list.length + 1;
        return ASCII.decode(list, allowInvalid: true);
    }

    /// Sets the buffer to the null-terminated ASCII string represented by [text].
    bool parseCStringString(String text) {
        List<int> bytes = ASCII.encode(text);
        if (bytes.length >= this.byteCount) {
            return false;
        }

        this.clear(bytes.length + 1);
        this.byteList.setRange(0, bytes.length, bytes);
        return true;
    }

    /// Returns the string as if the buffer was a pascal string.
    String toPascalStringString() {

        int len = this.byteCount > 0 ? this.bytes.getUint8(0) : 0;

        if (len >= this.byteCount) {
            throw new ByteConverterException("Invalid length");
        }

        List<int> list = this.byteList.skip(1).take(len).toList(growable: false);
        this.bytesUsed = list.length + 1;
        return ASCII.decode(list, allowInvalid: true);
    }

    /// Sets the buffer to contain a pascal string representation of [text].
    bool parsePascalStringString(String text) {
        if (text.length > 255) {
            text = text.substring(0, 255);
        }
        try {
            List<int> bytes = ASCII.encode(text);

            if (bytes.length >= this.byteCount) {
                return false;
            }

            this.clear(bytes.length + 1);
            this.bytes.setUint8(0, bytes.length);
            this.byteList.setRange(1, bytes.length + 1, bytes);
            return true;
        }
        catch (e) {
            return false;
        }
    }

    /// Returns a string of the buffer encoded as ASCII.
    String toAsciiString() {
        bool gotNull = false;
        List<int> list = this.byteList.toList(growable: false);
        this.bytesUsed = list.length;
        return ASCII.decode(list, allowInvalid: true);
    }

    /// Sets the buffer to the ASCII encoding of [text].
    bool parseAsciiString(String text) {
        List<int> bytes = ASCII.encode(text);
        this.clear(bytes.length);
        this.byteList.setRange(0, bytes.length, bytes);
        return true;
    }

    /// Outputs a UTF8 string.
    String toUtf8String() {
        List<int> list = this.toList();
        this.bytesUsed = list.length;
        return UTF8.decode(list, allowMalformed: true);
    }

    /// Sets the buffer to the UTF8 string.
    bool parseUtf8String(String text) {
        try {
            List<int> bytes = UTF8.encode(text);
            this.clear(bytes.length);
            this.bytes.setUint8(0, bytes.length);
            this.byteList.setRange(0, bytes.length, bytes);
        }
        catch (e) {
            return false;
        }
        return true;
    }

    /// Returns a string as if the buffer was a UTF16 string.
    String toUtf16String() {
        if (this.byteList.length < 2) {
            return "";
        }

        int len = (this.byteList.length - (this.byteList.length % Uint16List.BYTES_PER_ELEMENT));
        return new String.fromCharCodes(new Uint16List.view(this.byteList.buffer, 0,
                                                            len ~/ Uint16List.BYTES_PER_ELEMENT).toList());
    }

    /// Sets the buffer to the UTF16 encoding of [text].
    bool parseUtf16String(String text) {
        try {
            List<int> units = text.codeUnits;
            new Uint16List.view(this.byteList.buffer).setRange(0, units.length, units);
            return true;
        }
        catch (e) {
            return false;
        }
    }

    /// Clear first [size] bytes of the buffer.
    void clear([int size = 0]) {
        if (size == 0) {
            size = this.byteCount;
        }

        for (int n = 0; n < size; n++) {
            this.bytes.setUint8(n, 0);
        }

        this.bytesUsed = size;
    }

    /// Returns a list of the bytes.
    List<int> toList() {
        return this.byteList.toList(growable: false);
    }
}

/**
 * The was something wrong with the data conversion.
 */
class ByteConverterException implements Exception {
    final String message;

    const ByteConverterException([this.message = ""]);

    String toString() => this.message;
}
