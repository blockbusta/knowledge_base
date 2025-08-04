The fastest way to block a domain on macOS is to edit the hosts file. Here's how:

1. **Open Terminal** (press Cmd+Space, type "Terminal", press Enter)

2. **Edit the hosts file** with this command:
   ```bash
   sudo vim /etc/hosts
   ```

3. **Add this line** at the bottom of the file:
   ```
   127.0.0.1 hello.lolz.xyz
   ```

4. **Save and exit**: Press Ctrl+X, then Y, then Enter

5. **Flush DNS cache**:
   ```bash
   sudo dscacheutil -flushcache
   ```

This redirects any requests to hello.lolz.xyz back to your local machine (127.0.0.1), effectively blocking access. The block takes effect immediately and works system-wide for all browsers and applications.

To unblock later, just remove that line from the hosts file using the same process.
