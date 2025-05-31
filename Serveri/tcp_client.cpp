#include <arpa/inet.h>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <netinet/in.h>
#include <string>
#include <strings.h>
#include <sys/socket.h>
#include <unistd.h>

static const size_t BUFF_SIZE = 300;
static const char* SERVER_ADDR = "127.0.0.1";
static uint16_t SERVER_PORT;

void fail(const char* str)
{
  perror(str);
  exit(-1);
}

int main(int argc, char* argv[])
{
  int sock_fd = socket(AF_INET, SOCK_STREAM, 0);

  if (sock_fd < 0)
    fail("Socket creation failed");

  // Zatrazi port od korisnika
  // Ovo je dodano kako bi isti ovaj klijent mogao se spojiti i na HTTP server
  std::cout << "Input server port: ";
  std::cin >> SERVER_PORT;
  std::cin.ignore();

  sockaddr_in server_addr;

  server_addr.sin_family = AF_INET;
  server_addr.sin_port = htons(SERVER_PORT);

  inet_pton(AF_INET, SERVER_ADDR, &server_addr.sin_addr.s_addr);

  if (connect(sock_fd, reinterpret_cast<sockaddr*>(&server_addr), sizeof(server_addr)) < 0)
    fail("Failed to connect to server");

  while (true)
  {
    std::string msg;

    std::cout << "Write message: ";
    std::getline(std::cin, msg);

    send(sock_fd, msg.data(), msg.size(), 0);

    std::cout << "Message sent\n";

    std::string recv_msg(BUFF_SIZE, '\0');

    // Ako read vrati 0 to znaci da je konekcija prekinuta i treba zatvoriti socket
    if (read(sock_fd, recv_msg.data(), recv_msg.size()) == 0)
      break;

    std::cout << "Response: ";
    std::cout << recv_msg << "\n\n";
  }

  close(sock_fd);

  return 0;
}
