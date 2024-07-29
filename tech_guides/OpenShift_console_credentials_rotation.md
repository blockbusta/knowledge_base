# OpenShift console credentials rotation

<aside>
👉🏻 this is useful if the password got lost or forgotten, but you still have access to the cluster

</aside>

run this go script to generate the password:

[https://go.dev/play/p/D8c4P90x5du](https://go.dev/play/p/D8c4P90x5du)

```go
package main

import (
	"crypto/rand"
	b64 "encoding/base64"
	"fmt"
	"math/big"

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
	fmt.Printf("Actual Password: %s\n", password)
	fmt.Printf("Hashed Password: %s\n", hash)
	fmt.Printf("Patch this string in secret: %s", b64.StdEncoding.EncodeToString([]byte(hash)))
}
```

patch the kubeadmin secret with the value printed in “`Patch this string in secret`”

```go
kubectl -n kube-system patch secret kubeadmin \
-p='{"data":{"kubeadmin":"**STRING_TO_PATCH**"}}'
```

login to openshift web console with `kubeadmin` username, and the value printed in “`Actual Password`” as password