#include <arpa/inet.h>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <netinet/in.h>
#include <sstream>
#include <string>
#include <strings.h>
#include <sys/socket.h>
#include <unistd.h>
#include <vector>

static const std::size_t MAX_CONNECTIONS = 5;
static const std::size_t BUFF_SIZE = 512;
static const uint16_t SERVER_PORT = 8080;
static const char* const WEBSITE_PATH = "index.html";
static std::string website;

namespace HTTP
{
using Code = const char* const;

namespace Success
{
  static Code OK = "HTTP/1.1 200 OK";
}

namespace ClientError
{
  static Code BAD_REQUEST = "HTTP/1.1 400 Bad Request";
  static Code NOT_FOUND = "HTTP/1.1 404 Not Found";
  static Code NOT_ALLOWED = "HTTP/1.1 405 Method Not Allowed";
}

namespace ServerError
{
  static Code VERSION_NOT_SUPPORTED = "HTTP/1.1 505 HTTP Version Not Supported";
}
}

std::string get_file(const std::string& path);
std::string get_response(const std::string& request);
std::vector<std::string> split(const std::string& str, const char delimiter);

void fail(const char* str)
{
  perror(str);
  exit(-1);
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

  website = get_file(WEBSITE_PATH);

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

      response = get_response(request);

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

std::string get_response(const std::string& request)
{
  std::vector<std::string> request_parts = split(request, ' ');

  if (request_parts.size() < 3)
    return HTTP::ClientError::BAD_REQUEST;

  std::string method = request_parts[0];
  std::string path = request_parts[1];
  std::string version = request_parts[2];

  if (method != "GET")
    return HTTP::ClientError::NOT_ALLOWED;

  if (version.find("HTTP/1") == version.npos)
    return HTTP::ServerError::VERSION_NOT_SUPPORTED;

  std::string response_data;

  if (path == "/" || path == WEBSITE_PATH)
    response_data = website;
  else
    response_data = get_file(path);

  if (response_data.empty())
    return HTTP::ClientError::NOT_FOUND;

  std::string content_type = (path == "/" || path.rfind(".htm") != path.npos) ? "text/html" : "text/plain";
  std::stringstream sstream;

  sstream << HTTP::Success::OK << "\n";
  sstream << "Content-Length: " << response_data.length() << "\n";
  sstream << "Content-Type: " << content_type << "\n";
  sstream << "\n";
  sstream << response_data;

  return sstream.str();
}

std::vector<std::string> split(const std::string& str, const char delimiter)
{
  std::vector<std::string> result;
  std::stringstream sstream(str);
  std::string part;

  while (std::getline(sstream, part, delimiter))
    result.push_back(part);

  return result;
}

std::string get_file(const std::string& path)
{
  const char* cpath = path.c_str();

  if (path.size() < 1)
    return "";

  if (path[0] == '/')
    cpath = &path[1];

  if (!std::filesystem::exists(cpath))
    return "";

  std::ifstream file(cpath);
  std::stringstream sstream;
  std::string line;

  while (std::getline(file, line))
    sstream << line << "\r\n";

  file.close();

  return sstream.str();
}
