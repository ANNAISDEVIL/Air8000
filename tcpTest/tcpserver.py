import socket

HOST = "0.0.0.0"
PORT = 9000

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# 方便重新启动，不会出现 Address already in use
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

server.bind((HOST, PORT))
server.listen(1)

print("=" * 50)
print(f"TCP Server Listening")
print(f"Host : {HOST}")
print(f"Port : {PORT}")
print("Waiting for Air8000...")
print("Press Ctrl+C to stop.")
print("=" * 50)

try:
    while True:

        conn, addr = server.accept()

        print(f"\nClient Connected : {addr}")

        try:
            while True:

                data = conn.recv(4096)

                if not data:
                    print("Client Disconnected")
                    break

                print(f"RX ({len(data)} Bytes)")
                print(data)
                print("-" * 50)

        except ConnectionResetError:
            print("Connection Reset")

        finally:
            conn.close()

except KeyboardInterrupt:
    print("\nCtrl+C detected.")
    print("Server stopped.")

finally:
    server.close()