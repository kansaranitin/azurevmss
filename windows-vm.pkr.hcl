# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

packer {
  required_plugins {
    azure = {
      version = ">= 1.4.2"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# Define Azure source configuration
source "azure-arm" "imageBuild" {
  client_id                           = "4de9c48e-1e2a-4ce4-a73a-589aca74ff5f"
  client_secret                       = "22bf75d0-b9d8-4eaa-bf6a-90fd4a6892d9"
  tenant_id                           = "46c098eb-d201-4438-8d22-69c387d66aa8"
  subscription_id                     = "b1a16b61-64da-4d11-b76c-40be3788f709"

  location                            = "SoutheastAsia"
  vm_size                             = "Standard_DS2_v2"
  os_type                             = "Windows"
  image_offer                         = "WindowsServer"
  image_publisher                     = "MicrosoftWindowsServer"
  image_sku                           = "2019-Datacenter"

  communicator                        = "winrm"
  winrm_insecure                      = true
  winrm_timeout                       = "5m"
  winrm_use_ssl                       = true
  winrm_username                      = "packer"

  shared_image_gallery_destination {
    subscription        = "b1a16b61-64da-4d11-b76c-40be3788f709"
    gallery_name        = "nkgallary001"
    image_name          = "nkgallarydef001"
    image_version       = "0.1.0"
    resource_group      = "nktestvm002"
  }

  # Uncomment for replication to other regions
  # replication_regions = ["northeurope"]
}

# Build block to define provisioning and post-processing steps
build {
  sources = ["source.azure-arm.imageBuild"]

  # Provisioning step to upload files to the VM
  provisioner "file" {
    source      = "demo.zip"
    destination = "C:/"
  }

  # Powershell provisioning to display a demo message
  provisioner "powershell" {
    pause_before = "5s"
    inline = [
      "Write-Host '***** this is a demo message *****'"
    ]
  }

  # Initiating a system restart
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Restarted.'}\""
    pause_before  = "30s"
  }

  # Provisioning for setting environment variables and displaying them
  provisioner "powershell" {
    inline = [
      "Write-Host 'Release version is: $Env:Release'"
    ]
    environment_vars = {
      Release = "{{user `Release`}}"
    }
  }

  # Generalizing the image (Sysprep for Windows)
  provisioner "powershell" {
    inline = [
      "Write-host '=== Azure image build completed successfully ==='",
      "Write-host '=== Generalising the image ... ==='",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /generalize /oobe /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
   
}

