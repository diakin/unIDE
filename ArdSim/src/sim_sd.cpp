// ArdSim: SD card as the folder sim_sd next to the simulator exe.
// Names follow the FAT 8.3 rule of the Arduino SD library: a path part
// longer than 8.3 fails to open, as it does on the device.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include "SD.h"
#include "sim_internal.h"
#include <cstdio>
#include <cctype>
#include <algorithm>

SDClass SD;

struct SimFileState
{
  int RefCount = 1;
  FILE *Handle = nullptr;
  bool IsDir = false;
  std::string HostPath;               // full path on the PC
  std::vector<std::string> Entries;   // directory: names of entries
  size_t NextEntry = 0;
  char Name[13] = {0};                // 8.3 name for File::name()
};

static std::string sdRoot()
{
  return simExeDir() + "sim_sd";
}

static bool nameIs83(const std::string &part)
{
  size_t dot = part.find('.');
  std::string base = dot == std::string::npos ? part : part.substr(0, dot);
  std::string ext = dot == std::string::npos ? "" : part.substr(dot + 1);
  if (base.empty() || base.size() > 8 || ext.size() > 3 || ext.find('.') != std::string::npos)
    return false;
  return true;
}

// "/Archive1/Test.dat" -> host path; false if a part is not 8.3
static bool hostPath(const char *path, std::string &result)
{
  result = sdRoot();
  if (simSdFail())
    return false;   // no card: open, exists, mkdir, remove fail
  std::string text = path ? path : "";
  std::replace(text.begin(), text.end(), '\\', '/');
  size_t pos = 0;
  while (pos <= text.size())
  {
    size_t next = text.find('/', pos);
    if (next == std::string::npos)
      next = text.size();
    std::string part = text.substr(pos, next - pos);
    pos = next + 1;
    if (part.empty() || part == ".")
      continue;
    if (part == "..")
    {
      size_t slash = result.find_last_of('\\');
      if (slash != std::string::npos && result.size() > sdRoot().size())
        result.erase(slash);
      continue;
    }
    if (!nameIs83(part))
      return false;
    result += "\\" + part;
  }
  return true;
}

static void setName(SimFileState *state, const std::string &host)
{
  size_t slash = host.find_last_of('\\');
  std::string name = slash == std::string::npos ? host : host.substr(slash + 1);
  if (host == sdRoot())
    name = "/";
  // the SD library reports names in upper case
  for (char &value : name)
    value = (char)toupper((unsigned char)value);
  strncpy(state->Name, name.c_str(), sizeof(state->Name) - 1);
}

static bool isDirectory(const std::string &host)
{
  DWORD attributes = GetFileAttributesA(host.c_str());
  return attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_DIRECTORY);
}

static File openHost(const std::string &host, uint8_t mode)
{
  File result;
  SimFileState *state = new SimFileState();
  state->HostPath = host;
  setName(state, host);
  if (isDirectory(host))
  {
    state->IsDir = true;
    WIN32_FIND_DATAA findData;
    HANDLE find = FindFirstFileA((host + "\\*").c_str(), &findData);
    if (find != INVALID_HANDLE_VALUE)
    {
      do
      {
        std::string entry = findData.cFileName;
        if (entry != "." && entry != "..")
          state->Entries.push_back(entry);
      } while (FindNextFileA(find, &findData));
      FindClose(find);
    }
  }
  else
  {
    bool writing = (mode & O_WRITE) != 0;
    state->Handle = fopen(host.c_str(), writing ? "a+b" : "rb");
    if (!state->Handle)
    {
      delete state;
      return result;
    }
    if (writing)
      fseek(state->Handle, 0, SEEK_END);
  }
  result.State = state;
  return result;
}

bool SDClass::begin(uint8_t csPin)
{
  (void)csPin;
  simPoll();
  if (simSdFail())
    return false;
  CreateDirectoryA(sdRoot().c_str(), nullptr);
  return isDirectory(sdRoot());
}

File SDClass::open(const char *path, uint8_t mode)
{
  simPoll();
  std::string host;
  if (!hostPath(path, host))
    return File();
  return openHost(host, mode);
}

bool SDClass::exists(const char *path)
{
  std::string host;
  return hostPath(path, host) && GetFileAttributesA(host.c_str()) != INVALID_FILE_ATTRIBUTES;
}

bool SDClass::mkdir(const char *path)
{
  // creates the intermediate folders too, as the SD library does
  std::string host;
  if (!hostPath(path, host))
    return false;
  for (size_t pos = sdRoot().size() + 1; pos <= host.size(); pos++)
    if (pos == host.size() || host[pos] == '\\')
      CreateDirectoryA(host.substr(0, pos).c_str(), nullptr);
  return isDirectory(host);
}

bool SDClass::remove(const char *path)
{
  std::string host;
  return hostPath(path, host) && DeleteFileA(host.c_str());
}

bool SDClass::rmdir(const char *path)
{
  std::string host;
  return hostPath(path, host) && RemoveDirectoryA(host.c_str());
}

File::File() : State(nullptr) {}
File::File(const File &other) : State(other.State) { if (State) State->RefCount++; }
File &File::operator=(const File &other)
{
  if (State == other.State)
    return *this;
  if (State && --State->RefCount == 0)
  {
    if (State->Handle)
      fclose(State->Handle);
    delete State;
  }
  State = other.State;
  if (State)
    State->RefCount++;
  return *this;
}
File::~File()
{
  // the device keeps the file open until close(); here the last copy
  // closes it so handles do not leak
  if (State && --State->RefCount == 0)
  {
    if (State->Handle)
      fclose(State->Handle);
    delete State;
  }
}

size_t File::write(uint8_t value) { return write(&value, 1); }
size_t File::write(const uint8_t *buffer, size_t size)
{
  if (!State || !State->Handle)
    return 0;
  return fwrite(buffer, 1, size, State->Handle);
}

int File::read()
{
  if (!State || !State->Handle)
    return -1;
  return fgetc(State->Handle);
}

int File::read(void *buffer, uint16_t size)
{
  if (!State || !State->Handle)
    return -1;
  return (int)fread(buffer, 1, size, State->Handle);
}

int File::peek()
{
  int value = read();
  if (value >= 0)
    ungetc(value, State->Handle);
  return value;
}

int File::available()
{
  if (!State || !State->Handle)
    return 0;
  long current = ftell(State->Handle);
  return (int)(size() - (uint32_t)current);
}

void File::flush() { if (State && State->Handle) fflush(State->Handle); }

bool File::seek(uint32_t position)
{
  return State && State->Handle && fseek(State->Handle, (long)position, SEEK_SET) == 0;
}

uint32_t File::position()
{
  return State && State->Handle ? (uint32_t)ftell(State->Handle) : 0;
}

uint32_t File::size()
{
  if (!State || !State->Handle)
    return 0;
  long current = ftell(State->Handle);
  fseek(State->Handle, 0, SEEK_END);
  long total = ftell(State->Handle);
  fseek(State->Handle, current, SEEK_SET);
  return (uint32_t)total;
}

void File::close()
{
  if (State && State->Handle)
  {
    fclose(State->Handle);
    State->Handle = nullptr;
  }
  if (State && --State->RefCount == 0)
    delete State;
  State = nullptr;
}

File::operator bool() const { return State != nullptr; }
char *File::name() { static char empty[1] = {0}; return State ? State->Name : empty; }
bool File::isDirectory() { return State && State->IsDir; }

File File::openNextFile(uint8_t mode)
{
  simPoll();
  if (!State || !State->IsDir)
    return File();
  while (State->NextEntry < State->Entries.size())
  {
    std::string entry = State->Entries[State->NextEntry++];
    if (!nameIs83(entry))
      continue;   // long names are invisible to the SD library
    return openHost(State->HostPath + "\\" + entry, mode);
  }
  return File();
}

void File::rewindDirectory()
{
  if (State)
    State->NextEntry = 0;
}
