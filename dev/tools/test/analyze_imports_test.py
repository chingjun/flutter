#!/usr/bin/env python3
"""
Unit tests for analyze_imports.py.
"""

import os
import sys
import tempfile
import unittest

# Import analyze_imports module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import analyze_imports


class TestAnalyzeImports(unittest.TestCase):
    def setUp(self):
        self.temp_file = tempfile.NamedTemporaryFile("w+", delete=False, suffix=".csv")
        # Write test CSV graph:
        # A -> B (sym1, sym2)
        # B -> C (sym3)
        # C -> A (sym4)  [A, B, C form a 3-node cycle]
        # C -> D (sym5)
        # D -> E (sym6)
        # F -> G (sym7)
        # G -> F (sym8)  [F, G form a 2-node cycle]
        # H -> D (sym9)  [H is a linear leaf importer]
        self.temp_file.write(
            "source_file,imported_file,symbol\n"
            "A.dart,B.dart,sym1\n"
            "A.dart,B.dart,sym2\n"
            "B.dart,C.dart,sym3\n"
            "C.dart,A.dart,sym4\n"
            "C.dart,D.dart,sym5\n"
            "D.dart,E.dart,sym6\n"
            "F.dart,G.dart,sym7\n"
            "G.dart,F.dart,sym8\n"
            "H.dart,D.dart,sym9\n"
        )
        self.temp_file.close()

    def tearDown(self):
        if os.path.exists(self.temp_file.name):
            os.remove(self.temp_file.name)

    def test_direct_imports_and_symbols(self):
        analyzer = analyze_imports.ImportAnalyzer(self.temp_file.name)
        direct = analyzer.compute_direct_import_symbol_counts()
        direct_map = {(src, imp): (cnt, syms) for src, imp, cnt, syms in direct}

        self.assertEqual(direct_map[("A.dart", "B.dart")], (2, ["sym1", "sym2"]))
        self.assertEqual(direct_map[("B.dart", "C.dart")], (1, ["sym3"]))
        self.assertEqual(direct_map[("C.dart", "A.dart")], (1, ["sym4"]))
        self.assertEqual(direct_map[("C.dart", "D.dart")], (1, ["sym5"]))
        self.assertEqual(direct_map[("D.dart", "E.dart")], (1, ["sym6"]))
        self.assertEqual(direct_map[("F.dart", "G.dart")], (1, ["sym7"]))
        self.assertEqual(direct_map[("G.dart", "F.dart")], (1, ["sym8"]))
        self.assertEqual(direct_map[("H.dart", "D.dart")], (1, ["sym9"]))

    def test_transitive_imports(self):
        analyzer = analyze_imports.ImportAnalyzer(self.temp_file.name)
        transitive = analyzer.compute_transitive_imports()

        # A reaches B, C, A, D, E
        self.assertEqual(transitive["A.dart"], ["A.dart", "B.dart", "C.dart", "D.dart", "E.dart"])
        # B reaches C, A, B, D, E
        self.assertEqual(transitive["B.dart"], ["A.dart", "B.dart", "C.dart", "D.dart", "E.dart"])
        # C reaches A, B, C, D, E
        self.assertEqual(transitive["C.dart"], ["A.dart", "B.dart", "C.dart", "D.dart", "E.dart"])
        # D reaches E
        self.assertEqual(transitive["D.dart"], ["E.dart"])
        # F reaches F, G
        self.assertEqual(transitive["F.dart"], ["F.dart", "G.dart"])
        # G reaches F, G
        self.assertEqual(transitive["G.dart"], ["F.dart", "G.dart"])
        # H reaches D, E
        self.assertEqual(transitive["H.dart"], ["D.dart", "E.dart"])

    def test_import_cycles(self):
        analyzer = analyze_imports.ImportAnalyzer(self.temp_file.name)
        cycles = analyzer.compute_import_cycles()

        # Expect 2 cycles: [A, B, C] of size 3 and [F, G] of size 2
        self.assertEqual(len(cycles), 2)
        self.assertEqual(cycles[0], ["A.dart", "B.dart", "C.dart"])
        self.assertEqual(cycles[1], ["F.dart", "G.dart"])

        # Check property: importing any single file in cycle reaches all others
        for cycle in cycles:
            cycle_set = set(cycle)
            for f in cycle:
                trans = set(analyzer.compute_transitive_imports()[f])
                self.assertTrue(cycle_set.issubset(trans))


if __name__ == "__main__":
    unittest.main()
