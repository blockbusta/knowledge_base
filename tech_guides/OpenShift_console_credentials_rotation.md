
# OpenShift console credentials rotation

> 👉🏻 in case the password to the `kubeadmin` user got lost or forgotten

1. go online playground:
https://go.dev/play/

2. run this script:
```go
package main

import (
	"crypto/rand"
	b64 "encoding/base64"
	"fmt"
	"math/big"
	"strings"

	"golang.org/x/crypto/bcrypt"
)

func generateRandomPasswordHash(length int) (string, string, error) {
	const (
		lowerLetters = "abcdefghijkmnopqrstuvwxyz"
		upperLetters = "ABCDEFGHIJKLMNPQRSTUVWXYZ"
		digits       = "23456789"
		all          = lowerLetters + upperLetters + digits
	)
	var password string
	for i := 0; i < length; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(all))))
		if err != nil {
			return "", "", err
		}
		newchar := string(all[n.Int64()])
		if password == "" {
			password = newchar
		}
		if i < length-1 {
			n, err = rand.Int(rand.Reader, big.NewInt(int64(len(password)+1)))
			if err != nil {
				return "", "", err
			}
			j := n.Int64()
			password = password[0:j] + newchar + password[j:]
		}
	}
	pw := []rune(password)
	for _, replace := range []int{5, 11, 17} {
		pw[replace] = '-'
	}

	bytes, err := bcrypt.GenerateFromPassword([]byte(string(pw)), bcrypt.DefaultCost)
	if err != nil {
		return "", "", err
	}

	return string(pw), string(bytes), nil
}

func main() {
	password, hash, err := generateRandomPasswordHash(23)

	if err != nil {
		fmt.Println(err.Error())
		return
	}
	hash_enc := b64.StdEncoding.EncodeToString([]byte(hash))
	fmt.Printf("Actual Password: %s\n", password)
	fmt.Printf("Hashed Password: %s\n", hash)
	fmt.Printf("Secret string: %s\n\n", hash_enc)
	fmt.Printf("run this kubectl patch command:\n\n")
	command := `kubectl -n kube-system patch secret kubeadmin -p='{"data":{"kubeadmin":"STR2PATCH"}}'`
	command = strings.Replace(command, "STR2PATCH", hash_enc, 1)
	fmt.Println(command)
}
```

3. "**Actual Password**" is the new password
4. run the kubectl patch command generated to apply it
5. login to openshift web console with `kubeadmin` and the new password
