// ArdSim ardprep: turns an Arduino sketch (.ino) into a C++ file the way
// the Arduino IDE does before compiling:
//   - #include "Arduino.h" at the top;
//   - the other .ino files of the sketch folder after the main one, in
//     name order;
//   - prototypes of the sketch functions before the first function, so a
//     function can be called above its definition;
//   - #line directives, so compiler errors point at the .ino lines;
//   - debugger hooks (ardsim_debug.h): SIM_STEP before statements,
//     SimFrame in functions, Watch registration of variables;
//   - live arguments: SIM_ARG around the arguments of screen calls and
//     SimFontReg after extern font declarations (unIDE inspector changes
//     a font, color or number while the emulator runs).
// Usage: ardprep [-plain] [-fontlist file] [-fontdir dir] [-fontfile file]
//                sketch.ino output.cpp
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <map>
#include <regex>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iostream>
#include <set>
#include <sstream>
#include <string>
#include <vector>
#include <dirent.h>

static std::string readFile(const std::string &path)
{
  std::ifstream input(path.c_str(), std::ios::binary);
  std::stringstream buffer;
  buffer << input.rdbuf();
  return buffer.str();
}

// Same text with comments, string and char literals and preprocessor
// lines replaced by spaces (new lines kept), so offsets stay the same
static std::string maskSource(const std::string &text)
{
  std::string mask = text;
  size_t length = text.size();
  size_t pos = 0;
  bool lineStart = true;
  while (pos < length)
  {
    char current = text[pos];
    char next = pos + 1 < length ? text[pos + 1] : 0;
    if (current == '\n')
    {
      lineStart = true;
      pos++;
      continue;
    }
    if (lineStart && (current == ' ' || current == '\t'))
    {
      pos++;
      continue;
    }
    if (lineStart && current == '#')
    {
      // preprocessor line, with backslash continuation
      while (pos < length && text[pos] != '\n')
      {
        if (text[pos] == '\\' && pos + 1 < length && (text[pos + 1] == '\n' || text[pos + 1] == '\r'))
        {
          mask[pos] = ' ';
          pos++;
          while (pos < length && text[pos] != '\n')
            mask[pos++] = ' ';
          if (pos < length)
            pos++;
          continue;
        }
        mask[pos++] = ' ';
      }
      continue;
    }
    lineStart = false;
    if (current == '/' && next == '/')
    {
      while (pos < length && text[pos] != '\n')
        mask[pos++] = ' ';
      continue;
    }
    if (current == '/' && next == '*')
    {
      mask[pos++] = ' ';
      mask[pos++] = ' ';
      while (pos < length && !(text[pos] == '*' && pos + 1 < length && text[pos + 1] == '/'))
      {
        if (text[pos] != '\n')
          mask[pos] = ' ';
        pos++;
      }
      if (pos < length)
      {
        mask[pos++] = ' ';
        mask[pos++] = ' ';
      }
      continue;
    }
    if (current == '"' || current == '\'')
    {
      char quote = current;
      mask[pos++] = ' ';
      while (pos < length && text[pos] != quote && text[pos] != '\n')
      {
        if (text[pos] == '\\' && pos + 1 < length)
          mask[pos++] = ' ';
        mask[pos++] = ' ';
      }
      if (pos < length && text[pos] == quote)
        mask[pos++] = ' ';
      continue;
    }
    pos++;
  }
  return mask;
}

static std::string collapseSpaces(const std::string &text)
{
  std::string result;
  bool space = false;
  for (char value : text)
  {
    if (isspace((unsigned char)value))
    {
      space = !result.empty();
      continue;
    }
    if (space)
      result += ' ';
    space = false;
    result += value;
  }
  return result;
}

static bool hasWord(const std::string &text, const char *word)
{
  size_t wordLength = strlen(word);
  size_t pos = 0;
  while ((pos = text.find(word, pos)) != std::string::npos)
  {
    bool leftOk = pos == 0 || !(isalnum((unsigned char)text[pos - 1]) || text[pos - 1] == '_');
    size_t end = pos + wordLength;
    bool rightOk = end >= text.size() || !(isalnum((unsigned char)text[end]) || text[end] == '_');
    if (leftOk && rightOk)
      return true;
    pos = end;
  }
  return false;
}

static int lineOf(const std::string &text, size_t offset)
{
  int line = 1;
  for (size_t pos = 0; pos < offset && pos < text.size(); pos++)
    if (text[pos] == '\n')
      line++;
  return line;
}

struct Signature
{
  size_t Start;        // offset of the first char of the definition
  std::string Text;    // "int foo(int a, String b)"
};

// Top-level function definitions: "<type> <name>(<params>) [const] {"
static std::vector<Signature> findFunctions(const std::string &mask)
{
  std::vector<Signature> result;
  int depth = 0;
  size_t statementStart = 0;   // after the last ';' '}' '{' at depth 0
  int parenDepth = 0;
  for (size_t pos = 0; pos < mask.size(); pos++)
  {
    char current = mask[pos];
    if (current == '(')
      parenDepth++;
    else if (current == ')')
      parenDepth--;
    if (depth == 0 && parenDepth == 0 && current == ';')
      statementStart = pos + 1;
    if (current == '{')
    {
      if (depth == 0)
      {
        std::string head = mask.substr(statementStart, pos - statementStart);
        size_t closeParen = head.find_last_not_of(" \t\r\n");
        // allow "const" after the parameter list
        std::string trimmed = head.substr(0, closeParen == std::string::npos ? 0 : closeParen + 1);
        if (trimmed.size() > 5 && trimmed.compare(trimmed.size() - 5, 5, "const") == 0)
          trimmed = trimmed.substr(0, trimmed.find_last_not_of(" \t\r\n", trimmed.size() - 6) + 1);
        if (!trimmed.empty() && trimmed.back() == ')')
        {
          // find the matching '('
          int level = 0;
          size_t openParen = std::string::npos;
          for (size_t back = trimmed.size(); back-- > 0;)
          {
            if (trimmed[back] == ')')
              level++;
            else if (trimmed[back] == '(' && --level == 0)
            {
              openParen = back;
              break;
            }
          }
          std::string params = openParen == std::string::npos ? "" : trimmed.substr(openParen);
          std::string before = openParen == std::string::npos ? "" : trimmed.substr(0, openParen);
          std::string flat = collapseSpaces(before);
          bool isFunction = !flat.empty() && flat.find(' ') != std::string::npos &&
            flat.find('=') == std::string::npos && flat.find("::") == std::string::npos &&
            params.find('=') == std::string::npos &&   // default arguments: skip
            !hasWord(flat, "struct") && !hasWord(flat, "class") && !hasWord(flat, "enum") &&
            !hasWord(flat, "union") && !hasWord(flat, "namespace") && !hasWord(flat, "template") &&
            !hasWord(flat, "typedef") && !hasWord(flat, "extern");
          if (isFunction)
          {
            char last = flat.back();
            isFunction = isalnum((unsigned char)last) || last == '_';
          }
          if (isFunction)
          {
            size_t first = statementStart;
            while (first < pos && isspace((unsigned char)mask[first]))
              first++;
            Signature signature;
            signature.Start = first;
            signature.Text = collapseSpaces(trimmed);
            result.push_back(signature);
          }
        }
      }
      depth++;
    }
    else if (current == '}')
    {
      depth--;
      if (depth == 0)
        statementStart = pos + 1;
    }
  }
  return result;
}

static std::string escapePath(const std::string &path)
{
  std::string result;
  for (char value : path)
  {
    if (value == '\\')
      result += "\\\\";
    else if (value == '"')
      result += "\\\"";
    else
      result += value;
  }
  return result;
}

// ---------------------------------------------------------------- tokens
enum TokenKind
{
  TokIdent,
  TokNumber,
  TokPunct
};

struct Token
{
  size_t Start, End;   // offsets in the text
  TokenKind Kind;
  std::string Text;
};

// Tokens of the masked text (comments, literals and preprocessor lines
// are spaces there). "::" and "->" are one token, other punctuation - one
// char each.
static std::vector<Token> tokenize(const std::string &mask)
{
  std::vector<Token> result;
  size_t pos = 0, length = mask.size();
  while (pos < length)
  {
    unsigned char current = (unsigned char)mask[pos];
    if (isspace(current))
    {
      pos++;
      continue;
    }
    Token token;
    token.Start = pos;
    if (isalpha(current) || current == '_' || current >= 0x80)
    {
      while (pos < length && (isalnum((unsigned char)mask[pos]) || mask[pos] == '_' ||
                              (unsigned char)mask[pos] >= 0x80))
        pos++;
      token.Kind = TokIdent;
    }
    else if (isdigit(current) || (current == '.' && pos + 1 < length && isdigit((unsigned char)mask[pos + 1])))
    {
      while (pos < length && (isalnum((unsigned char)mask[pos]) || mask[pos] == '.' || mask[pos] == '_' ||
                              ((mask[pos] == '+' || mask[pos] == '-') &&
                               (mask[pos - 1] == 'e' || mask[pos - 1] == 'E'))))
        pos++;
      token.Kind = TokNumber;
    }
    else
    {
      token.Kind = TokPunct;
      if (pos + 1 < length && ((current == ':' && mask[pos + 1] == ':') ||
                               (current == '-' && mask[pos + 1] == '>')))
        pos += 2;
      else
        pos++;
    }
    token.End = pos;
    token.Text = mask.substr(token.Start, token.End - token.Start);
    result.push_back(token);
  }
  return result;
}

// ---------------------------------------------------------------- instrumenter
// Debugger hooks (ArdSim/include/ardsim_debug.h): SIM_STEP before each
// statement of a function body, SimFrame at the start of a body, Watch
// registration after variable declarations. Inserted text has no line
// breaks, so the #line numbers stay right.
struct Insertion
{
  size_t Offset;
  std::string Text;
};

class Instrumenter
{
public:
  Instrumenter(const std::string &text, const std::vector<Token> &tokens, int fileIndex,
               int &counter, std::vector<Insertion> &insertions)
    : Text(text), Tokens(tokens), FileIndex(fileIndex), Counter(counter), Out(insertions)
  {
    LineStarts.push_back(0);
    for (size_t pos = 0; pos < text.size(); pos++)
      if (text[pos] == '\n')
        LineStarts.push_back(pos + 1);
  }
  void run(int &functionCount, int &globalCount);

private:
  const std::string &Text;
  const std::vector<Token> &Tokens;
  int FileIndex;
  int &Counter;
  std::vector<Insertion> &Out;
  std::vector<size_t> LineStarts;
  size_t Limit = 0;       // end of the function body being parsed (index of '}')
  bool Failed = false;
  // goto targets of the function: a block around one gets no local Watch
  // registration (a goto past an object with a constructor is an error)
  std::vector<size_t> GotoLabels;

  bool isPunct(size_t index, const char *text) const
  {
    return index < Tokens.size() && Tokens[index].Kind == TokPunct && Tokens[index].Text == text;
  }
  bool isWord(size_t index, const char *text) const
  {
    return index < Tokens.size() && Tokens[index].Kind == TokIdent && Tokens[index].Text == text;
  }
  int lineAt(size_t offset) const
  {
    size_t low = 0, high = LineStarts.size();
    while (high - low > 1)
    {
      size_t middle = (low + high) / 2;
      if (LineStarts[middle] <= offset)
        low = middle;
      else
        high = middle;
    }
    return (int)low + 1;
  }
  void insert(size_t offset, const std::string &text)
  {
    Insertion item;
    item.Offset = offset;
    item.Text = text;
    Out.push_back(item);
  }
  void step(size_t index)
  {
    insert(Tokens[index].Start, "SIM_STEP(" + std::to_string(FileIndex) + "," +
           std::to_string(lineAt(Tokens[index].Start)) + "); ");
  }
  size_t matching(size_t index) const;
  size_t skipParens(size_t index);
  size_t parseBlock(size_t index, bool inSwitch);
  size_t parseSub(size_t index, const std::string &prefix = std::string());
  size_t parseLoopBody(size_t index, size_t loopToken, size_t condOpen, const std::string &prefix);
  std::string paramRegistration(size_t openParen, size_t closeParen);
  size_t parseStatement(size_t index, bool allowLocals);
  size_t parseSimple(size_t index, bool allowLocals);
  bool labelAt(size_t index, size_t &next) const;
  struct Declarator
  {
    std::string Name;
    bool IsArray;
  };
  bool declaration(size_t first, size_t last, bool global, std::vector<Declarator> &names) const;
  std::string registration(const std::vector<Declarator> &names, bool global);
  void instrumentBody(size_t open, size_t close, const std::string &name, size_t openParen);
};

static bool isKeyword(const std::string &word)
{
  static const char *Words[] = {
    "return", "delete", "throw", "goto", "case", "default", "else", "new", "break",
    "continue", "do", "if", "for", "while", "switch", "sizeof", "typedef", "using",
    "template", "operator", "asm", "this", "try", "catch", "true", "false", "nullptr",
    "extern", "friend", "static_assert", "namespace", "public", "private", "protected",
    "alignof", "decltype", "typeid", "co_return", "co_await", "co_yield", nullptr};
  for (int index = 0; Words[index]; index++)
    if (word == Words[index])
      return true;
  return false;
}

// Index of the bracket that closes the one at index; Tokens.size() if none
size_t Instrumenter::matching(size_t index) const
{
  int depth = 0;
  for (size_t pos = index; pos < Tokens.size(); pos++)
  {
    const Token &token = Tokens[pos];
    if (token.Kind != TokPunct)
      continue;
    char value = token.Text[0];
    if (token.Text.size() != 1)
      continue;
    if (value == '(' || value == '[' || value == '{')
      depth++;
    else if (value == ')' || value == ']' || value == '}')
    {
      depth--;
      if (depth == 0)
        return pos;
    }
  }
  return Tokens.size();
}

// index - at '(' ; returns the index after ')'
size_t Instrumenter::skipParens(size_t index)
{
  if (!isPunct(index, "("))
  {
    Failed = true;
    return Limit;
  }
  size_t close = matching(index);
  if (close >= Limit)
  {
    Failed = true;
    return Limit;
  }
  return close + 1;
}

// "name :" (goto label) or "case ... :" / "default :"; next - after ':'
bool Instrumenter::labelAt(size_t index, size_t &next) const
{
  if (isWord(index, "case"))
  {
    int depth = 0;
    for (size_t pos = index + 1; pos < Limit; pos++)
    {
      const Token &token = Tokens[pos];
      if (token.Kind == TokPunct && token.Text.size() == 1)
      {
        char value = token.Text[0];
        if (value == '(' || value == '[' || value == '{')
          depth++;
        else if (value == ')' || value == ']' || value == '}')
          depth--;
        else if (value == ':' && depth == 0)
        {
          next = pos + 1;
          return true;
        }
        else if (value == ';')
          return false;
      }
    }
    return false;
  }
  if (isWord(index, "default") && isPunct(index + 1, ":"))
  {
    next = index + 2;
    return true;
  }
  if (index < Limit && Tokens[index].Kind == TokIdent && !isKeyword(Tokens[index].Text) &&
      isPunct(index + 1, ":") && !(isWord(index, "public") || isWord(index, "private")))
  {
    next = index + 2;
    return true;
  }
  return false;
}

// index - at '{' ; returns the index after '}'
size_t Instrumenter::parseBlock(size_t index, bool inSwitch)
{
  size_t pos = index + 1;
  size_t close = matching(index);
  bool allowLocals = !inSwitch;
  for (size_t label : GotoLabels)
    if (label > index && label < close)
      allowLocals = false;
  while (!Failed && pos < Limit && !isPunct(pos, "}"))
  {
    size_t next;
    if (labelAt(pos, next))
    {
      pos = next;
      continue;
    }
    pos = parseStatement(pos, allowLocals);
  }
  if (!isPunct(pos, "}"))
  {
    Failed = true;
    return Limit;
  }
  return pos + 1;
}

// Body of a loop: an empty one ("while (x);", "do {} while (x);") gets
// a SIM_STEP with the line of the loop, so pause stops in it.
// condOpen - "(" of the loop condition. When the condition has no calls
// (btnName == "---", flMetka == 0), only an interrupt can end the loop:
// simSpinWait() then lets the PC core rest until the next timer tick,
// tacho edge or key (a wait for a key took a whole core before)
// prefix - Watch registration of the for variable, at the start of the body
size_t Instrumenter::parseLoopBody(size_t index, size_t loopToken, size_t condOpen,
                                   const std::string &prefix)
{
  std::string loopStep = "SIM_STEP(" + std::to_string(FileIndex) + "," +
                         std::to_string(lineAt(Tokens[loopToken].Start)) + ");";
  if (condOpen < Limit && isPunct(condOpen, "("))
  {
    size_t close = matching(condOpen);
    bool plain = close > condOpen + 1 && close < Limit;
    for (size_t pos = condOpen + 1; plain && pos < close; pos++)
      if (isPunct(pos, "(") || isPunct(pos, "["))
        plain = false;
    if (plain)
      loopStep += " simSpinWait();";
  }
  if (isPunct(index, "{") && isPunct(index + 1, "}"))
  {
    insert(Tokens[index].End, prefix + " " + loopStep + " ");
    return index + 2;
  }
  if (isPunct(index, ";"))
  {
    insert(Tokens[index].Start, "{" + prefix + " " + loopStep + " }");
    return index + 1;
  }
  return parseSub(index, prefix);
}

// Parameters of a function: Watch registration at the start of its body
// (an array parameter is a pointer)
std::string Instrumenter::paramRegistration(size_t openParen, size_t closeParen)
{
  std::vector<Declarator> all;
  size_t first = openParen + 1;
  int depth = 0, angle = 0;
  for (size_t pos = openParen + 1; pos <= closeParen; pos++)
  {
    bool atEnd = pos == closeParen;
    if (!atEnd)
    {
      if (isPunct(pos, "(") || isPunct(pos, "[") || isPunct(pos, "{"))
        depth++;
      else if (isPunct(pos, ")") || isPunct(pos, "]") || isPunct(pos, "}"))
        depth--;
      else if (isPunct(pos, "<"))
        angle++;
      else if (isPunct(pos, ">") && angle > 0)
        angle--;
    }
    if (atEnd || (isPunct(pos, ",") && depth == 0 && angle == 0))
    {
      std::vector<Declarator> names;
      if (pos > first && declaration(first, pos, false, names))
        for (Declarator &item : names)
        {
          item.IsArray = false;
          all.push_back(item);
        }
      first = pos + 1;
    }
  }
  return all.empty() ? std::string() : registration(all, false);
}

// Body of if/else/for/while/do: braceless - wrapped into { }
size_t Instrumenter::parseSub(size_t index, const std::string &prefix)
{
  if (index >= Limit)
  {
    Failed = true;
    return Limit;
  }
  if (isPunct(index, "{"))
  {
    if (!prefix.empty())
      insert(Tokens[index].End, prefix);
    return parseBlock(index, false);
  }
  insert(Tokens[index].Start, "{" + prefix + " ");
  size_t pos = index, next;
  while (labelAt(pos, next))
    pos = next;
  // nested blocks check the goto labels themselves
  pos = parseStatement(pos, true);
  if (Failed)
    return Limit;
  insert(Tokens[pos - 1].End, " }");
  return pos;
}

size_t Instrumenter::parseStatement(size_t index, bool allowLocals)
{
  if (Failed || index >= Limit)
  {
    Failed = true;
    return Limit;
  }
  if (isPunct(index, "{"))
    return parseBlock(index, false);
  if (isPunct(index, ";"))
    return index + 1;
  if (isWord(index, "if"))
  {
    step(index);
    size_t pos = index + 1;
    if (isWord(pos, "constexpr"))
      pos++;
    pos = skipParens(pos);
    pos = parseSub(pos);
    if (isWord(pos, "else"))
      pos = parseSub(pos + 1);
    return pos;
  }
  if (isWord(index, "for") || isWord(index, "while"))
  {
    step(index);
    // for (int index = 0; ...) / for (auto &item : list): the variable
    // goes to Watch inside the body
    std::string prefix;
    if (isWord(index, "for") && isPunct(index + 1, "(") && allowLocals)
    {
      size_t close = matching(index + 1), initEnd = index + 2;
      int depth = 0;
      while (initEnd < close)
      {
        if (isPunct(initEnd, "(") || isPunct(initEnd, "[") || isPunct(initEnd, "{"))
          depth++;
        else if (isPunct(initEnd, ")") || isPunct(initEnd, "]") || isPunct(initEnd, "}"))
          depth--;
        else if (depth == 0 && (isPunct(initEnd, ";") || isPunct(initEnd, ":")))
          break;
        initEnd++;
      }
      std::vector<Declarator> names;
      if (initEnd < close && declaration(index + 2, initEnd, false, names))
      {
        for (Declarator &item : names)
          item.IsArray = false;
        prefix = registration(names, false);
      }
    }
    size_t pos = skipParens(index + 1);
    // for (;;) is no wait on a condition
    return parseLoopBody(pos, index, isWord(index, "while") ? index + 1 : Limit, prefix);
  }
  if (isWord(index, "switch"))
  {
    step(index);
    size_t pos = skipParens(index + 1);
    if (isPunct(pos, "{"))
      return parseBlock(pos, true);
    return parseSub(pos);
  }
  if (isWord(index, "do"))
  {
    step(index);
    // condition of an empty body: do {} while (x); / do ; while (x);
    size_t condOpen = Limit;
    if (isPunct(index + 1, "{") && isPunct(index + 2, "}") && isWord(index + 3, "while"))
      condOpen = index + 4;
    else if (isPunct(index + 1, ";") && isWord(index + 2, "while"))
      condOpen = index + 3;
    size_t pos = parseLoopBody(index + 1, index, condOpen, std::string());
    if (!isWord(pos, "while"))
    {
      Failed = true;
      return Limit;
    }
    pos = skipParens(pos + 1);
    if (!isPunct(pos, ";"))
    {
      Failed = true;
      return Limit;
    }
    return pos + 1;
  }
  if (isWord(index, "try"))
  {
    step(index);
    if (!isPunct(index + 1, "{"))
    {
      Failed = true;
      return Limit;
    }
    size_t pos = parseBlock(index + 1, false);
    while (isWord(pos, "catch"))
    {
      pos = skipParens(pos + 1);
      if (!isPunct(pos, "{"))
      {
        Failed = true;
        return Limit;
      }
      pos = parseBlock(pos, false);
    }
    return pos;
  }
  step(index);
  return parseSimple(index, allowLocals);
}

// Expression or declaration up to ';'
size_t Instrumenter::parseSimple(size_t index, bool allowLocals)
{
  int depth = 0;
  for (size_t pos = index; pos < Limit; pos++)
  {
    const Token &token = Tokens[pos];
    if (token.Kind != TokPunct || token.Text.size() != 1)
      continue;
    char value = token.Text[0];
    if (value == '(' || value == '[' || value == '{')
      depth++;
    else if (value == ')' || value == ']' || value == '}')
    {
      depth--;
      if (depth < 0)
        break;
    }
    else if (value == ';' && depth == 0)
    {
      if (allowLocals)
      {
        std::vector<Declarator> names;
        if (declaration(index, pos, false, names))
          insert(token.End, registration(names, false));
      }
      return pos + 1;
    }
  }
  Failed = true;
  return Limit;
}

// Tokens [first, last) - a variable declaration ("int a = 1, b[4];")?
// names - the declared variables
bool Instrumenter::declaration(size_t first, size_t last, bool global,
                               std::vector<Declarator> &names) const
{
  names.clear();
  if (first >= last || Tokens[first].Kind != TokIdent || isKeyword(Tokens[first].Text))
    return false;
  static const char *Skip[] = {"struct", "class", "enum", "union", "typedef", "using",
                               "template", "extern", "namespace", "friend", nullptr};
  for (int index = 0; Skip[index]; index++)
    if (isWord(first, Skip[index]))
      return false;
  // type: identifiers, "::", "*", "&", <...>; the name - the last
  // identifier before "=", "[", "(", "{", "," or the end
  size_t pos = first;
  int typeWords = 0;
  size_t nameIndex = last;
  while (pos < last)
  {
    const Token &token = Tokens[pos];
    if (token.Kind == TokIdent)
    {
      if (isKeyword(token.Text))
        return false;
      size_t next = pos + 1;
      bool endsHere = next >= last || isPunct(next, "=") || isPunct(next, "[") ||
                      isPunct(next, "(") || isPunct(next, "{") || isPunct(next, ",");
      if (endsHere && typeWords > 0)
      {
        nameIndex = pos;
        break;
      }
      typeWords++;
      pos++;
    }
    else if (isPunct(pos, "::") || isPunct(pos, "*") || isPunct(pos, "&"))
      pos++;
    else if (isPunct(pos, "<"))
    {
      int angle = 0;
      while (pos < last)
      {
        if (isPunct(pos, "<"))
          angle++;
        else if (isPunct(pos, ">"))
          angle--;
        else if (isPunct(pos, ";") || isPunct(pos, "{"))
          return false;
        pos++;
        if (angle == 0)
          break;
      }
      if (angle != 0)
        return false;
      typeWords++;
    }
    else
      return false;
  }
  if (nameIndex >= last)
    return false;
  pos = nameIndex;
  while (pos < last)
  {
    // pos - at the name
    if (Tokens[pos].Kind != TokIdent || isKeyword(Tokens[pos].Text))
      return false;
    Declarator item;
    item.Name = Tokens[pos].Text;
    item.IsArray = false;
    pos++;
    bool keep = true;
    if (isPunct(pos, "("))
    {
      // constructor arguments or a function declaration
      if (global)
        return false;
      keep = false;
      pos = matching(pos) + 1;
    }
    while (isPunct(pos, "["))
    {
      item.IsArray = true;
      pos = matching(pos) + 1;
    }
    if (pos < last && (isPunct(pos, "=") || isPunct(pos, "{")))
    {
      int depth = 0;
      while (pos < last)
      {
        const Token &token = Tokens[pos];
        if (token.Kind == TokPunct && token.Text.size() == 1)
        {
          char value = token.Text[0];
          if (value == '(' || value == '[' || value == '{')
            depth++;
          else if (value == ')' || value == ']' || value == '}')
            depth--;
          else if (value == ',' && depth == 0)
            break;
        }
        pos++;
      }
    }
    if (keep)
      names.push_back(item);
    if (pos >= last)
      break;
    if (!isPunct(pos, ","))
      return false;
    pos++;
    while (isPunct(pos, "*") || isPunct(pos, "&") || isWord(pos, "const"))
      pos++;
  }
  return !names.empty();
}

std::string Instrumenter::registration(const std::vector<Declarator> &names, bool global)
{
  std::string result;
  for (const Declarator &item : names)
  {
    std::string varName = (global ? "simW_" : "simL_") + std::to_string(++Counter) + "_";
    result += global ? " static SimWatchReg " : " SimLocalReg ";
    result += varName + "(\"" + item.Name + "\", ";
    if (item.IsArray)
      result += "&" + item.Name + "[0], sizeof(" + item.Name + ") / sizeof(" + item.Name + "[0]));";
    else
      result += item.Name + ");";
  }
  return result;
}

void Instrumenter::instrumentBody(size_t open, size_t close, const std::string &name, size_t openParen)
{
  size_t mark = Out.size();
  Limit = close;
  Failed = false;
  insert(Tokens[open].End, " SimFrame simFrame_(\"" + name + "\");" +
         paramRegistration(openParen, matching(openParen)));
  GotoLabels.clear();
  std::set<std::string> targets;
  for (size_t scan = open + 1; scan + 1 < close; scan++)
    if (isWord(scan, "goto") && Tokens[scan + 1].Kind == TokIdent)
      targets.insert(Tokens[scan + 1].Text);
  for (size_t scan = open + 1; scan + 1 < close; scan++)
    if (Tokens[scan].Kind == TokIdent && isPunct(scan + 1, ":") && targets.count(Tokens[scan].Text))
      GotoLabels.push_back(scan);
  bool topLocals = GotoLabels.empty();
  size_t pos = open + 1;
  while (!Failed && pos < close)
  {
    size_t next;
    if (labelAt(pos, next))
    {
      pos = next;
      continue;
    }
    pos = parseStatement(pos, topLocals);
  }
  if (Failed)
  {
    // not understood: the function stays as it is
    Out.resize(mark);
    std::cerr << "ardprep: " << name << " (line " << lineAt(Tokens[open].Start)
              << ") - not instrumented\n";
  }
}

// Top level: function bodies and global variables
void Instrumenter::run(int &functionCount, int &globalCount)
{
  size_t statementStart = 0;
  size_t pos = 0;
  while (pos < Tokens.size())
  {
    const Token &token = Tokens[pos];
    if (isPunct(pos, ";"))
    {
      std::vector<Declarator> names;
      Limit = Tokens.size();
      if (declaration(statementStart, pos, true, names))
      {
        insert(token.End, registration(names, true));
        globalCount += (int)names.size();
      }
      pos++;
      statementStart = pos;
      continue;
    }
    if (isPunct(pos, "{"))
    {
      size_t close = matching(pos);
      if (close >= Tokens.size())
        return;
      // function body: "... name ( ... ) [const] {"
      size_t before = pos;
      while (before > statementStart &&
             (isWord(before - 1, "const") || isWord(before - 1, "noexcept") ||
              isWord(before - 1, "override")))
        before--;
      bool isFunction = before > statementStart && isPunct(before - 1, ")");
      size_t nameIndex = 0;
      if (isFunction)
      {
        // '(' that matches; the name before it
        int depth = 0;
        size_t openParen = Tokens.size();
        for (size_t back = before; back-- > statementStart;)
        {
          if (isPunct(back, ")"))
            depth++;
          else if (isPunct(back, "(") && --depth == 0)
          {
            openParen = back;
            break;
          }
        }
        isFunction = openParen < Tokens.size() && openParen > statementStart &&
                     Tokens[openParen - 1].Kind == TokIdent && !isKeyword(Tokens[openParen - 1].Text);
        nameIndex = openParen - 1;
        for (size_t scan = statementStart; isFunction && scan < pos; scan++)
          if (isPunct(scan, "=") || isWord(scan, "constexpr") || isWord(scan, "struct") ||
              isWord(scan, "class") || isWord(scan, "enum") || isWord(scan, "union") ||
              isWord(scan, "namespace") || isWord(scan, "typedef"))
            isFunction = false;
      }
      if (isFunction)
      {
        std::string name = Tokens[nameIndex].Text;
        if (nameIndex >= statementStart + 2 && isPunct(nameIndex - 1, "::") &&
            Tokens[nameIndex - 2].Kind == TokIdent)
          name = Tokens[nameIndex - 2].Text + "::" + name;
        instrumentBody(pos, close, name, nameIndex + 1);
        functionCount++;
        pos = close + 1;
        statementStart = pos;
        continue;
      }
      // initializer ("= {...};") - the statement goes on to its ';';
      // struct/class/enum/namespace bodies are not instrumented
      bool initializer = false;
      for (size_t scan = statementStart; scan < pos; scan++)
        if (isPunct(scan, "="))
          initializer = true;
      pos = close + 1;
      if (!initializer && !isPunct(pos, ";") && !isPunct(pos, ","))
        statementStart = pos;
      continue;
    }
    pos++;
  }
}

// ---------------------------------------------------------------- files
// Other .ino files of the sketch folder, sorted, as the Arduino IDE adds
// them after the main one
// ---------------------------------------------------------------- live arguments
// The unIDE inspector changes an argument of a screen call while the
// emulator runs (ArdSimHost.pas, SetArgOverride): each argument that can
// take a number or a font is wrapped as
//   SIM_ARG(code, hash, occurrence, index, expression)
// and simArg() (ardsim_debug.h) gives the host's value for this place, or
// the expression. code = (file << 20) | line of the call (the object of a
// method), hash = FNV-1a of the method or function name, occurrence =
// calls of that name on the line before this one, index = argument from 0.
// Text arguments, references and other types are not wrapped.
// Inserted text has no line breaks: #line numbers stay right.
static uint32_t nameHash(const std::string &name)
{
  uint32_t hash = 2166136261u;
  for (unsigned char value : name)
  {
    hash ^= value;
    hash *= 16777619u;
  }
  return hash;
}

static std::vector<std::string> wordsOf(const std::string &text)
{
  std::vector<std::string> words;
  std::string word;
  for (char value : text)
  {
    if (isalnum((unsigned char)value) || value == '_')
      word += value;
    else if (!word.empty())
    {
      words.push_back(word);
      word.clear();
    }
  }
  if (!word.empty())
    words.push_back(word);
  return words;
}

// Parameter "int Left", "uint8_t Font[]", "uint16_t Color": a number or
// a font - wrapped; "String Caption", "int &x", "char *s" - not
static bool wrappableParam(const std::string &param)
{
  if (param.find('&') != std::string::npos || param.find('(') != std::string::npos)
    return false;
  std::vector<std::string> words = wordsOf(param);
  bool pointer = param.find('*') != std::string::npos || param.find('[') != std::string::npos;
  static const char *Numbers[] = {
    "int", "long", "short", "byte", "word", "unsigned", "signed", "char", "float", "double",
    "bool", "boolean", "uint8_t", "int8_t", "uint16_t", "int16_t", "uint32_t", "int32_t",
    "uint64_t", "int64_t", "size_t", nullptr};
  // the last word is the name (an unnamed parameter has none: then all are type words)
  size_t typeWords = words.size() > 1 ? words.size() - 1 : words.size();
  if (pointer)
  {
    for (size_t index = 0; index < typeWords; index++)
      if (words[index] == "uint8_t" || words[index] == "fontdatatype")
        return true;
    return false;
  }
  for (size_t index = 0; index < typeWords; index++)
    for (int number = 0; Numbers[number]; number++)
      if (words[index] == Numbers[number])
        return true;
  return false;
}

// "void Label(int Left, String Caption)" -> name and per parameter: wrap
static bool signatureParams(const std::string &text, std::string &name, std::vector<bool> &wrap)
{
  size_t open = text.find('(');
  size_t close = text.rfind(')');
  if (open == std::string::npos || close == std::string::npos || close < open)
    return false;
  std::vector<std::string> before = wordsOf(text.substr(0, open));
  if (before.empty())
    return false;
  name = before.back();
  std::string params = text.substr(open + 1, close - open - 1);
  wrap.clear();
  if (wordsOf(params).empty() || collapseSpaces(params) == "void")
    return true;
  int depth = 0;
  std::string current;
  for (char value : params)
  {
    if (value == '(' || value == '[' || value == '<')
      depth++;
    else if (value == ')' || value == ']' || value == '>')
      depth--;
    if (value == ',' && depth == 0)
    {
      wrap.push_back(wrappableParam(current));
      current.clear();
    }
    else
      current += value;
  }
  wrap.push_back(wrappableParam(current));
  return true;
}

// UTFT methods: which arguments take numbers (text and bitmap data - not)
static bool methodArgs(const std::string &method, size_t count, std::vector<bool> &wrap)
{
  wrap.assign(count, true);
  if (method == "setColor" || method == "setBackColor" || method == "setFont" ||
      method == "drawLine" || method == "drawRect" || method == "fillRect" ||
      method == "drawRoundRect" || method == "fillRoundRect" || method == "drawCircle" ||
      method == "fillCircle" || method == "drawPixel" || method == "fillScr" ||
      method == "drawHLine" || method == "drawVLine")
    return true;
  if (method == "print" || method == "printChar")
  {
    if (count > 0)
      wrap[0] = false;   // text
    return true;
  }
  if (method == "printNumI" || method == "printNumF")
  {
    // printNumI(num, x, y, ...), printNumF(num, dec, x, y, ...): x, y only
    size_t first = method == "printNumI" ? 1 : 2;
    for (size_t index = 0; index < count; index++)
      wrap[index] = index == first || index == first + 1;
    return true;
  }
  if (method == "drawBitmap")
  {
    if (count > 4)
      wrap[4] = false;   // data
    return true;
  }
  return false;
}

class ArgWrapper
{
public:
  ArgWrapper(const std::string &text, const std::vector<Token> &tokens, int fileIndex,
             const std::map<std::string, std::vector<std::vector<bool>>> &functions,
             const std::set<std::string> &screens, std::vector<Insertion> &out)
    : Tokens(tokens), FileIndex(fileIndex), Functions(functions), Screens(screens), Out(out)
  {
    LineStarts.push_back(0);
    for (size_t pos = 0; pos < text.size(); pos++)
      if (text[pos] == '\n')
        LineStarts.push_back(pos + 1);
  }
  int run();

private:
  const std::vector<Token> &Tokens;
  int FileIndex;
  const std::map<std::string, std::vector<std::vector<bool>>> &Functions;
  const std::set<std::string> &Screens;
  std::vector<Insertion> &Out;
  std::vector<size_t> LineStarts;

  bool punct(size_t index, const char *text) const
  {
    return index < Tokens.size() && Tokens[index].Kind == TokPunct && Tokens[index].Text == text;
  }
  int lineAt(size_t offset) const
  {
    size_t low = 0, high = LineStarts.size();
    while (high - low > 1)
    {
      size_t middle = (low + high) / 2;
      if (LineStarts[middle] <= offset)
        low = middle;
      else
        high = middle;
    }
    return (int)low + 1;
  }
};

int ArgWrapper::run()
{
  int wrapped = 0;
  int depth = 0;
  std::map<std::pair<int, std::string>, int> seen;   // (line, name) -> calls so far
  for (size_t index = 0; index < Tokens.size(); index++)
  {
    if (punct(index, "{"))
    {
      depth++;
      continue;
    }
    if (punct(index, "}"))
    {
      depth--;
      continue;
    }
    if (depth <= 0 || Tokens[index].Kind != TokIdent || !punct(index + 1, "("))
      continue;
    const std::string &name = Tokens[index].Text;
    size_t callStart = index;
    bool method = false;
    if (index >= 2 && punct(index - 1, ".") && Tokens[index - 2].Kind == TokIdent &&
        Screens.count(Tokens[index - 2].Text))
    {
      method = true;
      callStart = index - 2;
    }
    else if (index >= 1 && (punct(index - 1, ".") || punct(index - 1, "->") || punct(index - 1, "::")))
      continue;
    else if (!Functions.count(name))
      continue;
    int line = lineAt(Tokens[callStart].Start);
    int occurrence = seen[std::make_pair(line, name)]++;
    // arguments: token ranges at depth 0 of the call's parentheses
    std::vector<std::pair<size_t, size_t>> args;
    int level = 0;
    size_t argFirst = index + 2;
    size_t close = Tokens.size();
    for (size_t scan = index + 1; scan < Tokens.size(); scan++)
    {
      const Token &token = Tokens[scan];
      if (token.Kind == TokPunct && (token.Text == "(" || token.Text == "[" || token.Text == "{"))
        level++;
      else if (token.Kind == TokPunct && (token.Text == ")" || token.Text == "]" || token.Text == "}"))
      {
        level--;
        if (level == 0)
        {
          close = scan;
          if (scan > argFirst)
            args.push_back(std::make_pair(argFirst, scan - 1));
          break;
        }
      }
      else if (level == 1 && token.Kind == TokPunct && token.Text == ",")
      {
        args.push_back(std::make_pair(argFirst, scan - 1));
        argFirst = scan + 1;
      }
      else if (level == 1 && token.Kind == TokPunct && token.Text == ";")
        break;   // not a call after all
    }
    if (close >= Tokens.size())
      continue;
    std::vector<bool> wrap;
    if (method)
    {
      if (!methodArgs(name, args.size(), wrap))
        continue;
    }
    else
    {
      // overloads: those with this number of parameters; an argument is
      // wrapped only when every such overload takes a number or font there
      bool found = false;
      for (const std::vector<bool> &params : Functions.at(name))
        if (params.size() == args.size())
        {
          if (!found)
            wrap = params;
          else
            for (size_t arg = 0; arg < wrap.size(); arg++)
              wrap[arg] = wrap[arg] && params[arg];
          found = true;
        }
      if (!found)
        continue;
    }
    std::string head = "SIM_ARG(" + std::to_string((FileIndex << 20) | line) + "," +
                       std::to_string(nameHash(name)) + "u," + std::to_string(occurrence) + ",";
    for (size_t arg = 0; arg < args.size(); arg++)
    {
      if (!wrap[arg] || args[arg].first > args[arg].second)
        continue;
      // a braced list has no type to deduce
      if (punct(args[arg].first, "{"))
        continue;
      Insertion open, end;
      open.Offset = Tokens[args[arg].first].Start;
      open.Text = head + std::to_string(arg) + ",";
      end.Offset = Tokens[args[arg].second].End;
      end.Text = ")";
      Out.push_back(open);
      Out.push_back(end);
      wrapped++;
    }
  }
  return wrapped;
}

// Sketch functions that draw on the screen: a UTFT method in the body or
// a call of another such function. Only their calls get SIM_ARG - helper
// functions (math, SD, serial) stay as they are.
static void drawingFunctions(const std::vector<std::string> &masks, const std::set<std::string> &screens,
                             const std::map<std::string, std::vector<std::vector<bool>>> &known,
                             std::set<std::string> &drawing)
{
  std::map<std::string, std::set<std::string>> callees;
  for (const std::string &mask : masks)
  {
    std::vector<Token> tokens = tokenize(mask);
    for (size_t index = 0; index < tokens.size(); index++)
    {
      if (!(tokens[index].Kind == TokPunct && tokens[index].Text == "{"))
        continue;
      // "name ( ... ) [const] {" at the top level
      size_t before = index;
      while (before > 0 && tokens[before - 1].Kind == TokIdent && tokens[before - 1].Text == "const")
        before--;
      if (before == 0 || tokens[before - 1].Text != ")")
        continue;
      int level = 0;
      size_t open = tokens.size();
      for (size_t back = before; back-- > 0;)
      {
        if (tokens[back].Text == ")")
          level++;
        else if (tokens[back].Text == "(" && --level == 0)
        {
          open = back;
          break;
        }
      }
      if (open == tokens.size() || open == 0 || tokens[open - 1].Kind != TokIdent)
        continue;
      std::string name = tokens[open - 1].Text;
      int depth = 0;
      size_t scan = index;
      std::set<std::string> &calls = callees[name];
      for (; scan < tokens.size(); scan++)
      {
        const Token &token = tokens[scan];
        if (token.Kind == TokPunct && token.Text == "{")
          depth++;
        else if (token.Kind == TokPunct && token.Text == "}")
        {
          if (--depth == 0)
            break;
        }
        else if (token.Kind == TokIdent && scan + 2 < tokens.size() && screens.count(token.Text) &&
                 tokens[scan + 1].Text == "." && tokens[scan + 2].Kind == TokIdent)
          drawing.insert(name);
        else if (token.Kind == TokIdent && scan + 1 < tokens.size() && tokens[scan + 1].Text == "(" &&
                 known.count(token.Text))
          calls.insert(token.Text);
      }
      index = scan;   // bodies of the top level only
    }
  }
  bool changed = true;
  while (changed)
  {
    changed = false;
    for (const auto &item : callees)
      if (!drawing.count(item.first))
        for (const std::string &callee : item.second)
          if (drawing.count(callee))
          {
            drawing.insert(item.first);
            changed = true;
            break;
          }
  }
}

// Objects declared "UTFT name(...)" in the sketch
static void collectScreens(const std::vector<Token> &tokens, std::set<std::string> &screens)
{
  for (size_t index = 0; index + 1 < tokens.size(); index++)
    if (tokens[index].Kind == TokIdent && tokens[index].Text == "UTFT" &&
        tokens[index + 1].Kind == TokIdent)
      screens.insert(tokens[index + 1].Text);
}

// Font arrays that the build links: "Name[...] =" in the .c files the
// build compiles (sketch folder, %ARDSIM_FONTS%, unIDE list, stand-ins)
static void collectFontArrays(const std::vector<std::string> &files, std::set<std::string> &arrays)
{
  for (const std::string &file : files)
  {
    std::string text = maskSource(readFile(file));
    std::vector<Token> tokens = tokenize(text);
    for (size_t index = 0; index + 1 < tokens.size(); index++)
      if (tokens[index].Kind == TokIdent && tokens[index + 1].Kind == TokPunct &&
          tokens[index + 1].Text == "[")
      {
        size_t scan = index + 2;
        while (scan < tokens.size() && !(tokens[scan].Kind == TokPunct && tokens[scan].Text == "]"))
          scan++;
        if (scan + 1 < tokens.size() && tokens[scan + 1].Kind == TokPunct && tokens[scan + 1].Text == "=")
          arrays.insert(tokens[index].Text);
      }
  }
}

static void listFolder(const std::string &folder, std::vector<std::string> &files)
{
  if (folder.empty())
    return;
  DIR *dir = opendir(folder.c_str());
  if (!dir)
    return;
  std::vector<std::string> names;
  while (dirent *entry = readdir(dir))
  {
    std::string name = entry->d_name;
    if (name.size() > 2 && name.compare(name.size() - 2, 2, ".c") == 0)
      names.push_back(name);
  }
  closedir(dir);
  std::sort(names.begin(), names.end());
  char separator = folder.find('\\') != std::string::npos ? '\\' : '/';
  std::string prefix = folder;
  if (prefix.back() != '\\' && prefix.back() != '/')
    prefix += separator;
  for (const std::string &name : names)
    files.push_back(prefix + name);
}

// "extern uint8_t Name[];" (or fontdatatype) at the top level: after it
// "static SimFontReg ...("Name", Name);" when the build links Name, so
// the host can switch a font by its name
static int registerFonts(const std::vector<Token> &tokens, int fileIndex,
                         const std::set<std::string> &arrays, std::vector<Insertion> &out)
{
  int count = 0;
  int depth = 0;
  for (size_t index = 0; index + 5 < tokens.size(); index++)
  {
    const Token &token = tokens[index];
    if (token.Kind == TokPunct && token.Text == "{")
      depth++;
    else if (token.Kind == TokPunct && token.Text == "}")
      depth--;
    if (depth != 0 || token.Kind != TokIdent || token.Text != "extern")
      continue;
    size_t scan = index + 1;
    if (tokens[scan].Kind == TokIdent && tokens[scan].Text == "const")
      scan++;
    if (scan + 4 >= tokens.size() || tokens[scan].Kind != TokIdent ||
        (tokens[scan].Text != "uint8_t" && tokens[scan].Text != "fontdatatype"))
      continue;
    const Token &nameToken = tokens[scan + 1];
    if (nameToken.Kind != TokIdent || tokens[scan + 2].Text != "[" || tokens[scan + 3].Text != "]" ||
        tokens[scan + 4].Text != ";" || !arrays.count(nameToken.Text))
      continue;
    Insertion item;
    item.Offset = tokens[scan + 4].End;
    item.Text = " static SimFontReg simFontReg" + std::to_string(fileIndex) + "_" +
                std::to_string(count) + "_(\"" + nameToken.Text + "\", " + nameToken.Text + ");";
    out.push_back(item);
    count++;
  }
  return count;
}

static std::vector<std::string> sketchFiles(const std::string &mainPath)
{
  std::vector<std::string> result;
  result.push_back(mainPath);
  size_t slash = mainPath.find_last_of("\\/");
  std::string dir = slash == std::string::npos ? std::string(".") : mainPath.substr(0, slash);
  std::string mainName = slash == std::string::npos ? mainPath : mainPath.substr(slash + 1);
  char separator = slash == std::string::npos ? '/' : mainPath[slash];
  std::vector<std::string> others;
  DIR *folder = opendir(dir.c_str());
  if (folder)
  {
    while (dirent *entry = readdir(folder))
    {
      std::string name = entry->d_name;
      if (name.size() < 5)
        continue;
      std::string ext = name.substr(name.size() - 4);
      for (char &value : ext)
        value = (char)tolower((unsigned char)value);
      if (ext != ".ino")
        continue;
      std::string lower = name, lowerMain = mainName;
      for (char &value : lower)
        value = (char)tolower((unsigned char)value);
      for (char &value : lowerMain)
        value = (char)tolower((unsigned char)value);
      if (lower == lowerMain)
        continue;
      others.push_back(name);
    }
    closedir(folder);
  }
  std::sort(others.begin(), others.end());
  for (const std::string &name : others)
    result.push_back(slash == std::string::npos ? name : dir + separator + name);
  return result;
}

// Live controls: "TLabel name = {...}" in the sketch's own #include "..."
// files (BS10Forms.h) -> SimCtlReg registrations (the class comes from the
// control header, BS10Controls.h)
static std::string controlRegistrations(const std::vector<std::string> &texts,
                                        const std::string &folder, int &count)
{
  std::string result;
  std::set<std::string> seenFiles, seenNames;
  std::regex includeLine("^[ \\t]*#[ \\t]*include[ \\t]*\"([^\"]+)\"");
  std::regex labelDecl("\\bTLabel[ \\t\\r\\n]+([A-Za-z_][A-Za-z0-9_]*)[ \\t\\r\\n]*=[ \\t\\r\\n]*\\{");
  for (const std::string &text : texts)
  {
    std::istringstream lines(text);
    std::string line;
    while (std::getline(lines, line))
    {
      std::smatch found;
      if (!std::regex_search(line, found, includeLine) || !seenFiles.insert(found[1]).second)
        continue;
      std::string header = readFile(folder + "/" + found[1].str());
      if (header.empty())
        continue;
      std::string mask = maskSource(header);
      for (std::sregex_iterator item(mask.begin(), mask.end(), labelDecl), end; item != end; ++item)
      {
        std::string name = (*item)[1];
        if (!seenNames.insert(name).second)
          continue;
        result += "static SimCtlReg simCtl" + std::to_string(count) + "_(\"" + name + "\", &" + name + ");\n";
        count++;
      }
    }
  }
  // a control header that does not define SimCtlReg (an older one): no
  // registrations, the sketch still builds
  if (!result.empty())
    result = "#ifdef SIM_CTL_REG_DEFINED\n" + result + "#endif\n";
  return result;
}

static std::string applyInsertions(const std::string &text, std::vector<Insertion> &insertions)
{
  std::stable_sort(insertions.begin(), insertions.end(),
                   [](const Insertion &left, const Insertion &right) { return left.Offset < right.Offset; });
  std::string result;
  size_t done = 0;
  for (const Insertion &item : insertions)
  {
    result += text.substr(done, item.Offset - done);
    result += item.Text;
    done = item.Offset;
  }
  result += text.substr(done);
  return result;
}

int main(int argc, char **argv)
{
  bool instrument = true;
  std::vector<std::string> args;
  std::vector<std::string> fontFiles;   // .c files with fonts the build compiles
  for (int index = 1; index < argc; index++)
  {
    if (strcmp(argv[index], "-plain") == 0)
      instrument = false;
    else if (strcmp(argv[index], "-fontlist") == 0 && index + 1 < argc)
    {
      std::ifstream list(argv[++index]);
      std::string line;
      while (std::getline(list, line))
      {
        while (!line.empty() && (line.back() == '\r' || line.back() == ' '))
          line.pop_back();
        if (!line.empty())
          fontFiles.push_back(line);
      }
    }
    else if (strcmp(argv[index], "-fontdir") == 0 && index + 1 < argc)
      listFolder(argv[++index], fontFiles);
    else if (strcmp(argv[index], "-fontfile") == 0 && index + 1 < argc)
      fontFiles.push_back(argv[++index]);
    else
      args.push_back(argv[index]);
  }
  if (args.size() < 2)
  {
    std::cerr << "usage: ardprep [-plain] sketch.ino output.cpp\n"
                 "  other .ino files of the folder are added after the main one;\n"
                 "  -plain: without the debugger hooks\n";
    return 2;
  }
  std::vector<std::string> files = sketchFiles(args[0]);
  {
    size_t slash = args[0].find_last_of("\\/");
    listFolder(slash == std::string::npos ? std::string(".") : args[0].substr(0, slash), fontFiles);
    const char *envFonts = getenv("ARDSIM_FONTS");
    if (envFonts)
      listFolder(envFonts, fontFiles);
  }
  std::set<std::string> fontArrays;
  collectFontArrays(fontFiles, fontArrays);
  int argTotal = 0, fontRegTotal = 0;
  std::string output = "#include \"Arduino.h\"\n";
  std::string registrations;
  int counter = 0, functionTotal = 0, globalTotal = 0, prototypeTotal = 0;
  std::vector<Signature> allFunctions;
  std::vector<std::string> texts, masks;
  for (size_t fileIndex = 0; fileIndex < files.size(); fileIndex++)
  {
    std::string text = readFile(files[fileIndex]);
    if (text.empty() && fileIndex == 0)
    {
      std::cerr << "ardprep: cannot read " << files[fileIndex] << "\n";
      return 1;
    }
    if (!text.empty() && text.back() != '\n')
      text += '\n';
    std::string mask = maskSource(text);
    std::vector<Signature> functions = findFunctions(mask);
    allFunctions.insert(allFunctions.end(), functions.begin(), functions.end());
    texts.push_back(text);
    masks.push_back(mask);
  }
  // live arguments: sketch functions (parameters that take numbers or
  // fonts) and UTFT objects of all files
  std::map<std::string, std::vector<std::vector<bool>>> wrapFunctions;
  std::set<std::string> screens;
  if (instrument)
  {
    for (const Signature &function : allFunctions)
    {
      std::string name;
      std::vector<bool> wrap;
      if (signatureParams(function.Text, name, wrap) && !wrap.empty() &&
          name != "setup" && name != "loop")
        wrapFunctions[name].push_back(wrap);
    }
    for (const std::string &mask : masks)
      collectScreens(tokenize(mask), screens);
    std::map<std::string, std::vector<std::vector<bool>>> allKnown;
    for (const Signature &function : allFunctions)
    {
      std::string name;
      std::vector<bool> wrap;
      if (signatureParams(function.Text, name, wrap))
        allKnown[name].push_back(wrap);
    }
    std::set<std::string> drawing;
    drawingFunctions(masks, screens, allKnown, drawing);
    for (auto item = wrapFunctions.begin(); item != wrapFunctions.end();)
      if (drawing.count(item->first))
        ++item;
      else
        item = wrapFunctions.erase(item);
  }
  for (size_t fileIndex = 0; fileIndex < files.size(); fileIndex++)
  {
    const std::string &text = texts[fileIndex];
    std::string lineName = "\"" + escapePath(files[fileIndex]) + "\"";
    std::vector<Insertion> insertions;
    if (instrument)
    {
      std::vector<Token> tokens = tokenize(masks[fileIndex]);
      Instrumenter instrumenter(text, tokens, (int)fileIndex, counter, insertions);
      instrumenter.run(functionTotal, globalTotal);
      ArgWrapper wrapper(text, tokens, (int)fileIndex, wrapFunctions, screens, insertions);
      argTotal += wrapper.run();
      fontRegTotal += registerFonts(tokens, (int)fileIndex, fontArrays, insertions);
      registrations += "static SimFileReg simFile" + std::to_string(fileIndex) + "_(" +
                       std::to_string(fileIndex) + ", " + lineName + ");\n";
    }
    output += "#line 1 " + lineName + "\n";
    if (fileIndex == 0 && !allFunctions.empty())
    {
      // prototypes of the functions of all files: before the first
      // function of the main file (at the start of its line), or at its
      // end if it has none
      std::vector<Signature> mainFunctions = findFunctions(masks[0]);
      size_t insertAt = mainFunctions.empty() ? text.size() : mainFunctions[0].Start;
      while (insertAt > 0 && text[insertAt - 1] != '\n')
        insertAt--;
      std::set<std::string> seen;
      std::string block = "// prototypes (ardprep)\n";
      for (const Signature &function : allFunctions)
        if (seen.insert(function.Text).second)
        {
          block += function.Text + ";\n";
          prototypeTotal++;
        }
      block += "#line " + std::to_string(lineOf(text, insertAt)) + " " + lineName + "\n";
      Insertion item;
      item.Offset = insertAt;
      item.Text = block;
      insertions.push_back(item);
    }
    output += applyInsertions(text, insertions);
  }
  int controlTotal = 0;
  if (instrument)
  {
    size_t slash = args[0].find_last_of("\\/");
    output += controlRegistrations(texts, slash == std::string::npos ? std::string(".")
                                                                    : args[0].substr(0, slash),
                                   controlTotal);
  }
  output += registrations;
  std::ofstream result(args[1].c_str(), std::ios::binary);
  result << output;
  if (!result)
  {
    std::cerr << "ardprep: cannot write " << args[1] << "\n";
    return 1;
  }
  std::cout << "ardprep: " << files.size() << " file(s), " << prototypeTotal << " prototypes";
  if (instrument)
    std::cout << ", debugger: " << functionTotal << " functions, " << globalTotal << " globals"
              << ", live arguments: " << argTotal << ", fonts: " << fontRegTotal
              << ", controls: " << controlTotal;
  std::cout << "\n";
  return 0;
}
