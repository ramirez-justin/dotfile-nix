# Cloud Platform Tools

Configuration and utilities for AWS and Google Cloud Platform.

## AWS CLI

### Profile Management

```bash
# Profile Selection
awsp    # Switch AWS profile interactively
awsw    # Show current AWS profile
awsl    # List available profiles

# Quick Access
awsc    # Copy current credentials
awse    # Export credentials as env vars
```

### Credential Management

```nix
# Configuration in home-manager/modules/aws-cred.nix
programs.aws = {
  enable = true;
  settings = {
    region = "us-east-1";
    output = "json";
  };
};
```

## Google Cloud SDK

### Installation & Components

The Google Cloud SDK is managed via Nix with declarative component installation.

```nix
# Configuration in home-manager/modules/gcloud.nix
let
  gdk = pkgs.google-cloud-sdk.withExtraComponents(
    with pkgs.google-cloud-sdk.components; [
      gke-gcloud-auth-plugin    # Required for GKE cluster authentication
      # Add other components here as needed
    ]
  );
in
{
  home.packages = [ gdk ];
}
```

**Important**: When using Nix, components must be added declaratively in the configuration.
`gcloud components install` will not work and should not be used.

### Authentication

#### Quick Authentication Aliases

```bash
# Authentication shortcuts
gauth      # Full gcloud authentication (user + application-default)
gauthuser  # User authentication only (gcloud auth login)
gauthapp   # Application default credentials only (gcloud auth application-default login)

# Credential Status
gauthls    # List authenticated accounts
gauthinfo  # Show current auth info
```

#### Manual Authentication

If you prefer to run commands manually:

```bash
# User Authentication
# This authenticates your user account for gcloud CLI commands
gcloud auth login

# Application Default Credentials (ADC)
# This sets up credentials for applications and SDKs (Terraform, Python libraries, etc.)
gcloud auth application-default login

# Check current authentication status
gcloud auth list
gcloud config list
```

#### When to Use Which Auth

- **User Auth** (`gcloud auth login`):
  - For running gcloud CLI commands
  - Manages GCP resources via command line

- **Application Default Credentials** (`gcloud auth application-default login`):
  - For local development with GCP SDKs
  - Required for Terraform, Python google-cloud-* libraries
  - Used by applications that call GCP APIs

### Configuration Management

```bash
# Configuration Commands
gcl     # List configurations
gcs     # Switch configuration
gci     # Show current config info

# Project Management
gpl     # List projects
gps     # Set current project
```

#### Managing Multiple Configurations

Google Cloud supports multiple named configurations for different environments:

```bash
# Create a new configuration
gcloud config configurations create dev-project

# Activate a configuration
gcloud config configurations activate dev-project

# Set project for current configuration
gcloud config set project PROJECT_ID

# Set default region/zone
gcloud config set compute/region us-west1
gcloud config set compute/zone us-west1-a

# List all configurations
gcloud config configurations list
```

### GKE (Kubernetes) Authentication

The `gke-gcloud-auth-plugin` is pre-installed and configured.

```bash
# Get credentials for a GKE cluster
gcloud container clusters get-credentials CLUSTER_NAME --region REGION

# Verify kubectl access
kubectl get nodes

# The USE_GKE_GCLOUD_AUTH_PLUGIN environment variable is automatically set
```

### Common Workflows

#### Setting Up a New Project

```bash
# 1. List available projects
gpl  # or: gcloud projects list

# 2. Set the project
gps PROJECT_ID  # or: gcloud config set project PROJECT_ID

# 3. Authenticate if needed
gauth

# 4. Verify configuration
gci  # or: gcloud config list
```

#### Switching Between Projects

```bash
# Option 1: Use configurations (recommended for frequent switching)
gcl                                          # List configurations
gcs CONFIG_NAME                              # Switch configuration

# Option 2: Change project directly
gps PROJECT_ID                               # Set project

# Option 3: Use project flag on commands
gcloud compute instances list --project=PROJECT_ID
```

### Troubleshooting

#### "Error: Could not automatically determine credentials"

This usually means Application Default Credentials are not set:

```bash
gauthapp  # or: gcloud auth application-default login
```

#### "You do not currently have an active account selected"

User authentication is missing:

```bash
gauthuser  # or: gcloud auth login
```

#### "gke-gcloud-auth-plugin not found"

The plugin is managed by Nix. If you encounter this error:

1. Verify the plugin is in your configuration: Check `home-manager/modules/gcloud.nix`
2. Rebuild your system: `rebuild`
3. Verify installation: `which gke-gcloud-auth-plugin`

#### Re-authenticating Everything

If you're having authentication issues, start fresh:

```bash
# Revoke all credentials
gcloud auth revoke --all
gcloud auth application-default revoke

# Re-authenticate
gauth
```
