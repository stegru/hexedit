import 'lib/hexedit.dart';
import 'dart:typed_data';

void main() {

    HexEdit hexEdit = new HexEdit();
    hexEdit.onReady.add((HexEdit he) {
        Uint8List buf = new Uint8List(0x1500);
        for (int n = 0; n <= 255; n++) {
            buf[n] = n;
        }
        he.setData(new HexData(he, buf));

    });
    hexEdit.start('#HexEditor', '#HexGrid');
}
