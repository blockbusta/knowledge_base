# VScode tricks

## general

### free column selection in text
click on text, then `option` + `SHIFT`, and drag to select the column

### export & import extensions
on pc1:
```
code --list-extensions > vscode-extensions.txt
```

on pc2:
```
cat vscode-extensions.txt | xargs -n 1 code --install-extension
```


### macos "quick action" to open files in VScode from finder
Open **Automator** application -> New **Quick Action**, set the following:

- **Workflow receives current**: files or folder
- **in**: Finder
- **Image**: Action
- **Color**: Purple

From the **Library** list on the left, add **Run Shell Script** and set the following:

- **Shell**: `/bin/zsh`
- **Pass input**: as arguments
- **Script**:
	```
	for f in "$@"; do
	  open -a "Visual Studio Code" "$f"
	done
	```
Save, then in **Finder** right click -> **Quick Actions** -> **Customize**, and check it in the list. 

## find & replace using regex

### select all empty lines
```
^\s*$\n
```

### select all lines containing "STRING"
```
^.*STRING.*$\n
```

### find lines that contains 2 strings "HELLO" + "WORLD"
```
(?=.*HELLO)(?=.*WORLD).*
```
