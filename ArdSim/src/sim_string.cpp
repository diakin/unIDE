// ArdSim: Arduino String on std::string. Number formatting as in the
// Arduino core: integers in the given base, float/double with a fixed
// number of decimals (default 2).
#include "Arduino.h"
#include <cctype>
#include <cstdlib>
#include <cstdio>

static std::string numberText(unsigned long long value, unsigned char base)
{
  if (base < 2 || base > 36)
    base = 10;
  if (value == 0)
    return "0";
  std::string digits;
  while (value)
  {
    int digit = (int)(value % base);
    digits.insert(digits.begin(), (char)(digit < 10 ? '0' + digit : 'a' + digit - 10));
    value /= base;
  }
  return digits;
}

static std::string signedText(long long value, unsigned char base)
{
  if (value < 0 && base == 10)
    return "-" + numberText((unsigned long long)(-value), base);
  // Arduino: other bases show the two's complement of a 32-bit value
  if (value < 0)
    return numberText((unsigned long long)(uint32_t)value, base);
  return numberText((unsigned long long)value, base);
}

static std::string floatText(double value, unsigned char decimals)
{
  if (std::isnan(value))
    return "nan";
  if (std::isinf(value))
    return "inf";
  // Arduino dtostrf limits: very large values print as "ovf"
  if (value > 4294967040.0 || value < -4294967040.0)
    return "ovf";
  char buffer[64];
  snprintf(buffer, sizeof(buffer), "%.*f", (int)decimals, value);
  return buffer;
}

String::String() {}
String::String(const char *text) : Text(text ? text : "") {}
String::String(const std::string &text) : Text(text) {}
String::String(const String &other) : Text(other.Text) {}
String::String(const __FlashStringHelper *text) : Text(text ? (const char *)text : "") {}
String::String(char value) : Text(1, value) {}
String::String(unsigned char value, unsigned char base) : Text(numberText(value, base)) {}
String::String(int value, unsigned char base) : Text(signedText(value, base)) {}
String::String(unsigned int value, unsigned char base) : Text(numberText(value, base)) {}
String::String(long value, unsigned char base) : Text(signedText(value, base)) {}
String::String(unsigned long value, unsigned char base) : Text(numberText(value, base)) {}
String::String(long long value, unsigned char base) : Text(signedText(value, base)) {}
String::String(unsigned long long value, unsigned char base) : Text(numberText(value, base)) {}
String::String(float value, unsigned char decimals) : Text(floatText(value, decimals)) {}
String::String(double value, unsigned char decimals) : Text(floatText(value, decimals)) {}

String &String::operator=(const String &other)
{
  if (this != &other)
    Text = other.Text;
  return *this;
}

String &String::operator=(const char *text)
{
  Text = text ? text : "";
  return *this;
}

bool String::equals(const String &other) const
{
  simPoll();
  return Text == other.Text;
}

bool String::equals(const char *text) const
{
  simPoll();
  return Text == (text ? text : "");
}

bool String::equalsIgnoreCase(const String &other) const
{
  if (Text.size() != other.Text.size())
    return false;
  for (size_t index = 0; index < Text.size(); index++)
    if (tolower((unsigned char)Text[index]) != tolower((unsigned char)other.Text[index]))
      return false;
  return true;
}

bool String::startsWith(const String &prefix) const
{
  return Text.compare(0, prefix.Text.size(), prefix.Text) == 0 && Text.size() >= prefix.Text.size();
}

bool String::endsWith(const String &suffix) const
{
  return Text.size() >= suffix.Text.size() &&
         Text.compare(Text.size() - suffix.Text.size(), suffix.Text.size(), suffix.Text) == 0;
}

char String::charAt(unsigned int index) const
{
  return index < Text.size() ? Text[index] : 0;
}

void String::setCharAt(unsigned int index, char value)
{
  if (index < Text.size())
    Text[index] = value;
}

char &String::operator[](unsigned int index)
{
  static char dummy;
  if (index >= Text.size())
  {
    dummy = 0;
    return dummy;
  }
  return Text[index];
}

void String::toCharArray(char *buffer, unsigned int size, unsigned int index) const
{
  getBytes((unsigned char *)buffer, size, index);
}

void String::getBytes(unsigned char *buffer, unsigned int size, unsigned int index) const
{
  if (!buffer || size == 0)
    return;
  if (index >= Text.size())
  {
    buffer[0] = 0;
    return;
  }
  unsigned int count = (unsigned int)Text.size() - index;
  if (count > size - 1)
    count = size - 1;
  memcpy(buffer, Text.data() + index, count);
  buffer[count] = 0;
}

int String::indexOf(char value, unsigned int from) const
{
  size_t found = Text.find(value, from);
  return found == std::string::npos ? -1 : (int)found;
}

int String::indexOf(const String &value, unsigned int from) const
{
  size_t found = Text.find(value.Text, from);
  return found == std::string::npos ? -1 : (int)found;
}

int String::lastIndexOf(char value) const
{
  size_t found = Text.rfind(value);
  return found == std::string::npos ? -1 : (int)found;
}

int String::lastIndexOf(const String &value) const
{
  size_t found = Text.rfind(value.Text);
  return found == std::string::npos ? -1 : (int)found;
}

String String::substring(unsigned int from) const
{
  return substring(from, (unsigned int)Text.size());
}

String String::substring(unsigned int from, unsigned int to) const
{
  // Arduino swaps the bounds if they come in reverse order
  if (from > to)
  {
    unsigned int temp = from;
    from = to;
    to = temp;
  }
  if (from >= Text.size())
    return String();
  if (to > Text.size())
    to = (unsigned int)Text.size();
  return String(Text.substr(from, to - from));
}

void String::replace(char find, char with)
{
  for (char &value : Text)
    if (value == find)
      value = with;
}

void String::replace(const String &find, const String &with)
{
  if (find.Text.empty())
    return;
  size_t pos = 0;
  while ((pos = Text.find(find.Text, pos)) != std::string::npos)
  {
    Text.replace(pos, find.Text.size(), with.Text);
    pos += with.Text.size();
  }
}

void String::remove(unsigned int index)
{
  if (index < Text.size())
    Text.erase(index);
}

void String::remove(unsigned int index, unsigned int count)
{
  if (index < Text.size())
    Text.erase(index, count);
}

void String::toLowerCase()
{
  for (char &value : Text)
    value = (char)tolower((unsigned char)value);
}

void String::toUpperCase()
{
  for (char &value : Text)
    value = (char)toupper((unsigned char)value);
}

void String::trim()
{
  size_t first = 0;
  while (first < Text.size() && isspace((unsigned char)Text[first]))
    first++;
  size_t last = Text.size();
  while (last > first && isspace((unsigned char)Text[last - 1]))
    last--;
  Text = Text.substr(first, last - first);
}

long String::toInt() const { return atol(Text.c_str()); }
float String::toFloat() const { return (float)atof(Text.c_str()); }
double String::toDouble() const { return atof(Text.c_str()); }

String operator+(const String &left, const String &right) { String result(left); result.Text += right.Text; return result; }
String operator+(const String &left, const char *right) { String result(left); if (right) result.Text += right; return result; }
String operator+(const char *left, const String &right) { String result(left); result.Text += right.Text; return result; }
String operator+(const String &left, char right) { String result(left); result.Text += right; return result; }
String operator+(const String &left, unsigned char right) { return left + String(right); }
String operator+(const String &left, int right) { return left + String(right); }
String operator+(const String &left, unsigned int right) { return left + String(right); }
String operator+(const String &left, long right) { return left + String(right); }
String operator+(const String &left, unsigned long right) { return left + String(right); }
String operator+(const String &left, float right) { return left + String(right); }
String operator+(const String &left, double right) { return left + String(right); }
bool operator==(const char *left, const String &right) { return right.equals(left); }
bool operator!=(const char *left, const String &right) { return !right.equals(left); }
