#include <arpa/inet.h>
#include <cctype>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <netinet/in.h>
#include <string>
#include <strings.h>
#include <sys/socket.h>
#include <unistd.h>

static const size_t BUFF_SIZE = 100;
static const char* SERVER_ADDR = "127.0.0.1";
static uint16_t SERVER_PORT = 8080;

std::size_t get_content_length(const std::string& recv_msg);

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

  sockaddr_in server_addr;

  server_addr.sin_family = AF_INET;
  server_addr.sin_port = htons(SERVER_PORT);

  inet_pton(AF_INET, SERVER_ADDR, &server_addr.sin_addr.s_addr);

  if (connect(sock_fd, reinterpret_cast<sockaddr*>(&server_addr), sizeof(server_addr)) < 0)
    fail("Failed to connect to server");

  while (true)
  {
    std::string request;

    std::cout << "Write message: ";
    std::getline(std::cin, request);

    send(sock_fd, request.data(), request.size(), 0);

    std::cout << "Message sent\n";

    // Procitaj dio (BUFF_SIZE) podataka u kojima ce biti header
    std::string response(BUFF_SIZE, '\0');

    if (read(sock_fd, response.data(), BUFF_SIZE) == 0)
      break;

    // Ako je poruke OK onda procitaj ostatak poruke
    if (response.find("OK") != response.npos)
    {
      // Pronadji velicinu poruke iz headera
      std::size_t content_len = get_content_length(response);

      if (content_len > 0)
      {
        auto empty_line_index = response.find("\n\n");
        char* data = response.data() + empty_line_index + 2;
        std::size_t header_size = empty_line_index + 2;

        // Napravi prostora za cijeli odgovor
        response.resize(header_size + content_len, '\0');

        // Vec je procitano BUFF_SIZE poruke, procitaj ostatak
        char* read_begin = response.data() + BUFF_SIZE;
        std::size_t read_len = header_size + content_len - BUFF_SIZE;

        if (read(sock_fd, read_begin, read_len) == 0) break;
      }
    }

    std::cout << "Response:\n";
    std::cout << response << "\n\n";
  }

  close(sock_fd);

  return 0;
}

std::size_t get_content_length(const std::string& header)
{
  using index = std::string::size_type;

  index content_len_index = header.find("Content-Length: ");

  if (content_len_index == header.npos)
    return -1;

  // Pronadji pocetak i kraj dijela string-a koji sadrzi broj content length
  index start = content_len_index + sizeof("Content-Length:");
  index end = start;

  while (std::isdigit(header[end]))
    end++;

  std::size_t value_length = end - start;                           // duzina broja content length
  std::string content_len_str = header.substr(start, value_length); // broj content length kao string

  return std::stoi(content_len_str);
}
