# record chrome browser network activity

1. In Chrome, go to the page within Box where you are experiencing trouble.
2. At the top-right of your browser window, click the Chrome menu (⋮).
3. Select **More Tools > Developer Tools**. The Developer Tools window opens as a docked panel at the side or bottom of Chrome.
4. Click the **Network** tab.
5. Select **Preserve log**.
6. You will see a red circle at the top left of the Network tab. This means the capture has started. If the circle is black, click the **black circle** to start recording activity in your browser.
7. **Refresh the page** and reproduce the problem while the capture is running.
8. After you successfully reproduce the issue, right click on any row of the activity pane and select **Export HAR…**
    
    
9. Select the **Console** tab.
10. Right-click anywhere in the console and select **Save as...**.
11. Name the log file **Chrome-console.log**

### display *.HAR files

simply drag and drop them into an open dev tools → network tab