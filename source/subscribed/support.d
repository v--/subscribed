/**
 * Various support functions.
 * Authors: Ianis G. Vasilev `<mail@ivasilev.net>`
 * Copyright: Copyright © 2016, Ianis G. Vasilev
 * License: BSL-1.0
 */
module subscribed.support;

/**
 * Checks whether an identifier is valid.
 *
 * Bugs:
 *  DMD v2.071 and derivatives do not provide a good way to check identifier validity without using a custom parser.
 *  Because this function is hackish, it is not recommended to rely on it.
 *  That means the user is responsible for providing strings that are valid identifiers.
 */
@safe bool isValidIdentifier(const string identifier) pure
{
    import std.algorithm: all;
    import std.uni: isNumber, isAlpha;

    return identifier.length > 0 &&
        !isNumber(identifier[0]) &&
        identifier.all!(chr => chr == '_' || isAlpha(chr) || isNumber(chr));
}

///
unittest
{
    assert(isValidIdentifier("name"));
    assert(isValidIdentifier("snake_case"));
    assert(isValidIdentifier("camelCase"));
    assert(isValidIdentifier("someNumbers01234"));

    assert(!isValidIdentifier(""));
    assert(!isValidIdentifier("01234"));
    assert(!isValidIdentifier("word word"));
    assert(!isValidIdentifier("word,word"));
    assert(!isValidIdentifier("word.word"));
    assert(!isValidIdentifier("word=word"));
    assert(!isValidIdentifier("word;word"));
    assert(!isValidIdentifier("word!word"));
}
