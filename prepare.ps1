$resourceGroup = 'toDelete2'
$aksClusterName = 'TestAKS'
$acrName = 'testgabacr'
$imageName = 'testpod'           # Docker image name
$imageTag = 'latest'             # Docker image tag


az group create --name $resourceGroup --location italynorth    

az deployment group create --resource-group $resourceGroup --template-file main.bicep 

# Get the ACR login server
$acr = az acr show --resource-group $resourceGroup --name $acrName --query "loginServer" --output tsv
$loginServer = $acr

# Login to the ACR
az acr login --name $acrName

# Build the Docker image
docker build --pull --rm -f "dokerfile" -t ${imageName}:${imageTag} "." 

# Tag the image with the ACR login server
docker tag ${imageName}:${imageTag} ${loginServer}/${imageName}:${imageTag}

# Push the image to the ACR
docker push ${loginServer}/${imageName}:${imageTag}

# Get AKS cluster credentials
az aks get-credentials --resource-group ${resourceGroup} --name ${aksClusterName}

# Deploy to AKS
kubectl apply -f deployment.yaml

kubectl get pods -o wide --watch


