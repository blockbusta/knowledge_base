# create and host helm charts

1. **Create a new Helm chart:**
    
    ```
    helm create mychart
    ```
    
    This will create a new directory called **`mychart`** with the basic files and directories required for a Helm chart.
    

1. **Add your YAML manifests:**
    
    Copy your existing YAML manifests into the **`mychart/templates`** directory. 
    You can remove any metadata that is already defined in the chart, such as **`apiVersion`** and **`kind`**, since this will be defined in the chart's **`Chart.yaml`** file.
    
    When adding your YAML manifests to the **`mychart/templates`** directory, you have the flexibility to either add a single manifest file that contains all Kubernetes objects or separate manifest files for each object. The decision of whether to use a single file or separate files is usually based on personal preference and the complexity of your application.
    
    If you have a complex application with multiple Kubernetes objects, it is recommended to use separate manifest files for each object. This makes it easier to manage the manifests and understand what each object does.
    
    In Helm, you can create conditionals in your manifest templates by using the Go template language.
    
    ```yaml
    {{- if .Values.global.https }}
      <display section>
    {{- else }}
      <display other section>
    {{- end }}
    ```
    
2. **Update the chart metadata:**
    
    Edit the **`mychart/Chart.yaml`** file to include metadata about your chart, such as its name, version, and description.
    
    When defining the chart metadata in the **`mychart/Chart.yaml`** file, you should include the following fields:
    
    - **`name`**: The name of the chart.
    - **`version`**: The version of the chart.
    - **`description`**: A description of the chart.
    - **`maintainers`**: A list of maintainers for the chart.
    
    Here's an example of what the **`mychart/Chart.yaml`** file might look like:
    
    ```
    apiVersion: v2
    name: mychart
    version: 0.1.0
    description: A Helm chart for my application
    maintainers:
      - name: John Smith
        email: john.smith@example.com
    ```
    
3. **Define the chart's values:**
    
    Edit the **`mychart/values.yaml`** file to include any configuration values that can be overridden by the user during installation.
    
    When defining the chart's values in the **`mychart/values.yaml`** file, you can define configuration values that can be overridden by the user during installation. To do this, define a list of variables and their default values, like this:
    
    ```
    variable1: default_value1
    variable2: default_value2
    ```
    
    For example, if your application requires a database name and password, you might define the values like this:
    
    ```
    database:
      name: mydatabase
      password: mysecretpassword
    ```
    
    You can then reference these values in your manifest files using the following syntax:
    
    ```
    {{ .Values.database.name }}
    {{ .Values.database.password }}
    ```
    
    This allows the user to override the default values by specifying them as command-line arguments during installation, like this:
    
    ```
    helm install mychart \
    --set database.name=mynewdatabase \
    --set database.password=mynewpassword
    ```
    
    This command will install the chart with the new database name and password values.
    
4. **Test the chart:**
    
    Run the following command to test your chart:
    
    ```
    helm install mychart --debug --dry-run
    ```
    
    This will simulate the installation of the chart and show you what resources will be created.
    
5. **Package the chart:**
    
    Run the following command to package your chart:
    
    ```
    helm package mychart
    ```
    
    This will create a **`.tgz`** file containing your chart.
    


1. **Add your Helm chart to the repository:**
    
    Upload your **`.tgz`** Helm chart file to the repository.
    
2. **Enable GitHub Pages:**
    
    In the repository settings, enable GitHub Pages and set the source to the **`gh-pages`** branch. This will make the repository available at a URL like **`https://<username>.github.io/<repository>`**.
    
3. **Add the Helm repository:**
    
    Run the following command to add your Helm repository to your local Helm configuration:
    
    ```
    helm repo add myrepo https://<username>.github.io/<repository>
    ```
    
    This will add the repository to your list of available Helm repositories.
    
4. **Install the Helm chart:**
    
    Run the following command to install the Helm chart from your GitHub Pages URL:
    
    ```
    helm install mychart myrepo/mychart --version <chart version>
    ```
    
    Replace **`<chart version>`** with the version of the Helm chart you want to install.
    
    For example, if your GitHub Pages URL is **`https://myusername.github.io/myrepo`** and the Helm chart version is **`0.1.0`**, the command would be:
    
    ```
    helm install mychart myrepo/mychart --version 0.1.0
    ```
    
    This will install the Helm chart from the specified GitHub Pages URL.