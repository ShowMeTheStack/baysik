// BASIC error codes and messages (QBasic 1.1 / GW-BASIC numbering)
(function (RC) {
  'use strict';
  const B = RC.Basic || (RC.Basic = {});

  B.ERRORS = {
    1: 'NEXT without FOR', 2: 'Syntax error', 3: 'RETURN without GOSUB', 4: 'Out of DATA',
    5: 'Illegal function call', 6: 'Overflow', 7: 'Out of memory', 8: 'Label not defined',
    9: 'Subscript out of range', 10: 'Duplicate definition', 11: 'Division by zero',
    12: 'Illegal in direct mode', 13: 'Type mismatch', 14: 'Out of string space',
    15: 'String too long', 16: 'String formula too complex', 17: 'Cannot continue',
    18: 'Function not defined', 19: 'No RESUME', 20: 'RESUME without error',
    21: 'Unprintable error', 22: 'Missing operand', 23: 'Line buffer overflow',
    24: 'Device timeout', 25: 'Device fault', 26: 'FOR without NEXT', 27: 'Out of paper',
    29: 'WHILE without WEND', 30: 'WEND without WHILE', 33: 'Duplicate label',
    35: 'Subprogram not defined', 37: 'Argument-count mismatch', 38: 'Array not defined',
    40: 'Variable required', 50: 'FIELD overflow', 51: 'Internal error',
    52: 'Bad file name or number', 53: 'File not found', 54: 'Bad file mode',
    55: 'File already open', 56: 'FIELD statement active', 57: 'Device I/O error',
    58: 'File already exists', 59: 'Bad record length', 61: 'Disk full',
    62: 'Input past end of file', 63: 'Bad record number', 64: 'Bad file name',
    66: 'Direct statement in file', 67: 'Too many files', 68: 'Device unavailable',
    69: 'Communication-buffer overflow', 70: 'Permission denied', 71: 'Disk not ready',
    72: 'Disk-media error', 73: 'Advanced feature unavailable', 74: 'Rename across disks',
    75: 'Path/File access error', 76: 'Path not found',
  };

  /** Runtime error raised by BASIC code. `code` is the ERR value. */
  class BasicError extends Error {
    constructor(code, detail) {
      super((B.ERRORS[code] || 'Unprintable error') + (detail ? ' (' + detail + ')' : ''));
      this.code = code;
      this.detail = detail || '';
    }
  }
  B.BasicError = BasicError;

  /** Compile-time (syntax/semantic) error, with source position. */
  class CompileError extends Error {
    constructor(message, pos, code) {
      super(message);
      this.pos = pos || null; // {file, line, col, endCol}
      this.code = code || 2;
    }
  }
  B.CompileError = CompileError;

  B.err = function (code, detail) { throw new BasicError(code, detail); };
})(RC);
