class PixelDataWrapper {
  PixelDataWrapper(this.n, int id, bool fetched) {
    pd = PixelData(id, fetched);
  }

  int n;
  PixelData pd;
}

class PixelData {
  PixelData(this.id, this.fetched);

  int id;
  bool fetched;
}

class Block {
  List<PixelData> pixels = List(4);
}

class Matrix {
  static const int _size = 20;
  var lastReceived = -1;
  final blocks = List<Block>.generate(_size * _size, (i) => Block());

  int get size => _size;
}
