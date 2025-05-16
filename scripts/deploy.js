const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Tokenized Real-World Asset Ownership Syndicate...");

  // Get the contract factory
  const Project = await ethers.getContractFactory("Project");
  
  // Deploy the contract
  const project = await Project.deploy();
  
  // Wait for deployment to complete
  await project.waitForDeployment();

  // Get the deployed contract address
  const projectAddress = await project.getAddress();
  
  console.log(`Project deployed to: ${projectAddress}`);
  console.log("Deployment completed successfully!");
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });
