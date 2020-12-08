provider "google" {
  credentials = var.credentials
  project     = var.project
  region      = var.region
  zone        = var.zone
  user_project_override = true
}


resource "google_compute_instance_template" "my_lamp_instance" {
  name           = "my-instance-template1"
  machine_type   = "e2-medium"
  can_ip_forward = false
  tags = ["foo", "bar"]

  disk {
    source_image = "project-2-297319/novinano1"
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_target_pool" "my_target_pool" {
  name = "my-target-pool-3"
}

resource "google_compute_instance_group_manager" "my_group" {
  name = "my-igm1"
  zone = var.zone

  version {
    instance_template  = google_compute_instance_template.my_lamp_instance.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.my_target_pool.id]
  base_instance_name = "lamp"
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-vpc-147"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "my_firewall" {
  name    = "terraform-scalable-firewall1"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = [80, 22, 443]
  }
}
resource "google_compute_autoscaler" "autoscal" {
  name   = "my-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.my_group.id

  autoscaling_policy {
    max_replicas    = 4
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

