# gettext-po-parser

[![NPM version](https://img.shields.io/npm/v/gettext-po-parser.svg)](https://npmjs.org/package/gettext-po-parser)
[![Node.js CI status](https://github.com/zhanghai/gettext-po-parser/workflows/Node.js%20CI/badge.svg)](https://github.com/zhanghai/gettext-po-parser/actions)
[![NPM downloads](https://img.shields.io/npm/dt/gettext-po-parser.svg)](https://npmjs.org/package/gettext-po-parser)

A Gettext PO file parser written with [peg.js](https://github.com/pegjs/pegjs). Tested to support parsing most PO files in the GNOME project, and every parsed node contains information for its location in source file.

## Installation

```shell
npm install gettext-po-parser
```

## Usage

```typescript
import { parse } from 'gettext-po-parser';

const catalog = parse(input);
```

You can take a look at the [type definitions](parser.d.ts) for the returned data structure.

## License

[MIT](LICENSE)
