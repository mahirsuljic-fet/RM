#include <arpa/inet.h>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <netinet/in.h>
#include <string>
#include <strings.h>
#include <sys/socket.h>
#include <unistd.h>

const size_t BUFF_SIZE = 30;
const uint16_t SERVER_PORT = 1234;
const size_t MAX_CONNECTIONS = 5;

void fail(const char* str)
{
  perror(str);
  exit(-1);
}

int main(int argc, char* argv[])
{
  // Kreiramo socket
  int server_sock_fd = socket(AF_INET, SOCK_STREAM, 0);

  if (server_sock_fd < 0)
    fail("Socket creation failed");

  sockaddr_in server_addr;

  server_addr.sin_family = AF_INET;
  server_addr.sin_port = htons(SERVER_PORT);
  server_addr.sin_addr.s_addr = INADDR_ANY; // moze se izostaviti htonl jer je IP adresa 0.0.0.0 ista i u big endian i u little endian

  if (bind(server_sock_fd, reinterpret_cast<sockaddr*>(&server_addr), sizeof(server_addr)) < 0)
    fail("Failed to bind server socket");

  if (listen(server_sock_fd, MAX_CONNECTIONS) < 0)
    fail("Failed to listen");

  while (true)
  {
    int client_sock_fd;
    sockaddr client_addr;
    socklen_t client_addr_size = sizeof(client_addr);

    std::cout << "Awaiting connection...\n";
    client_sock_fd = accept(server_sock_fd, &client_addr, &client_addr_size);

    sockaddr_in client_addr_in = *reinterpret_cast<sockaddr_in*>(&client_addr);
    std::string client_ip = inet_ntoa(*reinterpret_cast<in_addr*>(&client_addr_in.sin_addr.s_addr));
    uint16_t client_port = htons(client_addr_in.sin_port);

    std::cout << "Connection from " << client_ip << ":" << client_port << std::endl;

    while (true)
    {
      std::string msg(BUFF_SIZE, '\0');
      size_t recv_size;

      recv_size = recv(client_sock_fd, msg.data(), BUFF_SIZE, 0);

      if (recv_size == 0)
        break;

      std::cout << msg << std::endl;

      send(client_sock_fd, msg.data(), recv_size, 0);
    }

    close(client_sock_fd);
    std::cout << "Connection closed\n\n";
  }

  return 0;
}
