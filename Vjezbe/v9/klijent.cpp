#include <arpa/inet.h>
#include <iostream>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

const size_t BUFF_SIZE = 30;

void fail(const char* str)
{
  perror(str);
  exit(1);
}

int main()
{
  int sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (sock_fd < 0)
    fail("Failed to create the socket");
  sockaddr_in dest_address;
  bzero(&dest_address, sizeof(dest_address));
  dest_address.sin_family = AF_INET;
  dest_address.sin_port = htons(5000);
  inet_pton(AF_INET, "127.0.0.1", &dest_address.sin_addr.s_addr);
  std::string buff(BUFF_SIZE, '\0');
  socklen_t sz = sizeof(dest_address);
  sendto(sock_fd, &buff[0], 1, 0,
    reinterpret_cast<sockaddr*>(&dest_address),
    sizeof(dest_address));
  recvfrom(sock_fd, &buff[0], BUFF_SIZE, 0,
    reinterpret_cast<sockaddr*>(&dest_address), &sz);
  std::cout << buff << std::endl;
  close(sock_fd);
  return 0;
}
