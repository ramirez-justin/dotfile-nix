# home-manager/modules/gcloud.nix
#
# Google Cloud SDK Shell Setup
#
# Purpose:
# - Adds gcloud to shell PATH with declarative components
# - Enables command completion
# - Includes GKE auth plugin
# - Provides authentication and configuration aliases
#
# Features:
# - SDK installed via Nix with extra components
# - GKE authentication plugin included
# - Authentication shortcuts for quick login
# - Project and configuration management aliases
#
# Components:
# - gke-gcloud-auth-plugin: Required for GKE cluster authentication
#
# Authentication Aliases:
# - gauth: Full authentication (user + application-default)
# - gauthuser: User authentication only
# - gauthapp: Application default credentials only
# - gauthls: List authenticated accounts
# - gauthinfo: Show current auth info
#
# Configuration Aliases:
# - gcl: List configurations
# - gcs: Switch configuration
# - gci: Show current config info
# - gpl: List projects
# - gps: Set current project
#
# Usage:
# - Quick auth: 'gauth' to authenticate both user and ADC
# - Manual auth: 'gcloud auth login' and 'gcloud auth application-default login'
# - GKE auth: Handled automatically via plugin
#
# Note: When using Nix, components must be added declaratively.
#       Do not use 'gcloud components install'.

{ config, pkgs, ... }:

let
  gdk = pkgs.google-cloud-sdk.withExtraComponents(
    with pkgs.google-cloud-sdk.components; [
      gke-gcloud-auth-plugin
    ]
  );
in
{
  home.packages = [ gdk ];

  programs.zsh = {
    initExtra = ''
      # Initialize Google Cloud SDK
      # Adds completions and updates PATH
      # Source: google-cloud-sdk package from nixpkgs
      source "${gdk}/google-cloud-sdk/path.zsh.inc"

      # Enable GKE auth plugin
      export USE_GKE_GCLOUD_AUTH_PLUGIN=True
    '';

    # Google Cloud authentication and management aliases
    shellAliases = {
      # Authentication Commands
      # Full authentication (user + application default)
      gauth = "gcloud auth login && gcloud auth application-default login";

      # Individual authentication methods
      gauthuser = "gcloud auth login";                          # User authentication
      gauthapp = "gcloud auth application-default login";       # Application default credentials

      # Authentication status
      gauthls = "gcloud auth list";                             # List authenticated accounts
      gauthinfo = "gcloud config list";                         # Show current config and auth info

      # Configuration Management
      gcl = "gcloud config configurations list";                # List configurations
      gcs = "gcloud config configurations activate";            # Switch configuration (requires name)
      gci = "gcloud config list";                               # Show current config info

      # Project Management
      gpl = "gcloud projects list";                             # List projects
      gps = "gcloud config set project";                        # Set current project (requires project ID)
    };
  };
}
