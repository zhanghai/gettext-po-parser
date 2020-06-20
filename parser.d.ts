export interface Catalog extends Node {
  messages: Array<Message>;
}

export interface Message extends Node {
  translatorComments: Array<Comment>;
  extractedComments: Array<Comment>;
  references: Array<Comment>;
  flags: Flags | null;
  previousContext: MessageString | null;
  previousUntranslatedString: MessageString | null;
  previousUntranslatedPluralString: MessageString | null;
  context: MessageString | null;
  untranslatedString: MessageString;
  untranslatedStringPlural: MessageString | null;
  translatedStrings: Array<MessageString>;
  isObsolete: boolean;
}

export interface Comment extends Node {
  value: string;
}

export interface Flags extends Node {
  value: Array<string>
}

export interface MessageString extends Node {
  value: string;
}

export interface Node {
  location: Location;
}

export interface Location {
  start: Position;
  end: Position;
}

export interface Position {
  offset: number;
  line: number;
  column: number;
}

export declare class SyntaxError extends Error {
  expected: Array<any>;
  found: string;
  location: Location;
}

export interface ParseOptions {
  rawString?: boolean;
}

export declare function parse(input: string, options?: ParseOptions): Catalog;
