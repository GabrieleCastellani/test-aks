import socket

HOST = ''  # Listen on all available interfaces
PORT = 12345  # Port to listen on

def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen()
        print(f"Server listening on port {PORT}")
        while True:
            conn, addr = s.accept()
            with conn:
                source_ip = addr[0]
                print(f"Connection established with {source_ip}")
                response = f"Your source IP is {source_ip}\n"
                conn.sendall(response.encode('utf-8'))

if __name__ == "__main__":
    main()
