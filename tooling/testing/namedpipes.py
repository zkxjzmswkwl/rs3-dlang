# Chat gpt. I accept 0 responsibility.
import win32pipe, win32file, pywintypes

PIPE_NAME = r'\\.\pipe\BigOlDongs'
BUFFER_SIZE = 512

def connect_to_pipe():
    """Connects to an existing named pipe"""
    try:
        handle = win32file.CreateFile(
            PIPE_NAME,
            win32file.GENERIC_READ | win32file.GENERIC_WRITE,
            0,  # No sharing
            None,  # Default security
            win32file.OPEN_EXISTING,
            0,  # Default attributes
            None  # No template file
        )
        return handle
    except pywintypes.error as e:
        print(f"Error connecting to the pipe: {e}")
        return None

def send_message(handle, message):
    """Sends a message to the named pipe"""
    try:
        # Write message to the pipe
        win32file.WriteFile(handle, message.encode('utf-8'))
        print(f"Message sent: {message}")
    except pywintypes.error as e:
        print(f"Error writing to the pipe: {e}")

def receive_message(handle):
    """Receives a message from the named pipe"""
    try:
        # Read message from the pipe
        result, data = win32file.ReadFile(handle, BUFFER_SIZE)
        message = data.decode('utf-8')
        print(f"Message received: {message}")
    except pywintypes.error as e:
        print(f"Error reading from the pipe: {e}")

def main():
    print("Connecting to the pipe...")
    pipe_handle = connect_to_pipe()

    if pipe_handle:
        # Send a message
        send_message(pipe_handle, "Hello from the Python client!")

        # Receive a message
        receive_message(pipe_handle)

        # Close the pipe handle when done
        win32file.CloseHandle(pipe_handle)
    else:
        print("Failed to connect to the pipe.")

if __name__ == "__main__":
    main()