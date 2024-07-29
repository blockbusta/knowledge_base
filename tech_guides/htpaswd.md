# htpaswd

**to create the file:**

```go
htpasswd -c /path/to/.htpasswd 1stuser
```

you will be prompted to enter password twice.

after which, the file at `/path/to/.htpasswd` will be created.

**to add another set of user/pass to an existing file:**

```go
htpasswd -c /path/to/.htpasswd 2nduser
```

the new set of user/pass will be appended to the existing file.

**file content looks like:**

```go
1stuser:$apr1$sjtb.6si$Ads63ERgdgj.85p5kaL2I1
2nduser:$apr1$eBSl8Xqr$JDkhSnIFAAr4yRZws3P5l.
```

**to verify the password:**

```go
htpasswd -v /path/to/.htpasswd 1stuser
```

you will be prompted to enter the password for `1stuser` once, and will get a response back if its correct or not.