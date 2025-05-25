#include <arpa/inet.h>
#include <chrono>
#include <ctime>
#include <string.h>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

const size_t BUFF_SIZE = 30;

void fail(const char* str)
{
  perror(str);
  exit(1);
}

std::string getTime()
{
  using std::chrono::system_clock;

  auto now = system_clock::to_time_t(system_clock::now());
  std::string s(BUFF_SIZE, '\0');
  std::strftime(&s[0], s.size(), "%Y-%m-%d %H:%M:%S", std::localtime(&now));

  return s;
}

int main(int argc, char* argv[])
{
  int sock_fd = socket(AF_INET, SOCK_STREAM, 0); // IPv4, TCP

  if (sock_fd < 0)
    fail("Failed to create the socket");

  sockaddr_in my_address;

  bzero(&my_address, sizeof(my_address));

  my_address.sin_family = AF_INET;
  my_address.sin_port = htons(5000);              // pretvaramo u big endian 2B
  my_address.sin_addr.s_addr = htonl(INADDR_ANY); // pretvaramo u big endian od 4B

  // htons - host to network short
  // htonl - host to network long

  if (bind(sock_fd, reinterpret_cast<sockaddr*>(&my_address), sizeof(my_address)) < 0)
    fail("Failed to bind the socket");

  if (listen(sock_fd, 5) < 0)
    fail("Listen failed");

  int client_fd;

  while ((client_fd = accept(sock_fd, nullptr, nullptr)) >= 0)
  {
    auto t = getTime();

    if (write(client_fd, &t[0], t.size()) != t.size())
      fail("Write failed");

    close(client_fd);
  }

  fail("Accept failed");
  close(sock_fd);

  return 0;
}
