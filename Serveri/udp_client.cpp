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
const char* SERVER_ADDR = "127.0.0.1";
const uint16_t SERVER_PORT = 1234;

void fail(const char* str)
{
  perror(str);
  exit(-1);
}

int main(int argc, char* argv[])
{
  // Kreiramo socket
  int sock_fd = socket(AF_INET, SOCK_DGRAM, 0);

  if (sock_fd < 0)
    fail("Socket creation failed");

  sockaddr_in server_addr;

  // nuliramo strukturu server_addr
  bzero(&server_addr, sizeof(server_addr));

  server_addr.sin_family = AF_INET;          // koristimo IPv4
  server_addr.sin_port = htons(SERVER_PORT); // poruke cemo slati na port od servera (1234)

  // zapisujemo adresu servera ("127.0.0.1") u strukturu server_addr
  inet_pton(AF_INET, SERVER_ADDR, &server_addr.sin_addr.s_addr);

  while (true)
  {
    std::string send_msg;

    std::cout << "Write message: ";
    std::cin >> send_msg;

    sendto(sock_fd, send_msg.data(), send_msg.size(), 0, reinterpret_cast<sockaddr*>(&server_addr), sizeof(server_addr));

    std::cout << "Message sent\n";

    // inicijalizacija buffera za primanje poruke
    std::string recv_msg(BUFF_SIZE, '\0');

    // Cekamo da primimo poruku.
    // Opis arugmenata:
    // - Poruku cekamo na socketu opisanom sa sock_fd
    // - Poruku cemo zapisati u recv_msg.data(), moze i &recv_msg[0].
    // - Maksimalno mozemo primiti BUFF_SIZE podataka.
    // - Ne koristimo nikakve flagove (0).
    // - Ne zanima nas IP od kojeg dobijemo poruku (nullptr, nullptr).
    recvfrom(sock_fd, recv_msg.data(), BUFF_SIZE, 0, nullptr, nullptr);

    // Ispis
    std::cout << recv_msg << "\n\n";
  }

  close(sock_fd);

  return 0;
}
