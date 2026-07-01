#!/usr/bin/env python3
"""Standalone test of predict.py on real examples from the eval data."""

import sys
import json
sys.path.insert(0, "/home/acl2/books/kestrel/acl2data/postprocess")

from predict import Acl2ProofFixer

fixer = Acl2ProofFixer("/workspaces/acl2-jupyter/data/models")

# Test 1: simple STRINGP concatenate-names lemma
ck1 = ['(', '(', 'STRINGP', '(', 'CGEN::CONCATENATE-NAMES', 'var-0', ')', ')', ')']
goal1 = '(DEFTHM CGEN::CONCATENATE-NAMES-IS-STRINGP (STRINGP (CGEN::CONCATENATE-NAMES ...)))'
print('Test 1: STRINGP of CONCATENATE-NAMES')
preds = fixer.predict(ck1, goal1, 'top')
fixer.print_predictions(preds, acl2_format=True)
print()

# Test 2: SYMBOLP with MODIFY-SYMBOL
ck2 = ['(', '(', 'NOT', '(', 'SYMBOLP', 'var-0', ')', ')', '(', 'NOT']
goal2 = '(DEFTHM CGEN::MODIFIED-SYMBOL-SATISFIES-SYMBOLP (IMPLIES ...))'
print('Test 2: SYMBOLP with MODIFY-SYMBOL')
preds = fixer.predict(ck2, goal2, 'top')
fixer.print_predictions(preds, acl2_format=True)
print()

# Test 3: simple NATP CDR-CONS pattern
ck3 = ['(', '(', 'NOT', '(', 'NATP', 'var-0', ')', ')', '(', 'NATP', '(', 'CDR', 'var-0', ')', ')', ')']
goal3 = '(DEFTHM FOO-NATP-OF-CDR (IMPLIES (CONSP X) (NATP (CDR X))))'
print('Test 3: NATP of CDR')
preds = fixer.predict(ck3, goal3, 'top')
fixer.print_predictions(preds, acl2_format=True)
