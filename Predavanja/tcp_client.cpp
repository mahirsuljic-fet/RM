#include <arpa/inet.h>
#include <iostream>
#include <iterator>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

const size_t BUFF_SIZE = 30;

void fail(const char* str)
{
  perror(str);
  exit(1);
}

int main(int argc, char* argv[])
{
  int sock_fd = socket(AF_INET, SOCK_STREAM, 0);

  if (sock_fd < 0)
    fail("Failed to create the socket");

  sockaddr_in dest_address;

  bzero(&dest_address, sizeof(dest_address));

  dest_address.sin_family = AF_INET;
  dest_address.sin_port = htons(5000);

  inet_pton(AF_INET, "127.0.0.1", &dest_address.sin_addr.s_addr);

  if (connect(sock_fd, reinterpret_cast<sockaddr*>(&dest_address), sizeof(dest_address)) < 0)
    fail("Connect failed");

  std::string output;
  char temp[BUFF_SIZE];
  int n;

  while ((n = read(sock_fd, temp, BUFF_SIZE)) != 0)
    std::copy(temp, temp + n, std::back_inserter(output));

  if (n < 0)
    fail("Read failed");

  std::cout << output << std::endl;

  close(sock_fd);

  return 0;
}
