// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticsSerializationDelegate;
import 'package:flutter/src/widgets/icon_data.dart' show IconData, IconDataProperty;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IconDataDiagnosticsProperty includes valueProperties in JSON', () {
    var property = IconDataProperty('foo', const IconData(101010));
    final valueProperties =
        property.toJsonMap(const DiagnosticsSerializationDelegate())['valueProperties']!
            as Map<String, Object>;
    expect(valueProperties['codePoint'], 101010);

    property = IconDataProperty('foo', null);
    final Map<String, Object?> json = property.toJsonMap(const DiagnosticsSerializationDelegate());
    expect(json.containsKey('valueProperties'), isFalse);
  });
}
