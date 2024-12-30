# VScode tricks

## general

### free column selection in text
click on text, then `option` + `SHIFT`, and drag to select the column

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
