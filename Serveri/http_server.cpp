#include <arpa/inet.h>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <netinet/in.h>
#include <sstream>
#include <string>
#include <strings.h>
#include <sys/socket.h>
#include <unistd.h>

static const std::size_t MAX_CONNECTIONS = 5;
static const std::size_t BUFF_SIZE = 100;
static const uint16_t SERVER_PORT = 8080;
static const char* const SERVER_PATH = "index.html";

static const char* const HTTP_OK = "HTTP/1.1 200 OK";
static const char* const HTTP_NOTFOUND = "HTTP/1.1 404 Not Found";
static const char* const HTTP_NOTALLOWED = "HTTP/1.1 405 Method Not Allowed";

static std::string website;

void fail(const char* str)
{
  perror(str);
  exit(-1);
}

void load_website()
{
  std::ifstream file(SERVER_PATH);
  std::stringstream sstream;
  std::string line;

  while (std::getline(file, line))
    sstream << line << "\n";

  website = sstream.str();

  file.close();
}

int main(int argc, char* argv[])
{
  int server_sock_fd = socket(AF_INET, SOCK_STREAM, 0);

  if (server_sock_fd < 0)
    fail("Failed to create socket");

  std::cout << "Socket created\n";

  sockaddr_in server_addr;

  server_addr.sin_family = AF_INET;
  server_addr.sin_addr.s_addr = INADDR_ANY;
  server_addr.sin_port = htons(SERVER_PORT);

  if (bind(server_sock_fd, reinterpret_cast<sockaddr*>(&server_addr), sizeof(server_addr)) < 0)
    fail("Failed to bind socket");

  std::cout << "Socket bound\n";

  load_website();

  std::cout << "Website loaded\n";

  if (listen(server_sock_fd, MAX_CONNECTIONS) < 0)
    fail("Listen failed");

  std::cout << "Listening...\n";

  while (true)
  {
    int client_sock_fd;
    sockaddr client_addr;
    socklen_t client_addr_len = sizeof(client_addr);

    if ((client_sock_fd = accept(server_sock_fd, &client_addr, &client_addr_len)) < 0)
    {
      perror("Failed to accept connection");
      break;
    }

    sockaddr_in client_addr_in = *reinterpret_cast<sockaddr_in*>(&client_addr);
    std::string client_ip = inet_ntoa(*reinterpret_cast<in_addr*>(&client_addr_in.sin_addr.s_addr));
    uint16_t client_port = htons(client_addr_in.sin_port);

    std::cout << "New connection from " << client_ip << ":" << client_port << std::endl;

    if (fork() == 0)
      continue;

    while (true)
    {
      std::string request(BUFF_SIZE, '\0');
      std::string response;

      if (recv(client_sock_fd, request.data(), request.size(), 0) == 0)
        break;

      std::cout << "\nRequest received:\n"
                << request << std::endl;

      if (request.find("GET") == request.npos)
      {
        response = HTTP_NOTALLOWED;
      }
      else if (request.find("/") != request.npos
        || request.find("/index.html") != request.npos
        || request.find("index.html") != request.npos)
      {

        std::stringstream sstream;

        sstream << HTTP_OK << "\n";
        sstream << "Content-Length: " << website.length() << "\n";
        sstream << "Content-Type: text/html" << "\n";
        sstream << "\n";
        sstream << website;

        response = sstream.str();
      }
      else
      {
        response = HTTP_NOTFOUND;
      }

      if (send(client_sock_fd, response.data(), response.length(), 0) < 0)
      {
        perror("Failed to send response");
        break;
      }

      std::cout << "Response sent\n";
    }

    close(client_sock_fd);

    std::cout << "Connection closed\n";
  }

  close(server_sock_fd);

  return 0;
}
