# home-manager/modules/aws/default.nix
#
# AWS CLI Configuration and Credential Management
#
# Purpose:
# - Enables AWS CLI command completion
# - Sets default AWS region (configurable via user-config.nix)
# - Creates credential helper scripts
# - Provides profile switching aliases
#
# Features:
# - AWS CLI completion
# - Configurable region from user-config.nix
# - Credential file generation
# - Environment cleanup
# - Profile switching:
#   - awsdef (default)
#   - awsprod (production)
#   - awsdev (development)
#
# Configuration:
# - awsRegion: Set in user-config.nix (default: us-west-2)
#
# Integration:
# - AWS CLI installed via Homebrew (homebrew.nix)
# - Works with ZSH aliases

{ config, pkgs, lib, ... }@args:

let
  awsRegion = args.awsRegion or "us-west-2";
in {
  programs.zsh = {
    initContent = ''
      # Enable AWS CLI command completion
      # Uses aws_completer from awscli2 package
      complete -C '${pkgs.awscli2}/bin/aws_completer' aws

      # Set AWS region defaults
      # Region: ${awsRegion}
      # Used by AWS CLI and SDKs
      export AWS_DEFAULT_REGION=${awsRegion}
      export AWS_REGION=${awsRegion}
    '';

    # Profile switching aliases
    shellAliases = {
      awsdef = "osascript -e 'tell application \"System Events\" to keystroke \"k\" using command down' && ~/.local/bin/copy_and_unset default";
      awsprod = "osascript -e 'tell application \"System Events\" to keystroke \"k\" using command down' && ~/.local/bin/copy_and_unset production";
      awsdev = "osascript -e 'tell application \"System Events\" to keystroke \"k\" using command down' && ~/.local/bin/copy_and_unset development";
    };
  };

  # Credential helper scripts
  home.file = {
    # Script to copy AWS credentials from environment to file
    ".local/bin/aws_cred_copy" = {
      source = pkgs.writeScript "aws_cred_copy" ''
        #!/bin/bash
        mkdir -p ~/.aws
        echo "[default]" > ~/.aws/credentials
        echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
        echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials
        echo "aws_session_token = $AWS_SESSION_TOKEN" >> ~/.aws/credentials
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
      '';
      executable = true;
    };

    # Script to copy credentials and unset environment variables
    ".local/bin/copy_and_unset" = {
      text = ''
        #!/bin/bash
        ~/.local/bin/aws_cred_copy
      '';
      executable = true;
    };
  };
}
