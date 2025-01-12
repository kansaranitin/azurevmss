packer {
  required_plugins {
    azure = {
      version = ">= 2.0.0"
      source  = "hashicorp/azure"
    }
  }
}

source "azure-arm" "example" {
  client_id         = "bc5e53f2-9ed0-46bd-a492-faa229ff7147"
  client_secret     = "f596d56a-4f12-4312-9b52-e416ffcf84f8"
  tenant_id         = "51234009-8c9d-42ee-ab3d-73d8858f51e3"
  subscription_id   = "46e0072b-3d33-484d-90ef-8b69838c9ad2"

  location          = "SoutheastAsia"
  vm_size           = "Standard_DS2_v2"
  os_type           = "Windows"
  image_offer       = "WindowsServer"
  image_publisher   = "MicrosoftWindowsServer"
  image_sku         = "2019-Datacenter"

  communicator      = "winrm"
  winrm_insecure    = true
  winrm_timeout     = "7m"
  winrm_use_ssl     = true
  winrm_username    = "packer"

  shared_image_gallery_destination {
    subscription     = "46e0072b-3d33-484d-90ef-8b69838c9ad2"  # Optional if same as subscription_id
    gallery_name     = "nktestvm002"
    image_name       = "nkgallarydef001"
    image_version    = "0.1.0"
    replication_regions = ["northeurope"]
    resource_group   = "nkgallary007"
  }

  shared_image_gallery_replica_count = 1
}

build {
  sources = ["source.azure-arm.example"]  # Fixed source reference

  provisioner "file" {
    source      = "demo.zip"
    destination = "C:/"
  }

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

  provisioner "powershell" {
    environment_vars = [
      "Release=${var.Release}"  # Ensure the variable is defined somewhere
    ]
    inline = [
      "Write-Host \"Release version is: $Env:Release\""
    ]
  }

  # Generalising the image
  provisioner "powershell" {
    inline = [
      "Write-host '=== Azure image build completed successfully ==='",
      "Write-host '=== Generalising the image ... ==='",    
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /generalize /oobe /quit", 
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10 } else { break } }"
    ]
  }
}
