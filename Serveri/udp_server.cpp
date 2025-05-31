#include <arpa/inet.h>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <netinet/in.h>
#include <sstream>
#include <string>
#include <strings.h>
#include <sys/socket.h>
#include <unistd.h>

const size_t BUFF_SIZE = 30;
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

  sockaddr_in addr;
  socklen_t size = sizeof(addr);

  // nuliramo strukturu addr
  bzero(&addr, sizeof(sockaddr_in));

  addr.sin_family = AF_INET;                // koristimo IPv4
  addr.sin_port = htons(SERVER_PORT);       // server ce slusati na portu SERVER_PORT (1234)
  addr.sin_addr.s_addr = htonl(INADDR_ANY); // server ce slusati na svim adresama (interface-ima)

  // htons - host to network short, pretvaramo 16b (short) iz little endian (host) u big endian (network)
  // htonl - host to network long, pretvaramo 16b (long) iz little endian (host) u big endian (network)

  // vezujemo socket za adresu
  if (bind(sock_fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0)
    fail("Failed to bind socket");

  while (true)
  {
    // priprema buffera za poruku od klijenta
    std::string msg(BUFF_SIZE, '\0');

    int recv_size;
    sockaddr client_addr;
    socklen_t client_size = sizeof(client_addr); // govorimo ocekivanu velicinu za klient IP

    // Cekamo da neki klijent posalje poruku.
    // Opis argumenata:
    // - poruku cekamo na socketu opisanom sa sock_fd
    // - poruku cemo zapisivati u msg pa proslijedimo pointer na data od msg, moze i &mgs[0]
    // - maksimalno mozemo primiti BUFF_SIZE
    // - necemo koristiti nikakve flagove
    // - adresu klijenta cemo zapisati u client_addr
    // - kao zadnji argument proslijedimo adresu varijable za velicinu IP adrese
    std::cout << "Awaiting data...\n";
    recv_size = recvfrom(sock_fd, msg.data(), BUFF_SIZE, 0, &client_addr, &client_size);

    // Ovaj sljedeci dio je za ispis poruke, IP adrese i porta

    // Pretvorimo client_addr iz sockaddr u sockaddr_in kako bi mogli pristupiti poljima
    sockaddr_in client_addr_in = *reinterpret_cast<sockaddr_in*>(&client_addr);
    uint16_t client_port = htons(client_addr_in.sin_port); // uzmemo port i pretvorimo iz big u little endian

    // Metod 1 (m1) za dobijanje IP string-a iz sockaddr_in (koristeci inet_ntoa)
    std::string client_addr_m1 = inet_ntoa(*reinterpret_cast<in_addr*>(&client_addr_in.sin_addr.s_addr));

    // Metod 2 (m2) za dobijanje IP string-a iz sockaddr_in (koristeci inet_ntop)
    std::string client_addr_m2(INET_ADDRSTRLEN, '\0'); // inicijaliziramo string koji ce cuvati IP
    inet_ntop(AF_INET, &client_addr_in.sin_addr.s_addr, client_addr_m2.data(), client_addr_m2.size());

    // Metod 3 (m3) za dobijanje IP string-a iz sockaddr_in ("rucno")
    auto ipv4tostr = [](uint32_t addr) {
      std::stringstream sstream;

      sstream << ((addr & 0xff000000) >> 3 * 8) << ".";
      sstream << ((addr & 0x00ff0000) >> 2 * 8) << ".";
      sstream << ((addr & 0x0000ff00) >> 1 * 8) << ".";
      sstream << (addr & 0x000000ff);

      return sstream.str();
    };
    uint32_t client_address = htonl(client_addr_in.sin_addr.s_addr); // uzmemo adresu i pretvorimo iz big u little endian
    std::string client_addr_m3 = ipv4tostr(client_address);

    // Ispis
    std::cout << "Message:      " << msg << "\n";
    std::cout << "Address (m1): " << client_addr_m1 << "\n";
    std::cout << "Address (m2): " << client_addr_m2 << "\n";
    std::cout << "Address (m3): " << client_addr_m3 << "\n";
    std::cout << "Port:         " << client_port << "\n";
    std::cout << std::endl;

    // Saljemo istu poruku nazad klijentu
    sendto(sock_fd, msg.data(), recv_size, 0, &client_addr, sizeof(client_addr));
  }

  close(sock_fd);

  return 0;
}
