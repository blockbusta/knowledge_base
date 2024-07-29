# Azure ACR

[https://docs.microsoft.com/en-us/cli/azure/acr/credential?view=azure-cli-latest#:~:text=Global Parameters-,az acr credential show,-Edit](https://docs.microsoft.com/en-us/cli/azure/acr/credential?view=azure-cli-latest#:~:text=Global%20Parameters-,az%20acr%20credential%20show,-Edit)

## retrieve registry credentials

Get the login credentials for an Azure Container Registry.

```
az acr credential show -n **MyRegistry**
```

Get the username only:

```
az acr credential show -n **MyRegistry** --query username
```

Get a password only:

```
az acr credential show -n **MyRegistry** --query passwords[0].value
```

## retrieve registry URL

visit your registry page, and copy the URL from the **Login server** field:

![Untitled](Azure%20ACR%20a373c11c4d2f4040bef76f148f796fd7/Untitled.png)