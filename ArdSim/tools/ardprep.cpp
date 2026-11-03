// ArdSim ardprep: turns an Arduino sketch (.ino) into a C++ file the way
// the Arduino IDE does before compiling:
//   - #include "Arduino.h" at the top;
//   - prototypes of the sketch functions before the first function, so a
//     function can be called above its definition;
//   - #line directives, so compiler errors point at the .ino lines.
// Usage: ardprep sketch.ino output.cpp
#include <cctype>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iostream>
#include <set>
#include <sstream>
#include <string>
#include <vector>

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
    else
      result += value;
  }
  return result;
}

int main(int argc, char **argv)
{
  if (argc < 3)
  {
    std::cerr << "usage: ardprep sketch.ino output.cpp\n";
    return 2;
  }
  std::string inoPath = argv[1];
  std::string text = readFile(inoPath);
  if (text.empty())
  {
    std::cerr << "ardprep: cannot read " << inoPath << "\n";
    return 1;
  }
  std::string mask = maskSource(text);
  std::vector<Signature> functions = findFunctions(mask);
  std::string lineName = "\"" + escapePath(inoPath) + "\"";

  std::string output = "#include \"Arduino.h\"\n#line 1 " + lineName + "\n";
  if (functions.empty())
    output += text;
  else
  {
    // insert at the start of the line of the first function
    size_t insertAt = functions[0].Start;
    while (insertAt > 0 && text[insertAt - 1] != '\n')
      insertAt--;
    output += text.substr(0, insertAt);
    std::set<std::string> seen;
    output += "// prototypes (ardprep)\n";
    for (const Signature &function : functions)
      if (seen.insert(function.Text).second)
        output += function.Text + ";\n";
    output += "#line " + std::to_string(lineOf(text, insertAt)) + " " + lineName + "\n";
    output += text.substr(insertAt);
  }
  std::ofstream result(argv[2], std::ios::binary);
  result << output;
  if (!result)
  {
    std::cerr << "ardprep: cannot write " << argv[2] << "\n";
    return 1;
  }
  std::cout << "ardprep: " << functions.size() << " functions\n";
  return 0;
}
