// ArdSim: String class compatible with the Arduino core (subset used by
// sketches). Built on std::string. Comparisons call simPoll(), so busy
// loops like  do {} while (btnName == "---");  let the simulator deliver
// interrupts and timer ticks.
#ifndef ARDSIM_WSTRING_H
#define ARDSIM_WSTRING_H

#include <string>
#include <cstdint>

void simPoll();

class __FlashStringHelper;

class String
{
public:
  String();
  String(const char *text);
  String(const std::string &text);
  String(const String &other);
  String(const __FlashStringHelper *text);
  explicit String(char value);
  explicit String(unsigned char value, unsigned char base = 10);
  explicit String(int value, unsigned char base = 10);
  explicit String(unsigned int value, unsigned char base = 10);
  explicit String(long value, unsigned char base = 10);
  explicit String(unsigned long value, unsigned char base = 10);
  explicit String(long long value, unsigned char base = 10);
  explicit String(unsigned long long value, unsigned char base = 10);
  explicit String(float value, unsigned char decimals = 2);
  explicit String(double value, unsigned char decimals = 2);

  String &operator=(const String &other);
  String &operator=(const char *text);

  unsigned int length() const { return (unsigned int)Text.size(); }
  const char *c_str() const { return Text.c_str(); }
  bool reserve(unsigned int size) { Text.reserve(size); return true; }

  bool concat(const String &other) { Text += other.Text; return true; }
  bool concat(const char *text) { if (text) Text += text; return true; }
  bool concat(char value) { Text += value; return true; }
  bool concat(unsigned char value) { return concat(String(value)); }
  bool concat(int value) { return concat(String(value)); }
  bool concat(unsigned int value) { return concat(String(value)); }
  bool concat(long value) { return concat(String(value)); }
  bool concat(unsigned long value) { return concat(String(value)); }
  bool concat(float value) { return concat(String(value)); }
  bool concat(double value) { return concat(String(value)); }

  template <typename ValueType>
  String &operator+=(const ValueType &value) { concat(value); return *this; }
  String &operator+=(const char *text) { concat(text); return *this; }
  String &operator+=(char value) { concat(value); return *this; }

  bool equals(const String &other) const;
  bool equals(const char *text) const;
  bool equalsIgnoreCase(const String &other) const;
  bool operator==(const String &other) const { return equals(other); }
  bool operator==(const char *text) const { return equals(text); }
  bool operator!=(const String &other) const { return !equals(other); }
  bool operator!=(const char *text) const { return !equals(text); }
  bool operator<(const String &other) const { return Text < other.Text; }
  bool operator>(const String &other) const { return Text > other.Text; }
  int compareTo(const String &other) const { return Text.compare(other.Text); }
  bool startsWith(const String &prefix) const;
  bool endsWith(const String &suffix) const;

  char charAt(unsigned int index) const;
  void setCharAt(unsigned int index, char value);
  char operator[](unsigned int index) const { return charAt(index); }
  char &operator[](unsigned int index);
  void toCharArray(char *buffer, unsigned int size, unsigned int index = 0) const;
  void getBytes(unsigned char *buffer, unsigned int size, unsigned int index = 0) const;

  int indexOf(char value, unsigned int from = 0) const;
  int indexOf(const String &value, unsigned int from = 0) const;
  int lastIndexOf(char value) const;
  int lastIndexOf(const String &value) const;
  String substring(unsigned int from) const;
  String substring(unsigned int from, unsigned int to) const;

  void replace(char find, char with);
  void replace(const String &find, const String &with);
  void remove(unsigned int index);
  void remove(unsigned int index, unsigned int count);
  void toLowerCase();
  void toUpperCase();
  void trim();

  long toInt() const;
  float toFloat() const;
  double toDouble() const;

  std::string Text;
};

String operator+(const String &left, const String &right);
String operator+(const String &left, const char *right);
String operator+(const char *left, const String &right);
String operator+(const String &left, char right);
String operator+(const String &left, unsigned char right);
String operator+(const String &left, int right);
String operator+(const String &left, unsigned int right);
String operator+(const String &left, long right);
String operator+(const String &left, unsigned long right);
String operator+(const String &left, float right);
String operator+(const String &left, double right);
bool operator==(const char *left, const String &right);
bool operator!=(const char *left, const String &right);

#endif
