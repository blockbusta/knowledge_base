# helm commands

### Basic

add lolz operator repo and update to latest version

```bash
helm repo add lolzv3 https://charts.v3.beer.co.uk
helm repo update
```

display all chart versions

```bash
helm search repo lolzv3/lolz -l
```

### Download chart

download latest chart locally (`tar.gz` file)

```bash
helm pull lolzv3/lolz
```

download specific chart version

```bash
helm pull lolzv3/lolz --version 3.6.1
```

untar it on the fly

```bash
helm pull lolzv3/lolz --version 3.6.1 --untar
```

### Install chart

basic install

```bash
helm install release-name release --flags
```

install specific chart version

```yaml
helm install lolz lolzv3/lolz --version 4.3.28 -n lolz
```

install from local chart

```bash
helm install lolz . --create-namespace -n lolz
```

dry run an installation, to test expected outcome

```bash
helm install lolz . --create-namespace -n lolz --dry-run --debug
```

### Test chart

dry run (outputs configuration to stdout)

```yaml
helm install ... --dry-run
```

create template

```yaml
helm template ...
```

**extract chart from TGZ file**

```bash
tar -zxvf your-chart.tgz
```

**get values of installed chart:**

```bash
helm get values lolz
```

### Search

**search repo for charts:**

```
helm search repo kube-prometheus-stack
```

**list all available versions for chart:**

```
helm search repo prometheus-community/kube-prometheus-stack -l
```
