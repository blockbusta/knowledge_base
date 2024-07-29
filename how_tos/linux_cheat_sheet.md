# linux cheat sheet


```ruby
scp -i <PEM_KEY_PATH> <USER>@<HOST>:**/remote/path/file.txt** /local/target/path
```







### Wildcards

A question mark (" **?** ") can be used to indicate “any single character” within the file name

```bash
cat file1.txt file2.txt
cat file?.txt
```

An asterisk (" ***** ") can be used to indicate “zero or more characters”.

```bash
cat file1.txt file2.txt
cat file*
```