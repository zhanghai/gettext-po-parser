// https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
// gettext-0.20.2/gettext-tools/src/po-lex.c
// gettext-0.20.2/gettext-tools/src/po-gram-gen.y
// gettext-0.20.2/gettext-tools/src/read-catalog.c
// gettext-0.20.2/gettext-tools/src/read-catalog-abstract.c
// https://techbase.kde.org/Localization/Concepts/PO_Odyssey

{
  let isParsingObsolete = false;

  function setParsingObsolete(obsolete) {
    isParsingObsolete = obsolete;
    return true;
  }

  function buildList(first, rest, index) {
    return [first, ...rest.map(it => it[index])];
  }

  function extractOptional(group, index) {
    return group ? group[index] : null;
  }
}

Catalog
  = _ first:Message rest:(_ Message)* (_ Comments)* _ {
    return {
      location: location(),
      messages: buildList(first, rest, 1),
    };
  }

Message
  = message:(
    commentsGroup:(Comments _)? previousStringsGroup:(PreviousStrings _)? strings:(
      &{ return setParsingObsolete(false); } strings:Strings {
        return strings;
      }
      / '#~' _ &{ return setParsingObsolete(true); } strings:(
        Strings &{ return setParsingObsolete(false); }
        / !{ return setParsingObsolete(false); }
      ) {
        return strings[0];
      }
    ) {
      return [extractOptional(commentsGroup, 0) || [], extractOptional(previousStringsGroup, 0) || [null, null, null],
          strings];
    }
    / '#~' _ &{ return setParsingObsolete(true); } message:(
      commentsGroup:(Comments _)? previousStringsGroup:(PreviousStrings _)? strings:Strings &{ return setParsingObsolete(false); } {
        return [extractOptional(commentsGroup, 0) || [], extractOptional(previousStringsGroup, 0) || [null, null, null],
            strings];
      }
      / !{ return setParsingObsolete(false); }
    ) {
       return message;
    }
  ) {
    const [comments, previousStrings, strings] = message;
    const typeToComments = new Map();
    for (const { type, ...comment } of comments) {
      let typeComments = typeToComments.get(type);
      if (!typeComments) {
        typeComments = [];
        typeToComments.set(type, typeComments);
      }
      typeComments.push(comment);
    }
    const translatorComments = typeToComments.get('translator') || [];
    const extractedComments = typeToComments.get('extracted') || [];
    const references = typeToComments.get('reference') || [];
    const flags = typeToComments.has('flags') ? typeToComments.get('flags').reduce((mergedFlags, flags) => ({
      location: {
        start: mergedFlags.location.start,
        end: flags.location.end,
      },
      value: [...mergedFlags.value, ...flags.value],
    })) : null;
    const [previousContext, previousUntranslatedString, previousUntranslatedPluralString] = previousStrings;
    const [context, untranslatedString, untranslatedPluralString, translatedStrings, isObsolete] = strings;
    return {
      location: location(),
      translatorComments,
      extractedComments,
      references,
      flags,
      previousContext,
      previousUntranslatedString,
      previousUntranslatedPluralString,
      context,
      untranslatedString,
      untranslatedPluralString,
      translatedStrings,
      isObsolete,
    };
  }

Comments
  = first:Comment rest:(_ Comment)* { return buildList(first, rest, 1); }

Comment
  = ExtractedComment
  / ReferenceComment
  / FlagsComment
  / TranslatorComment

TranslatorComment
  = '#' !('~' !'|') ' '? value:$([^\n])* {
    return {
      location: location(),
      type: 'translator',
      value,
    };
  }

ExtractedComment
  = '#.' ' '? value:$([^\n])* {
    return {
      location: location(),
      type: 'extracted',
      value,
    };
  }

ReferenceComment
  = '#:' ' '? value:$([^\n])* {
    return {
      location: location(),
      type: 'reference',
      value,
    };
  }

FlagsComment
  = '#,' __ first:Flag rest:(',' __ Flag)* (__ ',')? {
    return {
      location: location(),
      type: 'flags',
      value: buildList(first, rest, 2),
    };
  }

Flag
  = flag:$[^,\n]+ { return flag.trim(); }

PreviousStrings
  = previousContextGroup:(PreviousContext _)? previousUntranslatedString:PreviousUntranslatedString previousUntranslatedPluralStringGroup:(_ PreviousUntranslatedPluralString)? {
    return [extractOptional(previousContextGroup, 0), previousUntranslatedString, extractOptional(previousUntranslatedPluralStringGroup, 1)];
  }

PreviousContext
  = '#|' _ 'msgctxt' _ value:String {
    return {
      location: location(),
      value,
    };
  }

PreviousUntranslatedString
  = '#|' _ 'msgid' _ value:String {
    return {
      location: location(),
      value,
    };
  }

PreviousUntranslatedPluralString
  = '#|' _ 'msgid_plural' _ value:String {
    return {
      location: location(),
      value,
    };
  }

Strings
  = contextGroup:(Context _)? untranslatedString:UntranslatedString _ translatedString:TranslatedString {
    return [extractOptional(contextGroup, 0), untranslatedString, null, [translatedString], isParsingObsolete];
  }
  / contextGroup:(Context _)? untranslatedString:UntranslatedString _ untranslatedPluralString:UntranslatedPluralString _ translatedPluralStrings:TranslatedPluralStrings {
    return [extractOptional(contextGroup, 0), untranslatedString, untranslatedPluralString, translatedPluralStrings,
        isParsingObsolete];
  }

Context
  = 'msgctxt' _ value:String {
    return {
      location: location(),
      value,
    };
  }

UntranslatedString
  = 'msgid' _ value:String {
    return {
      location: location(),
      value,
    };
  }

UntranslatedPluralString
  = 'msgid_plural' _ value:String {
    return {
      location: location(),
      value,
    };
  }

TranslatedString
  = 'msgstr' _ value:String {
    return {
      location: location(),
      value,
    };
  }

TranslatedPluralStrings
  = first:TranslatedPluralString rest:(_ TranslatedPluralString)* {
    if (first[0] !== 0) {
      error('First translated plural string has non-zero index');
    }
    for (let i = 0; i < rest.length; ++i) {
      if (rest[i][1][0] !== 1 + i) {
        error('Translated plural string has wrong index');
      }
    }
    return buildList(first[1], rest.map(it => it[1]), 1);
  }

TranslatedPluralString
  = 'msgstr' _ '[' _ digits:$[0-9]+ _ ']' _ value:String {
    return [Number.parseInt(digits, 10), {
      location: location(),
      value,
    }];
  }

String
  = first:SingleString rest:(_ SingleString)* { return buildList(first, rest, 1).join(''); }

SingleString
  = '"' chars:StringChar* '"' {
    if (options.rawString) {
      const stringText = text();
      return stringText.substring(1, stringText.length - 1);
    } else {
      return chars.join('');
    }
  }

StringChar
  = [^"\\\n]
  / EscapeSequence

EscapeSequence
    = SimpleEscapeSequence
    / OctalEscapeSequence
    / HexadecimalEscapeSequence
    / UniversalCharacterName

SimpleEscapeSequence
    = ('\\\'' / '\\"' / '\\?' / '\\\\') { return text().charAt(1); }
    / '\\a' { return '\x07'; }
    / '\\b' { return '\b'; }
    / '\\f' { return '\f'; }
    / '\\n' { return '\n'; }
    / '\\r' { return '\r'; }
    / '\\t' { return '\t'; }
    / '\\v' { return '\v'; }

OctalEscapeSequence
    = '\\' digits:$(OctalDigit OctalDigit? OctalDigit?) { return String.fromCharCode(Number.parseInt(digits, 8)); }

OctalDigit
    = [0-7]

HexadecimalEscapeSequence
    = '\\x' digits:$HexadecimalDigit+ { return String.fromCharCode(Number.parseInt(digits, 16)); }

UniversalCharacterName
    = universalCharacterName:('\\u' $HexadecimalQuad / '\\U' $(HexadecimalQuad HexadecimalQuad)) {
       const digits = universalCharacterName[1];
       const charCode = Number.parseInt(digits, 16);
       // The disallowed characters are the characters in the basic character set and the code positions reserved by
       // ISO/IEC 10646 for control characters, the character DELETE, and the S-zone (reserved for use by UTF−16).
       if ((charCode >= 0x0000 && charCode <= 0x001F)
           || (charCode >= 0x007F && charCode <= 0x009F)
           || (charCode >= 0xD800 && charCode <= 0xDFFF)) {
         error('Disallowed character in universal character name: 0x' + digits);
       }
       return String.fromCharCode(charCode);
    }

HexadecimalQuad
    = HexadecimalDigit HexadecimalDigit HexadecimalDigit HexadecimalDigit

HexadecimalDigit
    = [0-9a-fA-F]

_ 'Whitespace'
  = !{ return isParsingObsolete; } [ \f\n\r\t\v]*
  / &{ return isParsingObsolete; } ([ \f\r\t\v] / '\n' [ \f\n\r\t\v]* '#~')*

__ 'NonNewlineWhitespace'
  = [ \f\r\t\v]*
