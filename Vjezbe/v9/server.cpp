#include <arpa/inet.h>
#include <chrono>
#include <ctime>
#include <iostream>
#include <netinet/in.h>
#include <string.h>
#include <strings.h>
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

int main()
{
  int sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (sock_fd < 0)
    fail("Failed to create the socket");
  sockaddr_in my_address;
  bzero(&my_address, sizeof(my_address));
  my_address.sin_family = AF_INET;
  my_address.sin_port = htons(5000);
  my_address.sin_addr.s_addr = htonl(INADDR_ANY);
  if (bind(sock_fd, reinterpret_cast<sockaddr*>(&my_address), sizeof(my_address)) < 0)
    fail("Failed to bind the socket");
  char buff[BUFF_SIZE];
  sockaddr peer_address;
  socklen_t sz = sizeof(peer_address);

  while (recvfrom(sock_fd, &buff, BUFF_SIZE, 0, &peer_address, &sz))
  {
    std::cout << buff << " from port " << htons(reinterpret_cast<sockaddr_in*>(&peer_address)->sin_port);
  }
  close(sock_fd);
  return 0;
}
