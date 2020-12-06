provider "google" {
  credentials = var.credentials
  project     = var.project
  region      = var.region
  zone        = var.zone
  user_project_override = true
}


resource "google_compute_instance_template" "my_lamp_instance" {
  name           = "my-instance-template"
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
  name = "my-target-pool-2"
}

resource "google_compute_instance_group_manager" "my_group" {
  name = "my-igm"
  zone = var.zone

  version {
    instance_template  = google_compute_instance_template.my_lamp_instance.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.my_target_pool.id]
  base_instance_name = "lamp"
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-vpc-146"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "my_firewall" {
  name    = "terraform-scalable-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = [80, 22]
  }
}

//module "gce-lb-fr" {
//  source       = "github.com/GoogleCloudPlatform/terraform-google-lb"
//  region       = var.region
//  name         = "group1-lb"
//  service_port = "80"
//  target_tags  = ["allow-lb-service"]
//}

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

//resource "google_dns_record_set" "frontend" {
//  name = "frontend.${google_dns_managed_zone.prod.dns_name}"
//  type = "A"
//  ttl  = 300

//  managed_zone = google_dns_managed_zone.prod.name

//  rrdatas = [google_compute_instance_template.my_lamp_instance.network_interface[0].access_config[0].nat_ip]
//}

//resource "google_dns_managed_zone" "prod" {
//  name     = "prod-zone"
//  dns_name = "dev.svc.rv.ua"
//}